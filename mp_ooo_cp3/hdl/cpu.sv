module cpu
import rv32i_types::*;
(
    input   logic               clk,
    input   logic               rst,

    output  logic   [31:0]      bmem_addr,
    output  logic               bmem_read,
    output  logic               bmem_write,
    output  logic   [63:0]      bmem_wdata,
    input   logic               bmem_ready,

    input   logic   [31:0]      bmem_raddr,
    input   logic   [63:0]      bmem_rdata,
    input   logic               bmem_rvalid
);

logic   [31:0] ufp_addr  ;
logic   [3:0]  ufp_rmask ;
logic   [3:0]  ufp_wmask ;
logic   [31:0] ufp_rdata ;
logic   [31:0] ufp_wdata ;
logic          ufp_resp  ;

icache u_icache ( .* ) ;

assign ufp_wmask = '0 ;
assign ufp_wdata = '0 ;
//pipeline u_pipeline (
//
//    .clk          ( clk )  //i logic          
//   ,.rst          ( rst )  //i logic          
//`ifdef USE_PIPELINE
//   ,.imem_addr    ( ufp_addr  )  //o logic   [31:0] 
//   ,.imem_rmask   ( ufp_rmask )  //o logic   [3:0]  
//`endif
//   ,.imem_rdata   ( ufp_rdata )  //i logic   [31:0] 
//   ,.imem_resp    ( ufp_resp  )  //i logic          
//   ,.dmem_addr    ()  //o logic   [31:0] 
//   ,.dmem_rmask   ()  //o logic   [3:0]  
//   ,.dmem_wmask   ()  //o logic   [3:0]  
//   ,.dmem_rdata   ('0)  //i logic   [31:0] 
//   ,.dmem_wdata   ()  //o logic   [31:0] 
//   ,.dmem_resp    ('0)  //i logic          
//
//);

ooo u_ooo (

    .clk          ( clk )  //i logic          
   ,.rst          ( rst )  //i logic          
   ,.imem_addr    ( ufp_addr  )  //o logic   [31:0] 
   ,.imem_rmask   ( ufp_rmask )  //o logic   [3:0]  
   ,.imem_rdata   ( ufp_rdata )  //i logic   [31:0] 
   ,.imem_resp    ( ufp_resp  )  //i logic          
   ,.dmem_addr    ()  //o logic   [31:0] 
   ,.dmem_rmask   ()  //o logic   [3:0]  
   ,.dmem_wmask   ()  //o logic   [3:0]  
//   ,.dmem_rdata   ('0)  //i logic   [31:0] 
   ,.dmem_wdata   ()  //o logic   [31:0] 
//   ,.dmem_resp    ('0)  //i logic      

);


endmodule : cpu
