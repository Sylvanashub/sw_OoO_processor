
interface rob2gpr_itf () ;

   logic [4:0]          rs1_addr ;
   logic [31:0]         rs1_rdata;
   logic [4:0]          rs2_addr ;
   logic [31:0]         rs2_rdata;
   logic [4:0]          rd_addr  ;
   logic                rd_wr    ;
   logic [31:0]         rd_wdata ;

   modport rob (

       output  rs1_addr 
      ,input   rs1_rdata
      ,output  rs2_addr 
      ,input   rs2_rdata
      ,output  rd_addr  
      ,output  rd_wr    
      ,output  rd_wdata 

   );

   modport gpr (

       input   rs1_addr 
      ,output  rs1_rdata
      ,input   rs2_addr 
      ,output  rs2_rdata
      ,input   rd_addr  
      ,input   rd_wr    
      ,input   rd_wdata 

   );

endinterface

interface dec2rfu_itf #(

   parameter   TAG_W = 32'D4

) () ;

   logic [4:0]          rs1_addr ;
   logic                rs1_busy ;
   logic [TAG_W-1:0]    rs1_tag  ;
   logic [31:0]         rs1_rdata;
                              
   logic [4:0]          rs2_addr ;
   logic                rs2_busy ;
   logic [TAG_W-1:0]    rs2_tag  ;
   logic [31:0]         rs2_rdata;
                             
   logic [4:0]          rd_addr  ;
   logic                rd_wr    ;
   logic [TAG_W-1:0]    rd_tag   ;
   //logic                rd_busy  ;

   modport dec (

       output  rs1_addr
      ,input   rs1_busy
      ,input   rs1_tag
      ,input   rs1_rdata

      ,output  rs2_addr
      ,input   rs2_busy
      ,input   rs2_tag
      ,input   rs2_rdata

      ,output  rd_addr
      ,output  rd_wr
      ,output  rd_tag
      //,input   rd_busy

   );

   modport rfu (

       input   rs1_addr
      ,output  rs1_busy
      ,output  rs1_tag
      ,output  rs1_rdata

      ,input   rs2_addr
      ,output  rs2_busy
      ,output  rs2_tag
      ,output  rs2_rdata

      ,input   rd_addr
      ,input   rd_wr
      ,input   rd_tag
     // ,output  rd_busy
   );

endinterface

interface dec2rvs_itf #(
   
    parameter  TAG_W       = 32'D4
   ,parameter  OPC_W       = 32'D4  
   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  RPW   = $clog2(ROB_DEPTH)

) () ;

   logic             req         ;
   logic             rdy         ;
   logic [TAG_W-1:0] tag         ;
   logic [OPC_W-1:0] opc         ;

   logic             src1_vld    ;
   logic             src2_vld    ;
   logic [TAG_W-1:0] src1_tag    ;
   logic [TAG_W-1:0] src2_tag    ;
   logic [31:0]      src1_wdata  ;
   logic [31:0]      src2_wdata  ;
   logic [11:0]      offset  ;
   logic [RPW-1:0]   inst_id     ;

   logic             wr_rd       ;
   logic             predict_valid ;
   logic             predict_taken ;

   modport dec (

       output  req       
      ,output  opc       
      ,input   tag       
      ,input   rdy       
      ,output  src1_vld  
      ,output  src2_vld  
      ,output  src1_tag  
      ,output  src2_tag  
      ,output  src1_wdata
      ,output  src2_wdata
      ,output  offset
      ,output  inst_id
      ,output  predict_valid
      ,output  predict_taken
      ,output  wr_rd
   );

   modport rvs (

       input   req       
      ,input   opc       
      ,output  tag       
      ,output  rdy       
      ,input   src1_vld  
      ,input   src2_vld  
      ,input   src1_tag  
      ,input   src2_tag  
      ,input   src1_wdata
      ,input   src2_wdata
      ,input   offset
      ,input   inst_id
      ,input  predict_valid
      ,input  predict_taken
      ,input   wr_rd
   );

endinterface

interface rvs2exu_itf #(

    parameter  TAG_W       = 32'D4 
   ,parameter  OPC_W       = 32'D4 
   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  ROB_PTR_W   = $clog2(ROB_DEPTH)

) (  );

   logic                   req      ;
   logic                   rdy      ;
   logic [TAG_W-1:0]       tag      ;
   logic [OPC_W-1:0]       opc      ;
   logic [31:0]            src1     ;
   logic [31:0]            src2     ;
   logic [11:0]            offset   ;
   logic [ROB_PTR_W-1:0]   inst_id  ;
   logic             predict_valid ;
   logic             predict_taken ;
   
   modport rvs (
       output  req   
      ,input   rdy   
      ,output  tag   
      ,output  opc   
      ,output  src1  
      ,output  src2  
      ,output  offset
      ,output  inst_id
      ,output  predict_valid
      ,output  predict_taken

   );

   modport exu (
       input   req   
      ,output  rdy   
      ,input   tag   
      ,input   opc   
      ,input   src1  
      ,input   src2  
      ,input   offset
      ,input   inst_id
      ,input  predict_valid
      ,input  predict_taken

   );

