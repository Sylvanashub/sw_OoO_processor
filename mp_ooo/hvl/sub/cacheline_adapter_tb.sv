
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


logic   [31:0]    dfp0_addr;   
logic             dfp0_read;
logic             dfp0_write;
logic   [255:0]   dfp0_rdata;
logic   [255:0]   dfp0_wdata;
logic             dfp0_resp;
                           
logic   [31:0]    dfp1_addr;
logic             dfp1_read;
logic             dfp1_write;
logic   [255:0]   dfp1_rdata;
logic   [255:0]   dfp1_wdata;
logic             dfp1_resp;


                            
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

task do_dfp_read_meanwhile ( bit [31:0] bAddr );

   logic [255:0] bExp ;

   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H1 ;
   dfp0_write<= 1'H0 ;

   dfp1_addr <= bAddr + 6'H20 ;
   dfp1_read <= 1'H1 ;
   dfp1_write<= 1'H0 ;
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;

   $display("@%t [INF] DFP0 Read 0x%x = 0x%x",$time,bAddr,dfp0_rdata);
   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp0_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,bAddr,bExp);
      @(posedge clk);
      $finish();
   end

   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,dfp1_addr,dfp1_rdata);

   bExp = bmem_backdoor_read( bAddr + 6'H20 ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp1_addr,bExp);
      @(posedge clk);
      $finish();
   end
   
endtask

task do_dfp_write_meanwhile ( bit [31:0] bAddr , bit [255:0] bWdata );

   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H0 ;
   dfp0_write<= 1'H1 ;
   dfp0_wdata<= bWdata ;

   dfp1_addr <= bAddr + 6'H20;
   dfp1_read <= 1'H0 ;
   dfp1_write<= 1'H1 ;
   dfp1_wdata<= bWdata ; 
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;
   dfp0_write <= 1'H0 ;
   dfp0_wdata<= 'x ;

   $display("@%t [INF] DFP0 Write 0x%x  = 0x%x",$time,bAddr,bWdata);

   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;
   dfp1_write <= 1'H0 ;
   dfp1_wdata<= 'x ;

   $display("@%t [INF] DFP1 Write 0x%x = 0x%x",$time,dfp1_addr,bWdata);

endtask

task do_dfp_write0_read1_meanwhile( bit [31:0] bAddr , bit [255:0] bWdata );

   logic [255:0] bExp ;
   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H0 ;
   dfp0_write<= 1'H1 ;
   dfp0_wdata<= bWdata ;

   dfp1_addr <= bAddr;
   dfp1_read <= 1'H1 ;
   dfp1_write<= 1'H0 ;
   dfp1_wdata<= bWdata ; 
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;
   dfp0_write <= 1'H0 ;
   dfp0_wdata<= 'x ;

   $display("@%t [INF] DFP0 Write 0x%x = 0x%x",$time,bAddr,bWdata);

   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,bAddr,dfp1_rdata);

   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp1_addr,bExp);
      @(posedge clk);
      $finish();
   end

endtask

task do_dfp_write1_read0_meanwhile( bit [31:0] bAddr , bit [255:0] bWdata );

   logic [255:0] bExp ;
   @(posedge clk);
   dfp1_addr <= bAddr ;
   dfp1_read <= 1'H0 ;
   dfp1_write<= 1'H1 ;
   dfp1_wdata<= bWdata ;

   dfp0_addr <= bAddr;
   dfp0_read <= 1'H1 ;
   dfp0_write<= 1'H0 ;
   dfp0_wdata<= bWdata ; 
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;

   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp1_addr,bExp);
      @(posedge clk);
      $finish();
   end

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,bAddr,dfp0_rdata);

   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;
   dfp1_write <= 1'H0 ;
   dfp1_wdata<= 'x ;
   
   $display("@%t [INF] DFP0 Write 0x%x = 0x%x",$time,bAddr,bWdata);


endtask  

