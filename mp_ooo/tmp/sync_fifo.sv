
module sync_fifo #(

   parameter   DATA_WIDTH  = 32'D64 ,
   parameter   QUEUE_DEPTH = 32'D16

)(

    input   logic                   clk
   ,input   logic                   rst

   ,input   logic                   enqueue
   ,input   logic  [DATA_WIDTH-1:0] wdata 

   ,input   logic                   dequeue
   ,output  logic  [DATA_WIDTH-1:0] rdata

   ,output  logic                   is_full
   ,output  logic                   is_empty

);

//Add extra bit for is_full/is_empty
localparam  PTR_WIDTH = $clog2(QUEUE_DEPTH) + 1 ;

logic [DATA_WIDTH-1:0] queue [QUEUE_DEPTH] ;
logic [PTR_WIDTH-1:0] wptr_r ;
logic [PTR_WIDTH-1:0] rptr_r ;

logic [PTR_WIDTH-1:0] wptr_nxt ;
logic [PTR_WIDTH-1:0] rptr_nxt ;

//------------------------------------------------------------------------------
// Write pointer
// only increase when enqueue and not dequeue
//------------------------------------------------------------------------------
always_ff@(posedge clk)
begin
   if( rst )
      wptr_r <= {PTR_WIDTH{1'H0}} ;
   else if( enqueue && ~is_full )
      wptr_r <= wptr_r + {{(PTR_WIDTH-1){1'H0}},1'H1} ;
end

//------------------------------------------------------------------------------
// Read pointer
// only increase when edqueue and not enqueue
//------------------------------------------------------------------------------
always_ff@(posedge clk)
begin
   if( rst )
      rptr_r <= {PTR_WIDTH{1'H0}} ;
   else if( dequeue && ~is_empty )
      rptr_r <= rptr_r + {{(PTR_WIDTH-1){1'H0}},1'H1} ;
end

always_ff@(posedge clk)
begin
   if( enqueue && ~is_full )
   begin
      queue[wptr_r[PTR_WIDTH-2:0]] <= wdata ;
   end
end

always_ff@(posedge clk)
begin
   if( rst )
      rdata <= {DATA_WIDTH{1'H0}} ;
   else if( dequeue && ~is_empty )
      rdata <= queue[rptr_r[PTR_WIDTH-2:0]] ;
end


//------------------------------------------------------------------------------
// the extra bit is different 
// when write pointer catch up with read pointer 
//------------------------------------------------------------------------------
assign is_full  = (wptr_r[PTR_WIDTH-1] != rptr_r[PTR_WIDTH-1]) && (wptr_r[PTR_WIDTH-2:0] == rptr_r[PTR_WIDTH-2:0]) ;

//------------------------------------------------------------------------------
// the extra bit is the same
// when read pointer catch up with write pointer 
//------------------------------------------------------------------------------
assign is_empty = wptr_r == rptr_r ;

endmodule
