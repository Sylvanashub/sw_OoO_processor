module ooo #(

   parameter   RVS_ALU_DEPTH  = 32'D4 ,
   parameter   RVS_MDU_DEPTH  = 32'D4 ,
   parameter   RVS_LDU_DEPTH  = 32'D4 ,
   parameter   RVS_STU_DEPTH  = 32'D4 ,

   parameter   RVS_NUM = RVS_ALU_DEPTH + RVS_MDU_DEPTH + RVS_LDU_DEPTH ,
   parameter   TAG_W = $clog2(RVS_NUM)

) (

    input   logic          clk
   ,input   logic          rst

   ,output  logic [31:0]   imem_addr
   ,output  logic [3:0]    imem_rmask
   ,input   logic [31:0]   imem_rdata
   ,input   logic          imem_resp

   ,output  logic [31:0]   dmem_addr
   ,output  logic [3:0]    dmem_rmask
   ,output  logic [3:0]    dmem_wmask
   ,input   logic [31:0]   dmem_rdata
   ,output  logic [31:0]   dmem_wdata
   ,input   logic          dmem_resp   

);

logic          dequeue        ;
logic [63:0]   dequeue_rdata  ;
logic          is_empty       ;

assign dmem_addr  = '0 ;
assign dmem_rmask = '0 ;
assign dmem_wmask = '0 ;
assign dmem_wdata = '0 ;
//------------------------------------------------------------------------------
// interface instance
//------------------------------------------------------------------------------

dec2rvs_itf dec2alu_rvs_itf();
dec2rvs_itf dec2mdu_rvs_itf();
dec2rvs_itf dec2lsu_rvs_itf();
//dec2rvs_itf dec2stu_rvs_itf();

dec2rfu_itf dec2rfu_itf();

rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(4)) rvs2alu_itf() ;
rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(3)) rvs2mdu_itf() ;
rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(3)) rvs2lsu_itf() ;
//rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(3)) rvs2stu_itf() ;

exu2cdb_itf alu2cdb_itf() ;
exu2cdb_itf mdu2cdb_itf() ;
exu2cdb_itf lsu2cdb_itf() ;
//exu2cdb_itf stu2cdb_itf() ;

cdb_itf     cdb_itf();

dec2rob_itf dec2rob_itf() ;
rob2mon_itf rob2mon_itf();

//------------------------------------------------------------------------------
// pipeline instance
//------------------------------------------------------------------------------

fetch u_fetch (
   .*
   ,.ufp_addr        ( imem_addr )  //o logic   [31:0]
   ,.ufp_rmask       ( imem_rmask )  //o logic   [3:0] 
   ,.ufp_wmask       ()  //o logic   [3:0] 
   ,.ufp_rdata       ( imem_rdata )  //i logic   [31:0]
   ,.ufp_wdata       ()  //o logic   [31:0]
   ,.ufp_resp        ( imem_resp )  //i logic         

);

dec #(
   
   .TAG_W( TAG_W )

) u_dec (
   .*
);

rfu  #(
   
   .TAG_W( TAG_W )

) u_rfu (
   .*
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.DEPTH     ( RVS_ALU_DEPTH   )
   ,.START_ID  ( 1               )
) u_alu_rvs (
   .*
   ,.dec2rvs_itf ( dec2alu_rvs_itf  )
   ,.rvs2exu_itf ( rvs2alu_itf      )
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.DEPTH     ( RVS_MDU_DEPTH )
   ,.START_ID  ( 5               )
) u_mdu_rvs (
   .*
   ,.dec2rvs_itf ( dec2mdu_rvs_itf  )
   ,.rvs2exu_itf ( rvs2mdu_itf      )
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.DEPTH     ( RVS_LDU_DEPTH   )
   ,.START_ID  ( 9               )
) u_ldu_rvs (
   .*
   ,.dec2rvs_itf ( dec2lsu_rvs_itf  )
   ,.rvs2exu_itf ( rvs2lsu_itf      )
);

alu #(
    .TAG_W     ( TAG_W           )
) u_alu (
   .*
);

mdu #(
    .TAG_W     ( TAG_W           )
) u_mdu (
   .*
);

lsu #(
    .TAG_W     ( TAG_W           )
) u_lsu (
   .*
);

//stu u_stu (
//   .*
//);

cdb #(
    .TAG_W     ( TAG_W           )
) u_cdb (
   .*
);

rob  #(
   .TAG_W( TAG_W )
) u_rob  (
   .*
);

endmodule