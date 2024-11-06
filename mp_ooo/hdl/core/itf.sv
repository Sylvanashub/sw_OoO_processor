
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

   );

endinterface

interface dec2rvs_itf #(
   
   parameter   TAG_W = 32'D4 ,
   parameter   OPC_W = 32'D4 

) () ;

   logic             req         ;
   logic             rdy         ;
   logic [TAG_W-1:0] tag         ;
   logic [OPC_W-1:0] opc         ;
//   logic             sel         ;

   logic             src1_vld    ;
   logic             src2_vld    ;
   logic [TAG_W-1:0] src1_tag    ;
   logic [TAG_W-1:0] src2_tag    ;
   logic [31:0]      src1_wdata  ;
   logic [31:0]      src2_wdata  ;

   modport dec (

 //      output  sel       
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

   );

   modport rvs (

 //      input   sel       
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

   );

endinterface

interface rvs2exu_itf #(

   parameter   TAG_W = 32'D4 ,
   parameter   OPC_W = 32'D4 

) (  );

   logic             req   ;
   logic             rdy   ;
   logic [TAG_W-1:0] tag   ;
   logic [OPC_W-1:0] opc   ;
   logic [31:0]      src1  ;
   logic [31:0]      src2  ;
   
   modport rvs (
       output  req   
      ,input   rdy   
      ,output  tag   
      ,output  opc   
      ,output  src1  
      ,output  src2  
   );

   modport exu (
       input   req   
      ,output  rdy   
      ,input   tag   
      ,input   opc   
      ,input   src1  
      ,input   src2  
   );

endinterface

interface exu2cdb_itf #(

   parameter   TAG_W = 32'D4 

) () ;

   logic                req   ;
   logic                rdy   ;
   logic [TAG_W-1:0]    tag   ;
   logic [31:0]         wdata ;

   modport exu (

       output  req   
      ,input   rdy   
      ,output  tag   
      ,output  wdata 

   );

   modport cdb (

       input   req   
      ,output  rdy   
      ,input   tag   
      ,input   wdata 

   );

endinterface

interface cdb_itf #(

   parameter   TAG_W = 32'D4 

) () ;

   logic                wr    ;
//   logic [4:0]          addr  ;
   logic [TAG_W-1:0]    tag   ;
   logic [31:0]         wdata ;

   modport mst  (

       output  wr   
//      ,output  addr 
      ,output  tag  
      ,output  wdata

   );

   modport slv  (

       input   wr   
//      ,input   addr 
      ,input   tag  
      ,input   wdata

   );

endinterface

interface dec2rob_itf #(

   parameter   TAG_W = 32'D4 

) () ;

   logic             issue ;
   logic [31:0]      inst  ;
   logic [31:0]      pc    ;
   logic [TAG_W-1:0] tag   ;

   logic [TAG_W-1:0] rs1_tag   ;
   logic [TAG_W-1:0] rs2_tag   ;
   logic [31:0]      rs1_rdata ;
   logic [31:0]      rs2_rdata ;

   modport dec  (
       output  issue
      ,output  inst 
      ,output  pc   
      ,output  tag  

      ,output  rs1_tag   
      ,output  rs2_tag   
      ,output  rs1_rdata 
      ,output  rs2_rdata 
   );

   modport rob  (
       input   issue
      ,input   inst 
      ,input   pc   
      ,input   tag  

      ,input   rs1_tag   
      ,input   rs2_tag   
      ,input   rs1_rdata 
      ,input   rs2_rdata 
   );

endinterface

interface rob2mon_itf () ;

   logic          valid    ;
   logic [63:0]   order    ;
   logic [31:0]   inst     ;
   logic [4:0]    rs1_addr ;
   logic [4:0]    rs2_addr ;
   logic [31:0]   rs1_rdata;
   logic [31:0]   rs2_rdata;
   logic [4:0]    rd_addr  ;
   logic [31:0]   rd_wdata ;
   logic [31:0]   pc_rdata ;
   logic [31:0]   pc_wdata ;
   logic [31:0]   mem_addr ;
   logic [3:0]    mem_rmask;
   logic [3:0]    mem_wmask;
   logic [31:0]   mem_rdata;
   logic [31:0]   mem_wdata;

endinterface

