module rvs_visual
import rv32i_types::* ;
 #(

   parameter   INST_ORDER_START  = 2000 ,
   parameter   INST_ORDER_END    = 2100 ,
   parameter   RVS_NAME          = "alu"

)  (
    input   logic clk
   ,input   logic rst
);

parameter   FILE_NAME = {RVS_NAME,"_rvs_ary.js"} ;

wire  [63:0]   mon_order = dut.u_ooo.u_rob.mon_order ;

typedef struct {

   logic vld1 ;
   logic vld2 ;
   logic [3:0] tag1 ;
   logic [3:0] tag2 ;
   logic [31:0]   src1 ;
   logic [31:0]   src2 ;
} rvs_type ;

rvs_type rvs_entries [4] ;
   string         ptr[4] ;
 
wire [1:0] wptr ;
wire [1:0] rptr ;
integer iFile ;
//genvar i ;
generate


if( RVS_NAME == "alu" )
begin : alu
   assign wptr = dut.u_ooo.u_alu_rvs.wptr[1:0] ;
   assign rptr = dut.u_ooo.u_alu_rvs.rptr[1:0] ;
   
   always_comb
   begin
      for(int i=0;i<4;i++)
      begin : loop
         rvs_entries[i].vld1 = dut.u_ooo.u_alu_rvs.vld1[i] ;
         rvs_entries[i].vld2 = dut.u_ooo.u_alu_rvs.vld2[i] ;
         rvs_entries[i].tag1 = dut.u_ooo.u_alu_rvs.tag1[i] ;
         rvs_entries[i].tag2 = dut.u_ooo.u_alu_rvs.tag2[i] ;
         rvs_entries[i].src1 = dut.u_ooo.u_alu_rvs.src1[i] ;
         rvs_entries[i].src2 = dut.u_ooo.u_alu_rvs.src2[i] ;
      end
   end

end

if( RVS_NAME == "mdu" )
begin : mdu
   assign wptr = dut.u_ooo.u_mdu_rvs.wptr[1:0] ;
   assign rptr = dut.u_ooo.u_mdu_rvs.rptr[1:0] ;
   
   always_comb
   begin
      for(int i=0;i<4;i++)
      begin : loop
         rvs_entries[i].vld1 = dut.u_ooo.u_mdu_rvs.vld1[i] ;
         rvs_entries[i].vld2 = dut.u_ooo.u_mdu_rvs.vld2[i] ;
         rvs_entries[i].tag1 = dut.u_ooo.u_mdu_rvs.tag1[i] ;
         rvs_entries[i].tag2 = dut.u_ooo.u_mdu_rvs.tag2[i] ;
         rvs_entries[i].src1 = dut.u_ooo.u_mdu_rvs.src1[i] ;
         rvs_entries[i].src2 = dut.u_ooo.u_mdu_rvs.src2[i] ;
      end
   end
end

if( RVS_NAME == "lsu" )
begin : lsu
   assign wptr = dut.u_ooo.u_lsu_rvs.wptr[1:0] ;
   assign rptr = dut.u_ooo.u_lsu_rvs.rptr[1:0] ;
   
   always_comb
   begin
      for(int i=0;i<4;i++)
      begin : loop
         rvs_entries[i].vld1 = dut.u_ooo.u_lsu_rvs.vld1[i] ;
         rvs_entries[i].vld2 = dut.u_ooo.u_lsu_rvs.vld2[i] ;
         rvs_entries[i].tag1 = dut.u_ooo.u_lsu_rvs.tag1[i] ;
         rvs_entries[i].tag2 = dut.u_ooo.u_lsu_rvs.tag2[i] ;
         rvs_entries[i].src1 = dut.u_ooo.u_lsu_rvs.src1[i] ;
         rvs_entries[i].src2 = dut.u_ooo.u_lsu_rvs.src2[i] ;
      end
   end
end

if( RVS_NAME == "jmp" )
begin : jmp
   assign wptr = dut.u_ooo.u_jmp_rvs.wptr[1:0] ;
   assign rptr = dut.u_ooo.u_jmp_rvs.rptr[1:0] ;
   
   always_comb
   begin
      for(int i=0;i<4;i++)
      begin : loop
         rvs_entries[i].vld1 = dut.u_ooo.u_jmp_rvs.vld1[i] ;
         rvs_entries[i].vld2 = dut.u_ooo.u_jmp_rvs.vld2[i] ;
         rvs_entries[i].tag1 = dut.u_ooo.u_jmp_rvs.tag1[i] ;
         rvs_entries[i].tag2 = dut.u_ooo.u_jmp_rvs.tag2[i] ;
         rvs_entries[i].src1 = dut.u_ooo.u_jmp_rvs.src1[i] ;
         rvs_entries[i].src2 = dut.u_ooo.u_jmp_rvs.src2[i] ;
      end
   end
end

endgenerate

function void get_rvs_info () ;

   for(int i=0;i<4;i++)
   begin
      //rvs_ary[i] = `MP.rvs_entries[i] ;
   
      ptr[i] = "" ;
      if( i[1:0] == wptr )
      begin
         ptr[i] = "<" ;
      end
      if( i[1:0] == rptr )
      begin
         ptr[i] = {ptr[i],">"} ;
      end
   end

endfunction

function void write_rvs(input integer iFile );
   
   get_rvs_info();

   $fwrite(iFile,"%s_rvs_ary.push([",RVS_NAME);
   for(int i=0;i<4;i++)
   begin

      $fwrite(iFile,"['%0d','0x%08x','%0d','0x%08x','%s']",
      rvs_entries[i].tag1,
      rvs_entries[i].src1,
      rvs_entries[i].tag2,
      rvs_entries[i].src2,
      ptr[i]
      );

      if( i!= 3 )
         $fwrite(iFile,",");
   end
   $fwrite(iFile,"]);\n");

endfunction

initial
begin
   iFile = $fopen(FILE_NAME,"w");
   $fwrite(iFile,"let %s_rvs_ary = [];\n",RVS_NAME);
end

always@(posedge clk iff !rst)
begin
   if( int'(mon_order) >= INST_ORDER_START && int'(mon_order) < INST_ORDER_END )
   begin
      write_rvs(iFile);
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

//bind top_tb rvs_visual #(.RVS_NAME("alu")) u_alu_rvs_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("mdu")) u_mdu_rvs_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("lsu")) u_lsu_rvs_visual (.*);
//bind top_tb rvs_visual #(.RVS_NAME("jmp")) u_jmp_rvs_visual (.*);
