
module rob 
import rv32i_types::* ;
#(

   parameter   TAG_W = 32'D4 ,
   parameter   DEPTH = 16 ,
   parameter   PTR_W = $clog2(DEPTH)

) (

    input   logic    clk
   ,input   logic    rst

   ,dec2rob_itf.rob  dec2rob_itf

//   ,rvs2rob_itf.rob  rvs2rob_itf
   ,output  logic    rob_full
   
   ,cdb_itf.slv      cdb_itf

   ,rob2lsu_itf.rob  rob2lsu_itf

   ,rob2rat_itf.rob  rob2rat_itf

   ,rob2gpr_itf.rob  rob2gpr_itf

   ,rob2jmp_itf.rob  rob2jmp_itf

   ,input   logic          flush
   ,input   logic [31:0]   pc_new
   ,output  logic [31:0]   pc_org
   ,input   logic [31:0]   dmem_addr
   ,input   logic [3:0]    dmem_rmask
   ,input   logic [3:0]    dmem_wmask
   ,input   logic [31:0]   dmem_rdata
   ,input   logic [31:0]   dmem_wdata
   ,input   logic          dmem_resp   
);

typedef struct packed {

   logic [31:0]      inst  ;
   logic [31:0]      pc    ;
   logic [TAG_W-1:0] tag   ;
   logic [TAG_W-1:0] rs1_tag ;
   logic [TAG_W-1:0] rs2_tag ;
   logic [31:0]      rs1_rdata ;
   logic [31:0]      rs2_rdata ;
   logic [31:0]      wdata ;
   logic             valid ;
   logic             ready ;

} rob_entry_t ;

logic [PTR_W-1:0] wptr ;
logic [PTR_W-1:0] rptr ;

rob_entry_t rob_entries [DEPTH] ;

assign dec2rob_itf.inst_id = wptr ;

genvar i ;
generate 
for(i=0;i<DEPTH;i++)
begin : entry
   always@(posedge clk)
   begin
      if( rst|| flush )
      begin
         rob_entries[i].tag      <= '0 ;
         rob_entries[i].valid    <= '0 ;
         rob_entries[i].ready    <= '0 ;
         rob_entries[i].wdata    <= '0 ;
         rob_entries[i].pc       <= '0 ;
         rob_entries[i].inst     <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].inst     <= dec2rob_itf.inst     ;
         rob_entries[i].pc       <= dec2rob_itf.pc       ;
         rob_entries[i].tag      <= dec2rob_itf.tag      ;
         rob_entries[i].valid    <= '1 ;
         rob_entries[i].ready    <= '0 ;//dec2rob_itf.inst[6:0] == op_b_br ;
         //rob_entries[i].ready    <= dec2rob_itf.inst[6:0] == op_b_br ;

      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].tag && cdb_itf.inst_id == i[PTR_W-1:0] )
      begin
         rob_entries[i].tag      <= '0 ;
         rob_entries[i].wdata    <= cdb_itf.wdata ;
         rob_entries[i].ready    <= '1 ;
      end
      else if( rob_entries[i].valid && rob_entries[i].ready && rptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].valid    <= '0 ;
         rob_entries[i].ready    <= '0 ;
      end
   end

   always@(posedge clk)
   begin
      if( rst|| flush )
      begin
         rob_entries[i].rs1_tag  <= '0 ;
         rob_entries[i].rs1_rdata <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].rs1_tag  <= dec2rob_itf.rs1_tag  ;
         rob_entries[i].rs1_rdata<= dec2rob_itf.rs1_rdata;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].rs1_tag )
      begin
         rob_entries[i].rs1_tag   <= '0            ;
         rob_entries[i].rs1_rdata <= cdb_itf.wdata ;
      end
   end

   always@(posedge clk)
   begin
      if( rst|| flush )
      begin
         rob_entries[i].rs2_tag  <= '0 ;
         rob_entries[i].rs2_rdata <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].rs2_tag  <= dec2rob_itf.rs2_tag  ;
         rob_entries[i].rs2_rdata<= dec2rob_itf.rs2_rdata;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].rs2_tag )
      begin
         rob_entries[i].rs2_tag   <= '0            ;
         rob_entries[i].rs2_rdata <= cdb_itf.wdata ;
      end
   end


end
endgenerate
logic is_full ;
logic fifo_rd ;
assign fifo_rd = rob_entries[rptr].valid && rob_entries[rptr].ready ;

//assign rvs2rob_itf.busy = is_full ;
assign rob_full = is_full ;

assign rob2lsu_itf.inst_id = rptr ;

