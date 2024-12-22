module gpr_visual
import rv32i_types::* ;
 #(

   parameter   INST_ORDER_START  = 2000 ,
   parameter   INST_ORDER_END    = 2100

)  (
    input   logic clk
   ,input   logic rst
);

parameter   FILE_NAME = "gpr_ary.js" ;
`define GPR dut.u_ooo.u_gpr
`define RAT dut.u_ooo.u_rat
`define ROB dut.u_ooo.u_rob

wire  [63:0]   mon_order = dut.u_ooo.u_rob.mon_order ;

typedef struct {

   logic [31:0]   rdata ;
   logic          valid ;
   int            tag   ;

} gpr_type ;

integer iFile ;
gpr_type gpr_ary [32] ;
function void get_gpr_info () ;

      gpr_ary[0].rdata = 0 ;
      gpr_ary[0].valid = 1 ;
      gpr_ary[0].tag   = 0 ;

   for(int i=1;i<32;i++)
   begin
      //gpr_ary[i] = `MP.gpr_entries[i] ;
      gpr_ary[i].rdata = `GPR.mem[i] ;
      gpr_ary[i].valid = `RAT.entries[i].valid ;
      gpr_ary[i].tag   = `RAT.entries[i].rob_id;//gpr_ary[i].valid ? 0 : `ROB.rob_entries[`RAT.entries[i].rob_id].tag ;
   end

endfunction

function void write_gpr(input integer iFile );
   
   get_gpr_info();

   $fwrite(iFile,"gpr_ary.push([");
   for(int i=0;i<32;i++)
   begin

      $fwrite(iFile,"['0x%08x','%0d','%0d']",
      gpr_ary[i].rdata,
      gpr_ary[i].valid,
      gpr_ary[i].tag,
      );

      if( i!= 31 )
         $fwrite(iFile,",");
   end
   $fwrite(iFile,"]);\n");

endfunction

initial
begin
   iFile = $fopen(FILE_NAME,"w");
   $fwrite(iFile,"let gpr_ary = [];\n");
end

always@(posedge clk iff !rst)
begin
   if( int'(mon_order) >= INST_ORDER_START && int'(mon_order) < INST_ORDER_END )
   begin
      write_gpr(iFile);
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

//bind top_tb gpr_visual u_gpr_visual (.*);
