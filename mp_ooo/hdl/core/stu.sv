
module stu 
import rv32i_types::*;
#(

   parameter   TAG_W    = 32'D4  

) (

    input   logic    clk
   ,input   logic    rst

   ,rvs2exu_itf.exu  rvs2stu_itf

   ,exu2cdb_itf.exu  stu2cdb_itf

);

assign rvs2stu_itf.rdy = 1'H1 ;

endmodule
