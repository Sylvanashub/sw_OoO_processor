
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

   ,input   logic          flush
   ,input   logic [31:0]   pc_new

);

localparam  PC_RESET = 32'H1ECE_B000 ;
localparam DATA_WIDTH   = 64 ;
localparam IDLE   = 3'H0 ;
localparam READ   = 3'H1 ;
localparam WAIT   = 3'H2 ;
localparam FLUSH  = 3'H3 ;


logic [31:0]   pc_r ;
logic [31:0]   pc_fifo_r ;
logic [2:0]    state_r ;
logic [2:0]    state_nxt ;

logic                   enqueue ;
logic [DATA_WIDTH-1:0]  wdata   ;
logic [DATA_WIDTH-1:0]  rdata   ;
logic                   is_full ;
logic                   afull ;
logic [4:0]             count    ;
logic pc_inc ;

assign pc_inc = (state_r == IDLE) || enqueue ;
always_ff@(posedge clk)
begin
   if( rst )
      pc_r <= PC_RESET ;
   else if( flush )
      pc_r <= pc_new ;
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

assign afull = count > 5'H08 ;

always_comb
begin
   state_nxt = state_r ;
   case( state_r )
   IDLE : state_nxt = READ ;
   READ :
   begin
      if( ufp_resp ) 
      begin
         if( flush )
            state_nxt = IDLE ;
         else if( is_full )
            state_nxt = WAIT ;
      end
      else
      begin
         if( flush )
            state_nxt = FLUSH ;
      end
   end
   WAIT : 
      if( flush )
         state_nxt = IDLE ;
      else if( ~is_full)
         state_nxt = READ ;
   FLUSH :
   begin
      if( ufp_resp )
         state_nxt = IDLE ;
   end
   default : state_nxt = state_r ;
   endcase
end

logic [31:0] ufp_rdata_r ;
always_ff@(posedge clk)
begin
   if( rst )
      ufp_rdata_r <= '0 ;
   else if( is_full && ufp_resp )
      ufp_rdata_r <= ufp_rdata ;
end


assign enqueue = ~flush && ((state_r == READ) && ~is_full && ufp_resp || state_r == WAIT && ~is_full) ;
assign wdata   = {pc_fifo_r, state_r == WAIT ? ufp_rdata_r : ufp_rdata} ;

sync_fifo #(

    .DATA_WIDTH   (DATA_WIDTH)
   ,.QUEUE_DEPTH  (16)

) u_sync_fifo (

   .* 
   ,.rst ( rst | flush )

);
assign dequeue_rdata = rdata ;

assign ufp_addr  = pc_r ;
assign ufp_rmask = ~flush && pc_inc ? '1 : '0 ;
assign ufp_wmask = '0 ;
assign ufp_wdata = '0 ;

endmodule
