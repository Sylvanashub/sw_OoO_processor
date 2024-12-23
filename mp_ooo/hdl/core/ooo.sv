module ooo (

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

localparam   RVS_ALU_DEPTH  = 4 ;
localparam   RVS_MDU_DEPTH  = 4 ;
localparam   RVS_LSU_DEPTH  = 4 ;
localparam   RVS_JMP_DEPTH  = 4 ;
localparam   ROB_DEPTH      = 16 ;
localparam   ROB_PTR_W     = $clog2(ROB_DEPTH) ;
localparam   RVS_NUM = RVS_ALU_DEPTH + RVS_MDU_DEPTH + RVS_LSU_DEPTH + RVS_JMP_DEPTH + 1;
localparam   TAG_W = $clog2(RVS_NUM);
localparam   ALU_START_ID   = 1;
localparam   MDU_START_ID   = ALU_START_ID + RVS_ALU_DEPTH ;
localparam   LSU_START_ID   = MDU_START_ID + RVS_MDU_DEPTH ;
localparam   JMP_START_ID   = LSU_START_ID + RVS_LSU_DEPTH ;

logic          dequeue        ;
logic [65:0]   dequeue_rdata  ;
logic          is_empty       ;

logic          flush    ;
logic [31:0]   pc_new   ;
logic [31:0]   pc_org   ;
logic          btb_update ;

logic          rob_full ;

//assign dmem_addr  = '0 ;
//assign dmem_rmask = '0 ;
//assign dmem_wmask = '0 ;
//assign dmem_wdata = '0 ;
//------------------------------------------------------------------------------
// interface instance
//------------------------------------------------------------------------------

dec2rvs_itf #(.TAG_W(TAG_W)            ,.RPW(ROB_PTR_W) ) dec2alu_rsi();
dec2rvs_itf #(.TAG_W(TAG_W), .OPC_W(3) ,.RPW(ROB_PTR_W) ) dec2mdu_rsi();
dec2rvs_itf #(.TAG_W(TAG_W)            ,.RPW(ROB_PTR_W) ) dec2lsu_rsi();
dec2rvs_itf #(.TAG_W(TAG_W)            ,.RPW(ROB_PTR_W) ) dec2jmp_rsi();

rob2gpr_itf rob2gpr_itf();

rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(4) ,.ROB_PTR_W(ROB_PTR_W) ) rvs2alu_itf() ;
rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(3) ,.ROB_PTR_W(ROB_PTR_W) ) rvs2mdu_itf() ;
rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(4) ,.ROB_PTR_W(ROB_PTR_W) ) rvs2lsu_itf() ;
rvs2exu_itf #(.TAG_W(TAG_W), .OPC_W(4) ,.ROB_PTR_W(ROB_PTR_W) ) rvs2jmp_itf() ;

exu2cdb_itf #(.TAG_W(TAG_W), .ROB_DEPTH(ROB_DEPTH)) alu2cdb_itf() ;
exu2cdb_itf #(.TAG_W(TAG_W), .ROB_DEPTH(ROB_DEPTH)) mdu2cdb_itf() ;
exu2cdb_itf #(.TAG_W(TAG_W), .ROB_DEPTH(ROB_DEPTH)) lsu2cdb_itf() ;
exu2cdb_itf #(.TAG_W(TAG_W), .ROB_DEPTH(ROB_DEPTH)) jmp2cdb_itf() ;

cdb_itf     #(.TAG_W(TAG_W), .ROB_DEPTH(ROB_DEPTH)) cdb_itf();

dec2rob_itf #(.TAG_W(TAG_W), .RPW(ROB_PTR_W)) dec2rob_itf() ;
//rob2mon_itf rob2mon_itf();

rob2lsu_itf #(.ROB_PTR_W(ROB_PTR_W)) rob2lsu_itf();

//rvs2rob_itf rvs2rob_itf() ;

dec2rat_itf #(.RPW(ROB_PTR_W)) dec2rat_itf() ;
rob2rat_itf #(.ROB_PTR_W(ROB_PTR_W)) rob2rat_itf() ;

rob2jmp_itf #(.ROB_PTR_W(ROB_PTR_W)) rob2jmp_itf() ;

ifu2bpu_itf ifu2bpu_itf() ;
jmp2bpu_itf jmp2bpu_itf() ;

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
   ,.rst ( rst || flush ) 
);

gpr u_gpr (
   .*
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.OPC_W     ( 4               )
   ,.DEPTH     ( RVS_ALU_DEPTH   )
   ,.START_ID  ( ALU_START_ID    )
   ,.ROB_PTR_W ( ROB_PTR_W )
) u_alu_rvs (
   .*
   ,.rst ( rst || flush ) 
   ,.dec2rvs_itf ( dec2alu_rsi  )
   ,.rvs2exu_itf ( rvs2alu_itf      )
//   ,.rvs2rob_itf ( alu_rvs2rob_itf  )
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.OPC_W     ( 3               )
   ,.DEPTH     ( RVS_MDU_DEPTH   )
   ,.START_ID  ( MDU_START_ID    )
   ,.ROB_PTR_W ( ROB_PTR_W )
) u_mdu_rvs (
   .*
   ,.rst ( rst || flush ) 
   ,.dec2rvs_itf ( dec2mdu_rsi  )
   ,.rvs2exu_itf ( rvs2mdu_itf      )
//   ,.rvs2rob_itf ( mdu_rvs2rob_itf  )
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.OPC_W     ( 4               )
   ,.DEPTH     ( RVS_LSU_DEPTH   )
   ,.START_ID  ( LSU_START_ID    )
   ,.ROB_PTR_W ( ROB_PTR_W )
) u_lsu_rvs (
   .*
   ,.rst ( rst || flush ) 
   ,.dec2rvs_itf ( dec2lsu_rsi  )
   ,.rvs2exu_itf ( rvs2lsu_itf      )
//   ,.rvs2rob_itf ( lsu_rvs2rob_itf  )
);

rvs #(
    .TAG_W     ( TAG_W           )
   ,.OPC_W     ( 4               )
   ,.DEPTH     ( RVS_JMP_DEPTH   )
   ,.START_ID  ( JMP_START_ID    )
   ,.ROB_PTR_W ( ROB_PTR_W )
) u_jmp_rvs (
   .*
   ,.rst ( rst || flush ) 
   ,.dec2rvs_itf ( dec2jmp_rsi  )
   ,.rvs2exu_itf ( rvs2jmp_itf      )
//   ,.rvs2rob_itf ( lsu_rvs2rob_itf  )
);

alu u_alu (
   .*
   ,.rst ( rst || flush ) 
);

mdu u_mdu (
   .*
   ,.rst ( rst || flush ) 
);

lsu #(
   .TAG_W( TAG_W ) 
   ,.ROB_PTR_W ( ROB_PTR_W )
) u_lsu (
   .*
   ,.rst ( rst || flush ) 
);

jmp#(
    .ROB_PTR_W ( ROB_PTR_W )
)  u_jmp (
   .*
   ,.rst ( rst || flush ) 
);

cdb  u_cdb (
   .*
   ,.rst ( rst || flush ) 
);

rob  #(
   .TAG_W( TAG_W )
   ,.DEPTH( ROB_DEPTH )
) u_rob  (
   .*
   //,.rst ( rst || flush ) 
);

rat #(
   .ROB_DEPTH  ( ROB_DEPTH )
) u_rat (
   .*
   ,.rst ( rst || flush ) 
);


bpu u_bpu (
   .*
);

endmodule
