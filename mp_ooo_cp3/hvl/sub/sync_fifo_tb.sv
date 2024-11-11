
`timescale 1 ns / 1 ps

module sync_fifo_tb ;

localparam CLK_PERIOD = 2 ;
localparam RST_PERIOD = 100 ;

localparam DATA_WIDTH = 64 ;
localparam QUEUE_DEPTH = 32 ;

bit clk ;
bit rst ;
initial clk = 0 ;
always #(CLK_PERIOD/2) clk = ~clk ;


logic                   enqueue  ;
logic [DATA_WIDTH-1:0]  wdata    ;
logic                   dequeue  ;
logic [DATA_WIDTH-1:0]  rdata    ;
logic                   is_full  ;
logic                   is_empty ;

task reset ();

   rst = 1'H1 ;
   #(RST_PERIOD);
   rst = 1'H0 ;

endtask

//------------------------------------------------------------------------------
// FIFO access tasks
//------------------------------------------------------------------------------

task fifo_single_write ( logic [DATA_WIDTH-1:0] wdata_in = '0 ) ;

   @(posedge clk);
   enqueue  <= 1'H1 ;
   wdata    <= wdata_in ;
   @(posedge clk);
   enqueue  <= 1'H0 ;
   wdata    <= 'x ;
   $display("@%t [INF] FIFO write 0x%x",$time,wdata_in);

endtask

task fifo_single_read ( ) ;

   @(posedge clk);
   dequeue  <= 1'H1 ;
   
   @(posedge clk);
   dequeue  <= 1'H0 ;

   @(posedge clk);
   $display("@%t [INF] FIFO read 0x%x",$time,rdata);

endtask

task fifo_burst_write ( int iLen = 1 ) ;


   repeat(iLen)
   begin
      @(posedge clk);
      enqueue  <= 1'H1 ;
      oRnd.randomize() ;
      wdata    <= oRnd.bRndWdata ;
      $display("@%t [INF] FIFO write 0x%x",$time,oRnd.bRndWdata);
   end

   @(posedge clk);
   enqueue  <= 1'H0 ;
   wdata    <= 'x ;

endtask

task fifo_burst_read ( int iLen = 1 ) ;

   for(int i=0;i<iLen;i++)
   begin
      @(posedge clk);
      if( i > 0 )
      begin
         $display("@%t [INF] FIFO read 0x%x",$time,rdata);
      end
      dequeue  <= 1'H1 ;
   end
   
   @(posedge clk);
   dequeue  <= 1'H0 ;

   @(posedge clk);

endtask

//------------------------------------------------------------------------------
// Main test
//------------------------------------------------------------------------------
sync_fifo_rnd oRnd = new() ;

initial
begin
   
   enqueue = '0 ;
   dequeue = '0 ;
   wdata = '0 ;

   reset() ;

   //Generate full condition
   for(int i=0;i<QUEUE_DEPTH;i++)
   begin
      fifo_single_write($urandom());
   end

   //Generate empty condition
   for(int i=0;i<QUEUE_DEPTH;i++)
   begin
      fifo_single_read();
   end

   //random test
   for(int i=0;i<3;i++)
   begin
      repeat(5000)
      begin
         if( i == 0 )
            //#Write  >>> #Read , full is generated
            oRnd.randomize with { eRndType dist {sync_fifo_rnd::WRITE:=10, sync_fifo_rnd::READ:=1 } ; }  ;
         else if( i == 1 )
            //#Write  <<< #Read , empty is generated
            oRnd.randomize with { eRndType dist {sync_fifo_rnd::WRITE:=1, sync_fifo_rnd::READ:=10 } ; }  ;
         else
            oRnd.randomize() ;

         fork
         begin
            case( oRnd.eRndType )
            sync_fifo_rnd::WRITE ,
            sync_fifo_rnd::RW :
            begin
               if( oRnd.bIsBurst )
                  fifo_burst_write( oRnd.iWrLen ) ;
               else
                  fifo_single_write( oRnd.bRndWdata ) ;
            end
            endcase
         end
         begin
            case( oRnd.eRndType )
            sync_fifo_rnd::READ ,
            sync_fifo_rnd::RW :
            begin
               if( oRnd.bIsBurst )
                  fifo_burst_read( oRnd.iRdLen ) ;
               else
                  fifo_single_read();
            end
            endcase
         end
         join
      end
   end

   repeat(10)@(posedge clk);
   $finish();
end

//------------------------------------------------------------------------------
// DUT
//------------------------------------------------------------------------------

sync_fifo #(
    .DATA_WIDTH   (DATA_WIDTH)
   ,.QUEUE_DEPTH  (QUEUE_DEPTH)
) dut (               
   .*
);

//------------------------------------------------------------------------------
// RM
//------------------------------------------------------------------------------
sync_fifo_rm #(
    .DATA_WIDTH   (DATA_WIDTH)
   ,.QUEUE_DEPTH  (QUEUE_DEPTH)
) rm (
   .*
);

initial
begin
   $fsdbDumpfile("dump.fsdb");
   $fsdbDumpvars(0, "+all");
   //$vcdpluson(0);
end

endmodule
