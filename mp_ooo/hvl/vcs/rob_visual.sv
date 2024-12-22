module rob_visual
import rv32i_types::* ;
 #(

   parameter   INST_ORDER_START  = 2000 ,
   parameter   INST_ORDER_END    = 2100

)  (
    input   logic clk
   ,input   logic rst
);

parameter   FILE_NAME = "rob_ary.js" ;
`define MP dut.u_ooo.u_rob

wire  [63:0]   mon_order = dut.u_ooo.u_rob.mon_order ;

string ptr  [16] ;
//rob.rob_entry_t rob_ary [16] ;
rv32i_opcode eOpCode ;
 
integer iFile ;

function void get_rob_info () ;

   for(int i=0;i<16;i++)
   begin
      //rob_ary[i] = `MP.rob_entries[i] ;
   
      ptr[i] = "" ;
      if( i[3:0] == `MP.wptr[3:0] )
      begin
         ptr[i] = "<" ;
      end
      if( i[3:0] == `MP.rptr[3:0] )
      begin
         ptr[i] = {ptr[i],">"} ;
      end
   end

endfunction

function void write_rob(input integer iFile );
   
   get_rob_info();

   $fwrite(iFile,"rob_ary.push([");
   for(int i=0;i<16;i++)
   begin

      eOpCode  = rv32i_opcode'(`MP.rob_entries[i].inst[6:0]) ;

      $fwrite(iFile,"['0x%08x','0x%08x','%s','%0d','%0d','%0d','%s']",
      `MP.rob_entries[i].pc,
      `MP.rob_entries[i].inst,
      eOpCode.name.substr(5),
      `MP.rob_entries[i].tag,
      `MP.rob_entries[i].valid,
      `MP.rob_entries[i].ready,
      ptr[i]
      
      );

      if( i!= 15 )
         $fwrite(iFile,",");
   end
   $fwrite(iFile,"]);\n");

endfunction

initial
begin
   iFile = $fopen(FILE_NAME,"w");
   $fwrite(iFile,"let rob_ary = [];\n");
end

always@(posedge clk iff !rst)
begin
   if( int'(mon_order) >= INST_ORDER_START && int'(mon_order) < INST_ORDER_END )
   begin
      write_rob(iFile);
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

//bind top_tb rob_visual u_rob_visual (.*);
