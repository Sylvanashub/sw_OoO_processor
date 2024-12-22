
module inst_buf_visual (
    input   logic clk
   ,input   logic rst
);

parameter   FILE_NAME = "inst_buffer_ary.js" ;
parameter   INST_ORDER_START  = 2000 ;
parameter   INST_ORDER_END    = 2100 ;

typedef struct {

   logic [31:0]   pc ;
   logic [31:0]   inst ;
   logic          predict ;
   string         ptr ;

} inst_buf_type ;

wire  [63:0]   mon_order = dut.u_ooo.u_rob.mon_order ;

inst_buf_type inst_buf_ary [16] ;

integer iFile ;

function void get_inst_buf_info () ;

   inst_buf_type stcInstBuf ;

   for(int i=0;i<16;i++)
   begin

      {stcInstBuf.predict,stcInstBuf.pc,stcInstBuf.inst} 
      = dut.u_ooo.u_fetch.u_sync_fifo.queue[i] ;
      stcInstBuf.ptr = "" ;
      if( i[3:0] == dut.u_ooo.u_fetch.u_sync_fifo.wptr_r[3:0] )
      begin
         stcInstBuf.ptr = "<" ;
      end
      if( i[3:0] == dut.u_ooo.u_fetch.u_sync_fifo.rptr_r[3:0] )
      begin
         stcInstBuf.ptr = {stcInstBuf.ptr,">"} ;
      end
      

      inst_buf_ary[i] = stcInstBuf ;

   end

endfunction

function void write_inst_buf(input integer iFile );
   
   get_inst_buf_info();

   $fwrite(iFile,"inst_buffer_ary.push([");
   for(int i=0;i<16;i++)
   begin
      $fwrite(iFile,"['0x%08x','0x%08x','%s']",inst_buf_ary[i].pc,inst_buf_ary[i].inst,inst_buf_ary[i].ptr);
      if( i!= 15 )
         $fwrite(iFile,",");
   end
   $fwrite(iFile,"]);\n");

endfunction

initial
begin
   iFile = $fopen(FILE_NAME,"w");
   $fwrite(iFile,"let inst_buffer_ary = [];\n");
end

always@(posedge clk iff !rst)
begin
   if( int'(mon_order) >= INST_ORDER_START && int'(mon_order) < INST_ORDER_END )
   begin
      write_inst_buf(iFile);
   end
   else if( int'(mon_order) > INST_ORDER_END )
   begin
      $finish();
   end
end

final
begin
   $fclose(iFile);
end

endmodule

//bind top_tb inst_buf_visual u_inst_buf_visual (.*);
//bind top_tb dec_visual u_dec_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("alu")) u_alu_rvs_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("mdu")) u_mdu_rvs_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("lsu")) u_lsu_rvs_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("jmp")) u_jmp_rvs_visual (.*);
//bind top_tb rob_visual u_rob_visual (.*);
//bind top_tb gpr_visual u_gpr_visual (.*);