always_ff@(posedge clk)
begin
   if( rst|| flush )
      wptr <= '0;
   else if( dec2rob_itf.issue )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst|| flush )
      rptr <= '0;
   else if( rob_entries[rptr].valid && rob_entries[rptr].ready )
      rptr <= rptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst|| flush )
      is_full <= '0 ;
   else if( dec2rob_itf.issue && ~fifo_rd && ( wptr + 1'H1 == rptr ) )
      is_full <= '1 ;
   else if( is_full && ~dec2rob_itf.issue && fifo_rd )
      is_full <= '0 ;
end

logic   [6:0]   opcode;
assign opcode = rob_entries[rptr].inst[6:0];
wire  opcode_wo_rd = opcode == op_b_store || opcode == op_b_br ;

//------------------------------------------------------------------------------
// dec2rob
//------------------------------------------------------------------------------

always@(*)//_comb
begin

   dec2rob_itf.rs1_valid   = '1 ;
   dec2rob_itf.rs1_tag     = '0 ;
   dec2rob_itf.rs1_rdata   = '0 ;

   if( rob2rat_itf.rs1_valid )
   begin
      dec2rob_itf.rs1_rdata   = rob2gpr_itf.rs1_rdata ;
   end
   else if( rob_entries[rob2rat_itf.rs1_rob_id].valid )
   begin
      if( rob_entries[rob2rat_itf.rs1_rob_id].ready )
      begin
         dec2rob_itf.rs1_rdata = rob_entries[rob2rat_itf.rs1_rob_id].wdata ;
      end
      else if( cdb_itf.wr && cdb_itf.tag == rob_entries[rob2rat_itf.rs1_rob_id].tag )
      begin
         dec2rob_itf.rs1_rdata = cdb_itf.wdata ;
      end
      else
      begin
         dec2rob_itf.rs1_valid   = '0 ;
         dec2rob_itf.rs1_tag     = rob_entries[rob2rat_itf.rs1_rob_id].tag ;
      end
   end

end

always@(*)//_comb
begin

   dec2rob_itf.rs2_valid   = '1 ;
   dec2rob_itf.rs2_tag     = '0 ;
   dec2rob_itf.rs2_rdata   = '0 ;

   if( rob2rat_itf.rs2_valid )
   begin
      dec2rob_itf.rs2_rdata   = rob2gpr_itf.rs2_rdata ;
   end
   else if( rob_entries[rob2rat_itf.rs2_rob_id].valid )
   begin
      if( rob_entries[rob2rat_itf.rs2_rob_id].ready )
      begin
         dec2rob_itf.rs2_rdata = rob_entries[rob2rat_itf.rs2_rob_id].wdata ;
      end
      else if( cdb_itf.wr && cdb_itf.tag == rob_entries[rob2rat_itf.rs2_rob_id].tag )
      begin
         dec2rob_itf.rs2_rdata = cdb_itf.wdata ;
      end
      else
      begin
         dec2rob_itf.rs2_valid   = '0 ;
         dec2rob_itf.rs2_tag     = rob_entries[rob2rat_itf.rs2_rob_id].tag ;
      end
   end

end

//------------------------------------------------------------------------------
// rob2rat
//------------------------------------------------------------------------------

assign rob2rat_itf.commit     = rob2gpr_itf.rd_wr     ;
assign rob2rat_itf.rd_addr    = rob2gpr_itf.rd_addr   ;
assign rob2rat_itf.rob_id     = rptr ;

//------------------------------------------------------------------------------
// rob2gpr
//------------------------------------------------------------------------------

assign rob2gpr_itf.rs1_addr   = dec2rob_itf.inst[19:15];
assign rob2gpr_itf.rs2_addr   = dec2rob_itf.inst[24:20];

assign rob2gpr_itf.rd_wr      = rob_entries[rptr].valid && rob_entries[rptr].ready && ~opcode_wo_rd ;
assign rob2gpr_itf.rd_addr    = opcode_wo_rd ? '0 : rob_entries[rptr].inst[11:7] ;
assign rob2gpr_itf.rd_wdata   = rob_entries[rptr].wdata ;


//------------------------------------------------------------------------------
// rob2jmp
//------------------------------------------------------------------------------


assign rob2jmp_itf.pc      = rob_entries[rob2jmp_itf.pc_rob_id].pc ;
assign rob2jmp_itf.ready   = rob_entries[rptr].ready ;
assign rob2jmp_itf.rob_id  = rptr ;


assign pc_org  = rob_entries[rptr].pc ;

//------------------------------------------------------------------------------
// rvfi monitor
//------------------------------------------------------------------------------

logic          mon_valid    ;
logic [63:0]   mon_order    ;
logic [31:0]   mon_inst     ;
logic [4:0]    mon_rs1_addr ;
logic [4:0]    mon_rs2_addr ;
logic [31:0]   mon_rs1_rdata;
logic [31:0]   mon_rs2_rdata;
logic [4:0]    mon_rd_addr  ;
logic [31:0]   mon_rd_wdata ;
logic [31:0]   mon_pc_rdata ;
logic [31:0]   mon_pc_wdata ;
logic [31:0]   mon_mem_addr ;
logic [3:0]    mon_mem_rmask;
logic [3:0]    mon_mem_wmask;
logic [31:0]   mon_mem_rdata;
logic [31:0]   mon_mem_wdata;

logic [31:0]   dmem_addr_r    ;
logic [3:0]    dmem_rmask_r   ;
logic [3:0]    dmem_wmask_r   ;
logic [31:0]   dmem_rdata_r   ;
logic [31:0]   dmem_wdata_r   ;
logic    [2:0] funct3 ;
assign funct3 = rob_entries[rptr].inst[14:12];

always_ff@(posedge clk)
begin
   if( rst )
   begin
      mon_order <= '0 ;
   end
   else if( mon_valid )
   begin
      mon_order <= mon_order + 1;
   end
end
wire rs1_addr_vld =  opcode == op_b_jalr  || 
                     opcode == op_b_br    || 
                     opcode == op_b_load  || 
                     opcode == op_b_store || 
                     opcode == op_b_imm   ||
                     opcode == op_b_reg   
                     ;

wire rs2_addr_vld = opcode == op_b_br || opcode == op_b_store || opcode == op_b_reg ;

//wire  opcode_wo_rd = opcode == op_b_store || opcode == op_b_br ;

assign mon_valid      = rob_entries[rptr].valid && rob_entries[rptr].ready ;
assign mon_inst       = rob_entries[rptr].inst ;
assign mon_rs1_addr   = rs1_addr_vld ? rob_entries[rptr].inst[19:15] : '0 ;
assign mon_rs2_addr   = rs2_addr_vld ? rob_entries[rptr].inst[24:20] : '0 ;
assign mon_rs1_rdata  = mon_rs1_addr == '0 ? '0 : rob_entries[rptr].rs1_rdata ;
assign mon_rs2_rdata  = mon_rs2_addr == '0 ? '0 : rob_entries[rptr].rs2_rdata ;
assign mon_rd_addr    = opcode_wo_rd ? '0 : rob_entries[rptr].inst[11:7] ;
assign mon_rd_wdata   = rob_entries[rptr].wdata ;
assign mon_pc_rdata   = rob_entries[rptr].pc  ;
//assign mon_pc_wdata   = flush ? pc_new : rob_entries[rptr].pc + 4 ;
//assign mon_pc_wdata   = flush ? pc_new : rob_entries[(rptr+1'H1)].valid ? rob_entries[(rptr+1'H1)].pc : rob_entries[rptr].pc + 4 ;
assign mon_pc_wdata   = (flush||rob2jmp_itf.is_jmp) ? pc_new : rob_entries[rptr].pc + 4 ;

always_ff@(posedge clk)
begin
   if( rst|| flush )
   begin
      dmem_addr_r   <= '0 ;
      dmem_rmask_r  <= '0 ;
      dmem_wmask_r  <= '0 ;
      dmem_rdata_r  <= '0 ;
      dmem_wdata_r  <= '0 ;
   end
   else 
   begin
      if( |dmem_rmask || |dmem_wmask )
      begin
         dmem_addr_r    <= dmem_addr ;
         dmem_rmask_r   <= dmem_rmask ;
         dmem_wmask_r   <= dmem_wmask ;
         dmem_wdata_r   <= dmem_wdata ;
      end

      if( dmem_resp )
      begin
         dmem_rdata_r <= dmem_rdata ;
      end

   end
end

assign mon_mem_addr   = (opcode == op_b_store || opcode == op_b_load) ? dmem_addr_r  : '0 ;
assign mon_mem_rmask  = (opcode == op_b_store || opcode == op_b_load) ? dmem_rmask_r : '0 ;
assign mon_mem_wmask  = (opcode == op_b_store || opcode == op_b_load) ? dmem_wmask_r : '0 ;
wire [1:0] load_byte_addr = rob_entries[rptr].rs1_rdata[1:0] + rob_entries[rptr].inst[21:20] ;
always_comb
begin
   mon_mem_rdata = '0 ;
   case( opcode )
   op_b_load:
      case( funct3 )
      load_f3_lb  , 
      load_f3_lbu :
         case( load_byte_addr )
         2'H0 : mon_mem_rdata = dmem_rdata_r & 32'H0000_00FF ;
         2'H1 : mon_mem_rdata = dmem_rdata_r & 32'H0000_FF00 ;
         2'H2 : mon_mem_rdata = dmem_rdata_r & 32'H00FF_0000 ;
         2'H3 : mon_mem_rdata = dmem_rdata_r & 32'HFF00_0000 ;
         endcase
      load_f3_lh  ,
      load_f3_lhu :
         case( load_byte_addr[1] )
         1'H0 : mon_mem_rdata = dmem_rdata_r & 32'H0000_FFFF ;
         1'H1 : mon_mem_rdata = dmem_rdata_r & 32'HFFFF_0000 ;
         endcase
      load_f3_lw  : mon_mem_rdata = dmem_rdata_r ;
      endcase
   default :
      mon_mem_rdata = '0 ;
   endcase
end
assign mon_mem_wdata  = (opcode == op_b_store || opcode == op_b_load) ? dmem_wdata_r : '0 ;

endmodule
