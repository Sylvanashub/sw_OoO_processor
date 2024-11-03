module icache (
    input   logic           clk
   ,input   logic           rst

    // cpu side signals ufp -> upward facing port
   ,input   logic   [31:0]  ufp_addr
   ,input   logic   [3:0]   ufp_rmask
   ,input   logic   [3:0]   ufp_wmask
   ,output  logic   [31:0]  ufp_rdata
   ,input   logic   [31:0]  ufp_wdata
   ,output  logic           ufp_resp

   ,output  logic   [31:0]    bmem_addr
   ,output  logic             bmem_read
   ,output  logic             bmem_write
   ,output  logic   [63:0]    bmem_wdata
   ,input   logic             bmem_ready

   ,input   logic   [31:0]    bmem_raddr
   ,input   logic   [63:0]    bmem_rdata
   ,input   logic             bmem_rvalid

);

logic   [31:0]  dfp_addr ;
logic           dfp_read ;
logic           dfp_write ;
logic   [255:0] dfp_rdata ;
logic   [255:0] dfp_wdata ;
logic           dfp_resp ;

cache u_cache ( .* );

cacheline_adapter u_cacheline_adapter ( .* ) ;

endmodule