task do_dfp01_read ( bit [31:0] bAddr );

   logic [255:0] bExp ;

   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H1 ;
   dfp0_write<= 1'H0 ;

   @(posedge clk);
   dfp1_addr <= bAddr + 6'H20 ;
   dfp1_read <= 1'H1 ;
   dfp1_write<= 1'H0 ;
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;

   $display("@%t [INF] DFP0 Read 0x%x = 0x%x",$time,bAddr,dfp0_rdata);
   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp0_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,bAddr,bExp);
      @(posedge clk);
      $finish();
   end


   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,dfp1_addr,dfp1_rdata);

   bExp = bmem_backdoor_read( bAddr + 6'H20 ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp1_addr,bExp);
      @(posedge clk);
      $finish();
   end
   
endtask

task do_dfp01_write ( bit [31:0] bAddr , bit [255:0] bWdata );

   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H0 ;
   dfp0_write<= 1'H1 ;
   dfp0_wdata<= bWdata ;

   @(posedge clk);
   dfp1_addr <= bAddr + 6'H20;
   dfp1_read <= 1'H0 ;
   dfp1_write<= 1'H1 ;
   dfp1_wdata<= bWdata ; 
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;
   dfp0_write <= 1'H0 ;
   dfp0_wdata<= 'x ;

   $display("@%t [INF] DFP0 Write 0x%x  = 0x%x",$time,bAddr,bWdata);

   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;
   dfp1_write <= 1'H0 ;
   dfp1_wdata<= 'x ;

   $display("@%t [INF] DFP1 Write 0x%x = 0x%x",$time,dfp1_addr,bWdata);

endtask

task do_dfp10_read ( bit [31:0] bAddr );

   logic [255:0] bExp ;

   @(posedge clk);
   dfp1_addr <= bAddr ;
   dfp1_read <= 1'H1 ;
   dfp1_write<= 1'H0 ;

   @(posedge clk);
   dfp0_addr <= bAddr + 7'H40 ;
   dfp0_read <= 1'H1 ;
   dfp0_write<= 1'H0 ;
   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,bAddr,dfp1_rdata);
   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,bAddr,bExp);
      @(posedge clk);
      $finish();
   end


   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;

   $display("@%t [INF] DFP0 Read 0x%x = 0x%x",$time,dfp0_addr,dfp0_rdata);

   bExp = bmem_backdoor_read( bAddr + 7'H40 ) ;

   if( dfp0_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp0_addr,bExp);
      @(posedge clk);
      $finish();
   end
   
endtask

task do_dfp10_write ( bit [31:0] bAddr , bit [255:0] bWdata );

   @(posedge clk);
   dfp1_addr <= bAddr ;
   dfp1_read <= 1'H0 ;
   dfp1_write<= 1'H1 ;
   dfp1_wdata<= bWdata ;

   @(posedge clk);
   dfp0_addr <= bAddr + 7'H40;
   dfp0_read <= 1'H0 ;
   dfp0_write<= 1'H1 ;
   dfp0_wdata<= bWdata ; 
   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;
   dfp1_write <= 1'H0 ;
   dfp1_wdata<= 'x ;

   $display("@%t [INF] DFP1 Write 0x%x  = 0x%x",$time,bAddr,bWdata);

   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;
   dfp0_write <= 1'H0 ;
   dfp0_wdata<= 'x ;

   $display("@%t [INF] DFP0 Write 0x%x = 0x%x",$time,dfp0_addr,bWdata);

endtask

task do_dfp_write0_read1( bit [31:0] bAddr , bit [255:0] bWdata );

   logic [255:0] bExp ;
   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H0 ;
   dfp0_write<= 1'H1 ;
   dfp0_wdata<= bWdata ;

   @(posedge clk);
   dfp1_addr <= bAddr;
   dfp1_read <= 1'H1 ;
   dfp1_write<= 1'H0 ;
   dfp1_wdata<= bWdata ; 
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;
   dfp0_write <= 1'H0 ;
   dfp0_wdata<= 'x ;

   $display("@%t [INF] DFP0 Write 0x%x = 0x%x",$time,bAddr,bWdata);

   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,bAddr,dfp1_rdata);

   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp1_addr,bExp);
      @(posedge clk);
      $finish();
   end

endtask 

task do_dfp_write1_read0( bit [31:0] bAddr , bit [255:0] bWdata );

   logic [255:0] bExp ;
   @(posedge clk);
   dfp1_addr <= bAddr ;
   dfp1_read <= 1'H0 ;
   dfp1_write<= 1'H1 ;
   dfp1_wdata<= bWdata ;

   @(posedge clk);
   dfp0_addr <= bAddr;
   dfp0_read <= 1'H1 ;
   dfp0_write<= 1'H0 ;
   dfp0_wdata<= bWdata ; 
   while( !dfp1_resp )
   begin
      @(posedge clk);
   end
   dfp1_read <= 1'H0 ;
   dfp1_write <= 1'H0 ;
   dfp1_wdata<= 'x ;

   $display("@%t [INF] DFP0 Write 0x%x = 0x%x",$time,bAddr,bWdata);

   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;

   $display("@%t [INF] DFP1 Read 0x%x = 0x%x",$time,bAddr,dfp0_rdata);

   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp1_rdata !== bExp )
   begin
      $display("@%t [ERR] Expect 0x%x = 0x%x",$time,dfp1_addr,bExp);
      @(posedge clk);
      $finish();
   end

