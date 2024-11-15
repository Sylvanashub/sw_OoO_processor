
module rob 
import rv32i_types::* ;
#(

   parameter   TAG_W = 32'D4 ,
   parameter   DEPTH = 32'D16 ,
   parameter   PTR_W = $clog2(DEPTH)

) (

    input   logic    clk
   ,input   logic    rst

   ,dec2rob_itf.rob  dec2rob_itf

   ,rvs2rob_itf.rob  rvs2rob_itf
//   ,rvs2rob_itf.rob  alu_rvs2rob_itf
//   ,rvs2rob_itf.rob  mdu_rvs2rob_itf
//   ,rvs2rob_itf.rob  lsu_rvs2rob_itf
   
   ,cdb_itf.slv      cdb_itf

   ,rob2mon_itf      rob2mon_itf

   ,rob2lsu_itf.rob  rob2lsu_itf

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
//logic [DEPTH-1:0] alu_tag_match ;
//logic [DEPTH-1:0] mdu_tag_match ;
//logic [DEPTH-1:0] lsu_tag_match ;

assign dec2rob_itf.inst_id = wptr ;

genvar i ;
generate 
for(i=0;i<DEPTH;i++)
begin : entry
   always@(posedge clk)
   begin
      if( rst )
      begin
         rob_entries[i].tag      <= '0 ;
         rob_entries[i].valid    <= '0 ;
         rob_entries[i].ready    <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].inst     <= dec2rob_itf.inst     ;
         rob_entries[i].pc       <= dec2rob_itf.pc       ;
         rob_entries[i].tag      <= dec2rob_itf.tag      ;
         rob_entries[i].valid    <= '1 ;
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
      if( rst )
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
      if( rst )
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

//   assign alu_tag_match[i] = rob_entries[i].valid && (rob_entries[i].tag == alu_rvs2rob_itf.tag ) ;
//   assign mdu_tag_match[i] = rob_entries[i].valid && (rob_entries[i].tag == mdu_rvs2rob_itf.tag ) ;
//   assign lsu_tag_match[i] = rob_entries[i].valid && (rob_entries[i].tag == lsu_rvs2rob_itf.tag ) ;

end
endgenerate
logic is_full ;
logic fifo_rd ;
assign fifo_rd = rob_entries[rptr].valid && rob_entries[rptr].ready ;
//assign alu_rvs2rob_itf.busy = is_full ;//|| (|alu_tag_match) ;
//assign mdu_rvs2rob_itf.busy = is_full ;//|| (|mdu_tag_match) ;
//assign lsu_rvs2rob_itf.busy = is_full ;//|| (|lsu_tag_match) ;

assign rvs2rob_itf.busy = is_full ;

assign rob2lsu_itf.inst_id = rptr ;

always_ff@(posedge clk)
begin
   if( rst )
      wptr <= '0;
   else if( dec2rob_itf.issue )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rptr <= '0;
   else if( rob_entries[rptr].valid && rob_entries[rptr].ready )
      rptr <= rptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      is_full <= '0 ;
   else if( dec2rob_itf.issue && ~fifo_rd && ( wptr + 1'H1 == rptr ) )
      is_full <= '1 ;
   else if( is_full && ~dec2rob_itf.issue && fifo_rd )
      is_full <= '0 ;
end

logic [63:0]   mon_order ;
always_ff@(posedge clk)
begin
   if( rst )
   begin
      mon_order <= '0 ;
   end
   else if( rob2mon_itf.valid )
   begin
      mon_order <= mon_order + 1;
   end
end

logic   [6:0]   opcode;
assign opcode = rob_entries[rptr].inst[6:0];

wire rs1_addr_vld =  opcode == op_b_jalr  || 
                     opcode == op_b_br    || 
                     opcode == op_b_load  || 
                     opcode == op_b_store || 
                     opcode == op_b_imm   ||
                     opcode == op_b_reg   
                     ;
wire rs2_addr_vld = opcode == op_b_br || opcode == op_b_store || opcode == op_b_reg ;


assign rob2mon_itf.valid      = rob_entries[rptr].valid && rob_entries[rptr].ready ;
assign rob2mon_itf.order      = mon_order ;
assign rob2mon_itf.inst       = rob_entries[rptr].inst ;
assign rob2mon_itf.rs1_addr   = rs1_addr_vld ? rob_entries[rptr].inst[19:15] : '0 ;
assign rob2mon_itf.rs2_addr   = rs2_addr_vld ? rob_entries[rptr].inst[24:20] : '0 ;
assign rob2mon_itf.rs1_rdata  = rob2mon_itf.rs1_addr == '0 ? '0 : rob_entries[rptr].rs1_rdata ;
assign rob2mon_itf.rs2_rdata  = rob2mon_itf.rs2_addr == '0 ? '0 : rob_entries[rptr].rs2_rdata ;
assign rob2mon_itf.rd_addr    = opcode == op_b_store ? '0 : rob_entries[rptr].inst[11:7] ;
assign rob2mon_itf.rd_wdata   = rob_entries[rptr].wdata ;
assign rob2mon_itf.pc_rdata   = rob_entries[rptr].pc  ;
assign rob2mon_itf.pc_wdata   = rob_entries[rptr].pc + 4 ;

logic [31:0]   dmem_addr_r    ;
logic [3:0]    dmem_rmask_r   ;
logic [3:0]    dmem_wmask_r   ;
logic [31:0]   dmem_rdata_r   ;
logic [31:0]   dmem_wdata_r   ;

always_ff@(posedge clk)
begin
   if( rst )
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

assign rob2mon_itf.mem_addr   = (opcode == op_b_store || opcode == op_b_load) ? dmem_addr_r  : '0 ;
assign rob2mon_itf.mem_rmask  = (opcode == op_b_store || opcode == op_b_load) ? dmem_rmask_r : '0 ;
assign rob2mon_itf.mem_wmask  = (opcode == op_b_store || opcode == op_b_load) ? dmem_wmask_r : '0 ;
assign rob2mon_itf.mem_rdata  = (opcode == op_b_store || opcode == op_b_load) ? dmem_rdata_r : '0 ;
assign rob2mon_itf.mem_wdata  = (opcode == op_b_store || opcode == op_b_load) ? dmem_wdata_r : '0 ;


endmodule