endinterface

interface exu2cdb_itf #(

    parameter  TAG_W       = 32'D4 
   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  ROB_PTR_W   = $clog2(ROB_DEPTH)

) () ;

   logic                   req      ;
   logic                   rdy      ;
   logic [TAG_W-1:0]       tag      ;
   logic [31:0]            wdata    ;
   logic [ROB_PTR_W-1:0]   inst_id  ;

   modport exu (

       output  req   
      ,input   rdy   
      ,output  tag   
      ,output  wdata 
      ,output  inst_id

   );

   modport cdb (

       input   req   
      ,output  rdy   
      ,input   tag   
      ,input   wdata 
      ,input   inst_id

   );

endinterface

interface cdb_itf #(

    parameter  TAG_W       = 32'D4 
   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  ROB_PTR_W   = $clog2(ROB_DEPTH)

) () ;

   logic                   wr       ;
//   logic [4:0]          addr  ;
   logic [TAG_W-1:0]       tag      ;
   logic [31:0]            wdata    ;
   logic [ROB_PTR_W-1:0]   inst_id  ;

   modport mst  (

       output  wr   
//      ,output  addr 
      ,output  tag  
      ,output  wdata
      ,output  inst_id

   );

   modport slv  (

       input   wr   
//      ,input   addr 
      ,input   tag  
      ,input   wdata
      ,input   inst_id

   );

endinterface

interface dec2rob_itf #(

    parameter  TAG_W       = 32'D4 
   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  RPW   = $clog2(ROB_DEPTH)

) () ;

   logic                   issue       ;
   logic [31:0]            inst        ;
   logic [31:0]            pc          ;
   logic [TAG_W-1:0]       tag         ;

   logic                   rs1_valid   ;
   logic                   rs2_valid   ;
   logic [TAG_W-1:0]       rs1_tag     ;
   logic [TAG_W-1:0]       rs2_tag     ;
   logic [31:0]            rs1_rdata   ;
   logic [31:0]            rs2_rdata   ;

   logic [RPW-1:0]   inst_id     ;

//   logic [ROB_PTR_W-1:0]   rob_id      ;
//   logic [TAG_W-1:0]       rs_tag      ;
//   logic [31:0]            rs_rdata    ;

   modport dec  (
       output  issue
      ,output  inst 
      ,output  pc   
      ,output  tag  

      ,input   rs1_valid
      ,input   rs2_valid
      ,input   rs1_tag   
      ,input   rs2_tag   
      ,input   rs1_rdata 
      ,input   rs2_rdata 

      ,input   inst_id

//      ,output  rob_id
//      ,input   rs_tag
//      ,input   rs_rdata
   );

   modport rob  (
       input   issue
      ,input   inst 
      ,input   pc   
      ,input   tag  

      ,output  rs1_valid
      ,output  rs2_valid
      ,output  rs1_tag   
      ,output  rs2_tag   
      ,output  rs1_rdata 
      ,output  rs2_rdata 

      ,output  inst_id

//      ,input   rob_id
//      ,output  rs_tag
//      ,output  rs_rdata

   );

endinterface

interface rvs2rob_itf 
//#(
//
//   parameter   TAG_W = 32'D4 
//
//)
() ;

//   logic [TAG_W-1:0] tag   ;
   logic             busy ;

   modport rvs  (
//       output  tag 
      input   busy 
   );

   modport rob  (
//       input   tag
      output  busy 
   );

endinterface

interface rob2lsu_itf 
#(

   parameter   ROB_PTR_W = 32'H4

)
() ;

   logic [ROB_PTR_W-1:0] inst_id   ;

   modport lsu  (
      input   inst_id
   );

   modport rob  (
      output  inst_id
   );

endinterface

interface rob2jmp_itf 
#(

   parameter   ROB_PTR_W = 32'H4

)
() ;

   logic [ROB_PTR_W-1:0]   pc_rob_id ;
   logic [31:0]            pc ;
   logic [ROB_PTR_W-1:0]   rob_id ;
   logic                   ready ;
   logic                   is_jmp ;

   modport rob  (

       input   pc_rob_id
      ,output  pc
      ,output  rob_id
      ,output  ready
      ,input   is_jmp

   );

   modport jmp  (

       output  pc_rob_id
      ,input   pc
      ,input   rob_id
      ,input   ready
      ,output  is_jmp
   );

endinterface



