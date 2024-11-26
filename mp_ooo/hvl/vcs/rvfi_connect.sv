
module rvfi_connect
import rv32i_types::* ;
# (

   parameter   TAG_W = 32'D5 ,
   parameter   DEPTH = 32'D16 ,
   parameter   PTR_W = $clog2(DEPTH)

) (
    input   logic    clk
   ,input   logic    rst
) ;

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

rob_entry_t  rob_entries [DEPTH] ;
logic [PTR_W-1:0] rptr ;
wire  flush = dut.u_ooo.flush ;
wire [31:0] pc_new = dut.u_ooo.pc_new ;
assign rptr = dut.u_ooo.u_rob.rptr ;


wire  [31:0]   dmem_addr   = dut.u_ooo.dmem_addr ;
wire  [3:0]    dmem_rmask  = dut.u_ooo.dmem_rmask;
wire  [3:0]    dmem_wmask  = dut.u_ooo.dmem_wmask;
wire  [31:0]   dmem_rdata  = dut.u_ooo.dmem_rdata;
wire  [31:0]   dmem_wdata  = dut.u_ooo.dmem_wdata;
wire           dmem_resp   = dut.u_ooo.dmem_resp ;

genvar i;
generate
for(i=0;i<DEPTH;i++)
begin : rob_ent
   assign rob_entries[i] = dut.u_ooo.u_rob.rob_entries[i] ;
end
endgenerate

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
logic   [6:0]   opcode;
logic    [2:0] funct3 ;
assign opcode = rob_entries[rptr].inst[6:0];
assign funct3 = rob_entries[rptr].inst[14:12];
wire rs1_addr_vld =  opcode == op_b_jalr  || 
                     opcode == op_b_br    || 
                     opcode == op_b_load  || 
                     opcode == op_b_store || 
                     opcode == op_b_imm   ||
                     opcode == op_b_reg   
                     ;

wire rs2_addr_vld = opcode == op_b_br || opcode == op_b_store || opcode == op_b_reg ;

wire  opcode_wo_rd = opcode == op_b_store || opcode == op_b_br ;

assign mon_valid      = rob_entries[rptr].valid && rob_entries[rptr].ready ;
assign mon_inst       = rob_entries[rptr].inst ;
assign mon_rs1_addr   = rs1_addr_vld ? rob_entries[rptr].inst[19:15] : '0 ;
assign mon_rs2_addr   = rs2_addr_vld ? rob_entries[rptr].inst[24:20] : '0 ;
assign mon_rs1_rdata  = mon_rs1_addr == '0 ? '0 : rob_entries[rptr].rs1_rdata ;
assign mon_rs2_rdata  = mon_rs2_addr == '0 ? '0 : rob_entries[rptr].rs2_rdata ;
assign mon_rd_addr    = opcode_wo_rd ? '0 : rob_entries[rptr].inst[11:7] ;
assign mon_rd_wdata   = rob_entries[rptr].wdata ;
assign mon_pc_rdata   = rob_entries[rptr].pc  ;
assign mon_pc_wdata   = flush ? pc_new : rob_entries[rptr].pc + 4 ;

logic [31:0]   dmem_addr_r    ;
logic [3:0]    dmem_rmask_r   ;
logic [3:0]    dmem_wmask_r   ;
logic [31:0]   dmem_rdata_r   ;
logic [31:0]   dmem_wdata_r   ;

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
//assign mon_mem_rdata  = (opcode == op_b_store || opcode == op_b_load) ? dmem_rdata_r : '0 ;
//assign mon_mem_rdata  = (opcode == op_b_load) ? dmem_rdata_r : '0 ;
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
