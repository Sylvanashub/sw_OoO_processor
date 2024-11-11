
module fetch (

    input   logic          clk
   ,input   logic          rst

   ,output  logic   [31:0] ufp_addr
   ,output  logic   [3:0]  ufp_rmask
   ,output  logic   [3:0]  ufp_wmask
   ,input   logic   [31:0] ufp_rdata
   ,output  logic   [31:0] ufp_wdata
   ,input   logic          ufp_resp

   ,input   logic          dequeue
   ,output  logic          is_empty
   ,output  logic   [63:0] dequeue_rdata

);

localparam  PC_RESET = 32'H1ECE_B000 ;
localparam DATA_WIDTH   = 64 ;
localparam IDLE   = 3'H0 ;
localparam READ   = 3'H1 ;
localparam WAIT   = 3'H2 ;


logic [31:0]   pc_r ;
logic [31:0]   pc_fifo_r ;
logic [2:0]    state_r ;
logic [2:0]    state_nxt ;

logic                   enqueue ;
logic [DATA_WIDTH-1:0]  wdata   ;
logic [DATA_WIDTH-1:0]  rdata   ;
logic                   is_full ;

logic pc_inc ;

assign pc_inc = (state_r == IDLE) || (state_r == READ) && ufp_resp ;
always_ff@(posedge clk)
begin
   if( rst )
      pc_r <= PC_RESET ;
   else if( pc_inc )
      pc_r <= pc_r + 32'H0000_0004 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      pc_fifo_r <= PC_RESET ;
   else if( pc_inc )
      pc_fifo_r <= pc_r ;
end

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
   case( state_r )
   IDLE : state_nxt = READ ;
   READ : if( ufp_resp ) state_nxt = is_full ? WAIT : READ ;
   WAIT : if( ~is_full ) state_nxt = READ ;
   default : state_nxt = state_r ;
   endcase
end



assign enqueue = (state_r == READ) && ufp_resp ;
assign wdata   = {pc_fifo_r,ufp_rdata} ;

sync_fifo #(

    .DATA_WIDTH   (DATA_WIDTH)
   ,.QUEUE_DEPTH  (16)

) u_sync_fifo (

   .* 

   // .clk       ()  //i logic                  
   //,.rst       ()  //i logic                  
   //,.enqueue   ()  //i logic                  
   //,.wdata     ()  //i logic  [DATA_WIDTH-1:0]
   //,.dequeue   ()  //i logic                  
   //,.rdata     ()  //o logic  [DATA_WIDTH-1:0]
   //,.is_full   ()  //o logic                  
   //,.is_empty  ()  //o logic                  

);
assign dequeue_rdata = rdata ;

assign ufp_addr  = pc_r ;
assign ufp_rmask = (state_r == IDLE || state_r == READ) ? '1 : '0 ;
assign ufp_wmask = '0 ;
assign ufp_wdata = '0 ;

endmodule
