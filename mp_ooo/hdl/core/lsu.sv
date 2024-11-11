
module lsu 
import rv32i_types::*;
//#(
//
//   parameter   TAG_W    = 32'D4  
//
//) 
(

    input   logic    clk
   ,input   logic    rst

   ,rvs2exu_itf.exu  rvs2lsu_itf

   ,exu2cdb_itf.exu  lsu2cdb_itf

   ,output  logic [31:0]   dmem_addr
   ,output  logic [3:0]    dmem_rmask
   ,output  logic [3:0]    dmem_wmask
//   ,input   logic [31:0]   dmem_rdata
   ,output  logic [31:0]   dmem_wdata
//   ,input   logic          dmem_resp 

);

localparam  IDLE  = 2'H0 ;
localparam  LOAD  = 2'H1 ;
localparam  STORE = 2'H2 ;

logic [1:0] state_r ;
logic [1:0] state_nxt ;
logic       wr_vld ;
logic       rd_vld ;

assign wr_vld = rvs2lsu_itf.req && rvs2lsu_itf.rdy ;
assign rd_vld = lsu2cdb_itf.req && lsu2cdb_itf.rdy ;

always_ff@(posedge clk)
begin
   if( rst )
      state_r <= IDLE ;
   else
      state_r <= state_nxt ;
end

always_comb
begin
   state_nxt = state_r ;
   unique case( state_r )
   IDLE : 
   begin
      if( wr_vld )
         state_nxt = rvs2lsu_itf.opc[1] ? STORE : LOAD ;
   end
   LOAD :
   begin
      if( 1'H1 )
         state_nxt = IDLE ;
   end
   STORE :
   begin
      if( 1'H1 )
         state_nxt = IDLE ;
   end
   default :
   begin
      state_nxt = state_r ;
   end
   endcase
end

assign rvs2lsu_itf.rdy = state_r == IDLE ;
assign lsu2cdb_itf.req = '0 ;
assign lsu2cdb_itf.tag = rvs2lsu_itf.tag ;
assign lsu2cdb_itf.wdata = '0 ;

assign dmem_addr = rvs2lsu_itf.src1 + {{20{rvs2lsu_itf.offset[11]}},rvs2lsu_itf.offset} ;
assign dmem_wdata = rvs2lsu_itf.src2 ;
assign dmem_rmask = rvs2lsu_itf.opc ;
assign dmem_wmask = rvs2lsu_itf.opc ;

endmodule
