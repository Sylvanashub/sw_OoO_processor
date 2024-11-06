
module lsu 
import rv32i_types::*;
#(

   parameter   TAG_W    = 32'D4  

) (

    input   logic    clk
   ,input   logic    rst

   ,rvs2exu_itf.exu  rvs2lsu_itf

   ,exu2cdb_itf.exu  lsu2cdb_itf

);

assign rvs2lsu_itf.rdy = 1'H1 ;
assign lsu2cdb_itf.req = '0 ;
assign lsu2cdb_itf.tag = '0 ;
assign lsu2cdb_itf.wdata = '0 ;

endmodule
