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

logic   [31:0] ufp1_addr  ;
logic   [3:0]  ufp1_rmask ;
logic   [3:0]  ufp1_wmask ;
logic   [31:0] ufp1_rdata ;
logic   [31:0] ufp1_wdata ;
logic          ufp1_resp  ;
assign         ufp1_wmask = '0 ;
assign         ufp1_wdata = '0 ;

logic   [31:0] ufp0_addr  ;
logic   [3:0]  ufp0_rmask ;
logic   [3:0]  ufp0_wmask ;
logic   [31:0] ufp0_rdata ;
logic   [31:0] ufp0_wdata ;
logic          ufp0_resp  ;

logic   [31:0]  dfp1_addr  ;
logic           dfp1_read  ;
logic           dfp1_write ;
logic   [255:0] dfp1_rdata ;
logic   [255:0] dfp1_wdata ;
logic           dfp1_resp  ;

logic   [31:0]  dfp0_addr  ;
logic           dfp0_read  ;
logic           dfp0_write ;
logic   [255:0] dfp0_rdata ;
logic   [255:0] dfp0_wdata ;
logic           dfp0_resp  ;


cache u_icache ( 

    .* 
   ,.ufp_addr  ( ufp1_addr    )
   ,.ufp_rmask ( ufp1_rmask   )
   ,.ufp_wmask ( ufp1_wmask   )
   ,.ufp_rdata ( ufp1_rdata   )
   ,.ufp_wdata ( ufp1_wdata   )
   ,.ufp_resp  ( ufp1_resp    )
   
   ,.dfp_addr  ( dfp1_addr    )
   ,.dfp_read  ( dfp1_read    )
   ,.dfp_write ( dfp1_write   )
   ,.dfp_rdata ( dfp1_rdata   )
   ,.dfp_wdata ( dfp1_wdata   )
   ,.dfp_resp  ( dfp1_resp    )
   
) ;

cache u_dcache ( 

    .* 
   ,.ufp_addr  ( ufp0_addr    )
   ,.ufp_rmask ( ufp0_rmask   )
   ,.ufp_wmask ( ufp0_wmask   )
   ,.ufp_rdata ( ufp0_rdata   )
   ,.ufp_wdata ( ufp0_wdata   )
   ,.ufp_resp  ( ufp0_resp    )
                    
   ,.dfp_addr  ( dfp0_addr    )
   ,.dfp_read  ( dfp0_read    )
   ,.dfp_write ( dfp0_write   )
   ,.dfp_rdata ( dfp0_rdata   )
   ,.dfp_wdata ( dfp0_wdata   )
   ,.dfp_resp  ( dfp0_resp    )
   
) ;

cacheline_adapter u_cacheline_adapter ( .* ) ;

ooo u_ooo (

    .clk          ( clk )  //i logic          
   ,.rst          ( rst )  //i logic          
   
   ,.imem_addr    ( ufp1_addr    )  //o logic   [31:0] 
   ,.imem_rmask   ( ufp1_rmask   )  //o logic   [3:0]  
   ,.imem_rdata   ( ufp1_rdata   )  //i logic   [31:0] 
   ,.imem_resp    ( ufp1_resp    )  //i logic          

   ,.dmem_addr    ( ufp0_addr    )  //o logic   [31:0] 
   ,.dmem_rmask   ( ufp0_rmask   )  //o logic   [3:0]  
   ,.dmem_wmask   ( ufp0_wmask   )  //o logic   [3:0]  
   ,.dmem_rdata   ( ufp0_rdata   )  //i logic   [31:0] 
   ,.dmem_wdata   ( ufp0_wdata   )  //o logic   [31:0] 
   ,.dmem_resp    ( ufp0_resp    )  //i logic      

);


endmodule : cpu