endtask 

task do_dfp_read ( bit [31:0] bAddr );

   logic [255:0] bExp ;


   @(posedge clk);
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H1 ;
   dfp0_write<= 1'H0 ;

   @(posedge clk);
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;

   $display("@%t [INF] DFP Read 0x%x = 0x%x",$time,bAddr,dfp0_rdata);

   bExp = bmem_backdoor_read( bAddr ) ;

   if( dfp0_rdata !== bExp )
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
   dfp0_addr <= bAddr ;
   dfp0_read <= 1'H0 ;
   dfp0_write<= 1'H1 ;
   dfp0_wdata<= bWdata ;

   @(posedge clk);
   while( !dfp0_resp )
   begin
      @(posedge clk);
   end
   dfp0_read <= 1'H0 ;
   dfp0_write <= 1'H0 ;
   dfp0_wdata<= 'x ;

   $display("@%t [INF] DFP Write 0x%x = 0x%x",$time,bAddr,bWdata);

endtask

task init () ;

   dfp0_addr    = '0 ;
   dfp0_read    = '0 ;
   dfp0_write   = '0 ;
   dfp0_wdata   = '0 ;

   dfp1_addr    = '0 ;
   dfp1_read    = '0 ;
   dfp1_write   = '0 ;
   dfp1_wdata   = '0 ;

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

   //------------------------------------------------------------------------------
   // two input dfp0 and dfp1 raed or write test meanwhile
   //------------------------------------------------------------------------------
   $display("@%t [INF] Checking dfp0 and dfp1 write min address meanwhile...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write_meanwhile( i*32 , oRnd.bRndDFPWdata );
   end
   $display("@%t [INF] Checking dfp0 and dfp1 read min address meanwhile...",$time);
   for(int i=0;i<16;i++)
   begin
      do_dfp_read_meanwhile( i*32 ) ;
   end
   $display("@%t [INF] Checking dfp0 write and dfp1 read min address meanwhile...",$time);
   for(int i=0;i<16;i++)
   begin
      do_dfp_write0_read1_meanwhile( i*32, oRnd.bRndDFPWdata  ) ;
   end
   $display("@%t [INF] Checking dfp0 read and dfp1 write min address meanwhile",$time);
   for(int i=0;i<16;i++)
   begin
      do_dfp_write1_read0_meanwhile( i*32, oRnd.bRndDFPWdata  ) ;
   end

   $display("@%t [INF] Checking dfp0 and dfp1 write max address meanwhile...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write_meanwhile( 32'HFFFF_F000 + i*32 , oRnd.bRndDFPWdata );
   end
   $display("@%t [INF] Checking dfp0 and dfp1 read max address meanwhile...",$time);
   for(int i=0;i<16;i++)
   begin
      do_dfp_read_meanwhile( 32'HFFFF_F000 + i*32 ) ;
   end
   $display("@%t [INF] Checking dfp0 write and dfp1 read max address meanwhile...",$time);
   for(int i=0;i<16;i++)
   begin
      do_dfp_write0_read1_meanwhile( 32'HFFFF_F000 + i*32, oRnd.bRndDFPWdata  ) ;
   end
   $display("@%t [INF] Checking dfp0 read and dfp1 write max address meanwhile",$time);
   for(int i=0;i<16;i++)
   begin
      do_dfp_write1_read0_meanwhile( 32'HFFFF_F000 + i*32, oRnd.bRndDFPWdata  ) ;
   end

   begin
      
      bit [31:0] bStartAddrm ;
      $display("@%t [INF] Checking dfp0 and dfp1 random address ...",$time);

      //Write random value
      oRnd.randomize();
      bStartAddrm = oRnd.bRndDFPAddr ;
      bStartAddrm[14:0] = '0 ;

      for(int i=0;i<1024;i++)
      begin
         oRnd.randomize();
         do_dfp_write_meanwhile ( bStartAddrm + i*32 , oRnd.bRndDFPWdata ) ;
      end

      repeat(1000)
      begin
         oRnd.randomize with { bRndDFPAddr[31:15] == bStartAddrm[31:15] ;} ;
         if( oRnd.bRndDFPRW )
            do_dfp_write_meanwhile ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
         else
            do_dfp_read_meanwhile ( oRnd.bRndDFPAddr ) ;
      end

      repeat(1000)
      begin
         oRnd.randomize with { bRndDFPAddr[31:15] == bStartAddrm[31:15] ;} ;
         if( oRnd.bRndDFPRW )
            do_dfp_write0_read1_meanwhile ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
         else
            do_dfp_write1_read0_meanwhile ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
      end


   end

   //------------------------------------------------------------------------------
   // two input dfp0 and dfp1 raed or write test no meanwhile
   //------------------------------------------------------------------------------

   $display("@%t [INF] Checking dfp0 and dfp1 min address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp01_write( i*32 , oRnd.bRndDFPWdata );
   end

   for(int i=0;i<16;i++)
   begin
      do_dfp01_read( i*32 ) ;
   end

   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp10_write( i*32 , oRnd.bRndDFPWdata );
   end

   for(int i=0;i<16;i++)
   begin
      do_dfp10_read( i*32 ) ;
   end

   $display("@%t [INF] Checking dfp0 and dfp1 max address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp01_write( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
   end

   for(int i=0;i<16;i++)
   begin
      do_dfp01_read( 32'HFFFF_FE00 + i*32 ) ;
   end

   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp10_write( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
   end

   for(int i=0;i<16;i++)
   begin
      do_dfp10_read( 32'HFFFF_FE00 + i*32 ) ;
   end 

   begin
      
      bit [31:0] bStartAddr10 ;
      $display("@%t [INF] Checking dfp0 and dfp1 random address ...",$time);

      //Write random value
      oRnd.randomize();
      bStartAddr10 = oRnd.bRndDFPAddr ;
      bStartAddr10[14:0] = '0 ;

      for(int i=0;i<1024;i++)
      begin
         oRnd.randomize();
         do_dfp10_write ( bStartAddr10 + i*32 , oRnd.bRndDFPWdata ) ;
      end

      repeat(1000)
      begin
         oRnd.randomize with { bRndDFPAddr[31:15] == bStartAddr10[31:15] ;} ;
         if( oRnd.bRndDFPRW )
            do_dfp10_write ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
         else
            do_dfp10_read ( oRnd.bRndDFPAddr ) ;
      end

   end

   begin
      
      bit [31:0] bStartAddr01 ;

      //Write random value
      oRnd.randomize();
      bStartAddr01 = oRnd.bRndDFPAddr ;
      bStartAddr01[14:0] = '0 ;

      for(int i=0;i<1024;i++)
      begin
         oRnd.randomize();
         do_dfp01_write ( bStartAddr01 + i*32 , oRnd.bRndDFPWdata ) ;
      end

      repeat(1000)
      begin
         oRnd.randomize with { bRndDFPAddr[31:15] == bStartAddr01[31:15] ;} ;
         if( oRnd.bRndDFPRW )
            do_dfp01_write ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
         else
            do_dfp01_read ( oRnd.bRndDFPAddr ) ;
      end

      $display("@%t [INF] Checking dfp0 write dfp1 read random address ...",$time);
      repeat(1000)
      begin
         oRnd.randomize with { bRndDFPAddr[31:15] == bStartAddr01[31:15] ;} ;
         if( oRnd.bRndDFPRW )
            do_dfp_write0_read1 ( oRnd.bRndDFPAddr , oRnd.bRndDFPWdata ) ;
         else
            do_dfp_write1_read0 ( oRnd.bRndDFPAddr , oRnd.bRndDFPAddr ) ;
      end

   end

   $display("@%t [INF] Checking dfp0 write dfp1 read min address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write0_read1( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
   end
   $display("@%t [INF] Checking dfp1 write dfp0 read min address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write1_read0( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
   end

   $display("@%t [INF] Checking dfp0 write dfp1 read max address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write0_read1( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
   end
   $display("@%t [INF] Checking dfp1 write dfp0 read max address ...",$time);
   for(int i=0;i<16;i++)
   begin
      oRnd.randomize();
      do_dfp_write1_read0( 32'HFFFF_FE00 + i*32 , oRnd.bRndDFPWdata );
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
   //$fsdbDumpfile("dump.fsdb");
   //$fsdbDumpvars(0, "+all");
   //$vcdpluson(0);
end

endmodule

