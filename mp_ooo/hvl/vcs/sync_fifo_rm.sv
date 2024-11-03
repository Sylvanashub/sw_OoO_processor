
`timescale 1 ns / 1 ps

module sync_fifo_rm #(

   parameter   DATA_WIDTH  = 32'D64 ,
   parameter   QUEUE_DEPTH = 32'D16

)(

    input   logic                   clk
   ,input   logic                   rst

   ,input   logic                   enqueue
   ,input   logic  [DATA_WIDTH-1:0] wdata 

   ,input   logic                   dequeue
   ,input   logic  [DATA_WIDTH-1:0] rdata

   ,input   logic                   is_full
   ,input   logic                   is_empty

);

logic [DATA_WIDTH-1:0] queue [$] ;
logic [DATA_WIDTH-1:0] rdata_exp ;

always@(posedge clk)
begin
   if( enqueue && (queue.size() < QUEUE_DEPTH) )
   begin
      logic [DATA_WIDTH-1:0] d ;
      d <= wdata ;
      //Add delay to eliminate race condition at rdata_exp
      #0.01 ;
      queue.push_back( d ) ;
      //$display("@%t [RM] write 0x%x",$time,d); 
   end
end

always@(posedge clk)
begin
   if( rst )
      rdata_exp <= {DATA_WIDTH{1'H0}} ;
   else if( dequeue && (queue.size() > 0) )
   begin
      rdata_exp <= queue.pop_front() ;
   end
end

always@(posedge clk)
begin
   if( ~rst )
   begin
      if( rdata !== rdata_exp )
      begin
         $error("rdata = 0x%x , expect = 0x%x",rdata,rdata_exp);
         @(posedge clk);
         $finish();
      end
   end
end

always@(negedge clk)
begin
   if( is_full && (queue.size() != QUEUE_DEPTH) )
   begin
      $error("FIFO's full = 1, expect = 0");
      @(posedge clk);
      $finish();
   end
   if( ~is_full && (queue.size() == QUEUE_DEPTH) )
   begin
      $error("FIFO's full = 0, expect = 1");
      @(posedge clk);
      $finish();
   end

   if( is_empty && (queue.size() != 0) )
   begin
      $error("FIFO's empty = 1, expect = 0");
      @(posedge clk);
      $finish();
   end
   if( ~is_empty && (queue.size() == 0) )
   begin
      $error("FIFO's empty = 0, expect = 1");
      @(posedge clk);
      $finish();
   end
end


endmodule
