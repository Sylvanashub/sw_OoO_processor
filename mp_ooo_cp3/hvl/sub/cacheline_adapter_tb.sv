
`timescale 1 ns / 1 ps

class cacheline_adapter_rnd ;

   rand bit [63:0] bRndDramData ;

   rand bit          bRndDFPRW ;
   rand bit [255:0] bRndDFPWdata ;
   rand bit [31:0] bRndDFPAddr ;

   constraint cstDFPAddr {
      bRndDFPAddr[4:0] == '0 ;
   }

endclass

module cacheline_adapter_tb ;

localparam CLK_PERIOD = 2 ;
localparam RST_PERIOD = 100 ;


bit clk ;
bit rst ;
initial clk = 0 ;
always #(CLK_PERIOD/2) clk = ~clk ;

logic   [31:0]    dfp_addr    ;
logic             dfp_read    ;
logic             dfp_write   ;
logic   [255:0]   dfp_rdata   ;
logic   [255:0]   dfp_wdata   ;
logic             dfp_resp    ;
                             
logic   [31:0]    bmem_addr   ;
logic             bmem_read   ;
logic             bmem_write  ;
logic   [63:0]    bmem_wdata  ;
logic             bmem_ready  ;
                            
logic   [31:0]    bmem_raddr  ;
logic   [63:0]    bmem_rdata  ;
logic             bmem_rvalid ;

cacheline_adapter_rnd oRnd = new();

task reset ();

   rst = 1'H1 ;
   @(negedge clk);
   rst = 1'H0 ;

endtask

task gen_random_bmem ( int iMemSize = 1024 );

   for(int i=0;i<iMemSize;i++)
   begin
      oRnd.randomize() ;
      mem.internal_memory_array[i] = oRnd.bRndDramData ;
   end

endtask

task do_dfp_read ( bit [31:0] bAddr );

   logic [255:0] bExp ;


   @(posedge clk);
   dfp_addr <= bAddr ;
   dfp_read <= 1'H1 ;
   dfp_write<= 1'H0 ;

   @(posedge clk);
   while( !dfp_resp )
   begin
      @(posedge clk);
   end
   dfp_read <= 1'H0 ;

   $display("@%t [INF] DFP Read 0x%x = 0x%x",$time,bAddr,dfp_rdata);

   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,bAddr,bExp);
      @(posedge clk);
      $finish();
   end


endtask

function logic [255:0] bmem_backdoor_read ( bit [31:0] bAddr );

   if( !mem.internal_memory_array.exists(bAddr[31:5]) )
   begin
      $display("@%t [ERR] address (0x%x) doesn't exists !!!",
      $time,bAddr);
      $finish();
   end

   return mem.internal_memory_array[bAddr[31:5]] ;

endfunction


task do_dfp_write ( bit [31:0] bAddr , bit [255:0] bWdata );

   @(posedge clk);
   dfp_addr <= bAddr ;
   dfp_read <= 1'H0 ;
   dfp_write<= 1'H1 ;
   dfp_wdata<= bWdata ;

   @(posedge clk);
   while( !dfp_resp )
   begin
      @(posedge clk);
   end
   dfp_read <= 1'H0 ;
   dfp_write <= 1'H0 ;
   dfp_wdata<= 'x ;

   $display("@%t [INF] DFP Write 0x%x = 0x%x",$time,bAddr,bWdata);

endtask

task init () ;

   dfp_addr    = '0 ;
   dfp_read    = '0 ;
   dfp_write   = '0 ;
   dfp_wdata   = '0 ;

endtask

initial
begin

   init() ;

   reset () ;

   //#1 ;
   //gen_random_bmem() ;

   //------------------------------------------------------------------------------
   // check address min edge case
   //------------------------------------------------------------------------------

   $display("@%t [INF] Checking min address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write( i*32 , oRnd.bRndDFPWdata );
   end

   for(int i=0;i<16;i++)
   begin
      do_dfp_read( i*32 ) ;
   end

   //------------------------------------------------------------------------------
   // check address max edge case
   //------------------------------------------------------------------------------

   $display("@%t [INF] Checking max address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
   end

   for(int i=0;i<16;i++)
   begin
      do_dfp_read( 32'HFFFF_FE00 + i*32 ) ;
   end

   //------------------------------------------------------------------------------
   // random access test
   //------------------------------------------------------------------------------
   $display("@%t [INF] Random access test ...",$time);
   begin
      
      bit [31:0] bStartAddr ;

      //Write random value
      oRnd.randomize();
      bStartAddr = oRnd.bRndDFPAddr ;
      bStartAddr[14:0] = '0 ;

      for(int i=0;i<1024;i++)
      begin
         oRnd.randomize();
         do_dfp_write ( bStartAddr + i*32 , oRnd.bRndDFPWdata ) ;
      end

      repeat(1000)
      begin
         oRnd.randomize with { bRndDFPAddr[31:15] == bStartAddr[31:15] ;} ;
         if( oRnd.bRndDFPRW )
            do_dfp_write ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
         else
            do_dfp_read ( oRnd.bRndDFPAddr ) ;
      end

   end


   #1us ;
   $finish();

end

mem_itf_banked itf ( .* );

assign itf.addr   = bmem_addr    ;
assign itf.read   = bmem_read    ;
assign itf.write  = bmem_write   ;
assign itf.wdata  = bmem_wdata   ;

assign bmem_ready = itf.ready    ;
assign bmem_raddr = itf.raddr    ;
assign bmem_rdata = itf.rdata    ;
assign bmem_rvalid= itf.rvalid   ;

cacheline_adapter dut (
   .*
);

banked_memory mem (
   .*
);

initial
begin
   $fsdbDumpfile("dump.fsdb");
   $fsdbDumpvars(0, "+all");
   //$vcdpluson(0);
end

endmodule