interface dec2rat_itf 
#(

   parameter   RPW = 32'H4

)
() ;

   logic                   rd_wr       ;
   logic [4:0]             rd_addr     ;
   logic [RPW-1:0]   rob_id      ;

   logic [4:0]             rs1_addr    ;
   logic [4:0]             rs2_addr    ;
//   logic                   rs1_valid   ;
//   logic                   rs2_valid   ;
//   logic [ROB_PTR_W-1:0]   rs1_rob_id  ;
//   logic [ROB_PTR_W-1:0]   rs2_rob_id  ;

   modport dec  (

       output  rd_wr     
      ,output  rd_addr   
      ,output  rob_id    

      ,output  rs1_addr
      ,output  rs2_addr
//      ,input   rs1_valid 
//      ,input   rs2_valid 
//      ,input   rs1_rob_id
//      ,input   rs2_rob_id

   );

   modport rat  (

       input   rd_wr     
      ,input   rd_addr   
      ,input   rob_id    

      ,input   rs1_addr
      ,input   rs2_addr
//      ,output  rs1_valid 
//      ,output  rs2_valid 
//      ,output  rs1_rob_id
//      ,output  rs2_rob_id

   );

endinterface

interface rob2rat_itf #(

   parameter   ROB_PTR_W = 32'H4

) ();

   logic                   commit   ;
   logic [4:0]             rd_addr  ;
   logic [ROB_PTR_W-1:0]   rob_id      ;
   logic                   rs1_valid   ;
   logic                   rs2_valid   ;
   logic [ROB_PTR_W-1:0]   rs1_rob_id  ;
   logic [ROB_PTR_W-1:0]   rs2_rob_id  ;

   modport rob (

       output  commit
      ,output  rd_addr
      ,output  rob_id
      ,input   rs1_valid 
      ,input   rs2_valid 
      ,input   rs1_rob_id
      ,input   rs2_rob_id

   );

   modport rat (

       input   commit
      ,input   rd_addr
      ,input   rob_id
      ,output  rs1_valid 
      ,output  rs2_valid 
      ,output  rs1_rob_id
      ,output  rs2_rob_id

   );

endinterface

interface rob2ifu_itf () ;

   logic          flush    ;
   logic [31:0]   pc_cur   ;
   logic [31:0]   pc_new   ;

endinterface

//interface rob2mon_itf () ;
//
//   logic          valid    ;
//   logic [63:0]   order    ;
//   logic [31:0]   inst     ;
//   logic [4:0]    rs1_addr ;
//   logic [4:0]    rs2_addr ;
//   logic [31:0]   rs1_rdata;
//   logic [31:0]   rs2_rdata;
//   logic [4:0]    rd_addr  ;
//   logic [31:0]   rd_wdata ;
//   logic [31:0]   pc_rdata ;
//   logic [31:0]   pc_wdata ;
//   logic [31:0]   mem_addr ;
//   logic [3:0]    mem_rmask;
//   logic [3:0]    mem_wmask;
//   logic [31:0]   mem_rdata;
//   logic [31:0]   mem_wdata;
//
//endinterface

interface dmem_itf ();

   logic [31:0]   addr  ;
   logic [3:0]    rmask ;
   logic [3:0]    wmask ;
   logic [31:0]   rdata ;
   logic [31:0]   wdata ;
   logic          resp  ;

   modport mst (

       output  addr 
      ,output  rmask
      ,output  wmask
      ,input   rdata
      ,output  wdata
      ,input   resp 
   );

   modport slv (

       input   addr 
      ,input   rmask
      ,input   wmask
      ,output  rdata
      ,input   wdata
      ,output  resp 

   );


endinterface

interface ifu2bpu_itf ();

   logic          fetch          ;
   logic [31:0]   fetch_pc       ;

   logic          predict_valid  ;
   logic          predict_taken  ;
   logic [31:0]   predict_pc     ;

   modport ifu (

       output  fetch         
      ,output  fetch_pc      
      ,input   predict_taken 
      ,input   predict_pc    
      ,input   predict_valid

   );

   modport bpu (

       input   fetch         
      ,input   fetch_pc      
      ,output  predict_taken 
      ,output  predict_pc    
      ,output  predict_valid

   );

endinterface

interface jmp2bpu_itf ();

   logic          execute        ;
   logic          update         ;
   logic [31:0]   execute_pc     ;
   logic [31:0]   execute_target ;
   logic          execute_taken  ;
   logic [3:0]    opc   ;

   modport jmp (

       output  execute      
      ,output  update
      ,output  execute_pc   
      ,output  execute_target
      ,output  execute_taken
      ,output  opc

   );

   modport bpu (

       input   execute      
      ,input   update
      ,input   execute_pc   
      ,input   execute_target
      ,input   execute_taken
      ,input   opc

   );

endinterface

