module dec_visual
import rv32i_types::* ;
 #(

   parameter   INST_ORDER_START  = 2000 ,
   parameter   INST_ORDER_END    = 2100

)  (
    input   logic clk
   ,input   logic rst
);

parameter   FILE_NAME = "dec_ary.js" ;
`define DEC dut.u_ooo.u_dec

wire  [63:0]   mon_order = dut.u_ooo.u_rob.mon_order ;

wire   [2:0]   funct3  = `DEC.funct3 ;
wire   [6:0]   funct7  = `DEC.funct7 ;
wire   [6:0]   opcode  = `DEC.opcode ;
//wire   [31:0]  imm     = `DEC.imm    ;
wire   [4:0]   rs1_s   = `DEC.rs1_s  ;
wire   [4:0]   rs2_s   = `DEC.rs2_s  ;
wire   [4:0]   rd_s    = `DEC.rd_s   ;
wire  [31:0]   inst     = `DEC.inst ;

rv32i_opcode eOpCode ;

assign eOpCode = rv32i_opcode'(opcode) ;

typedef struct {

   string   strAssembly ;
   string   strBinary   ;
   string   strHex      ;
   string   strFormat   ;
   string   strInst_set ;
   string   strManual   ;
   string   strStatus   ;

} dec_dis_type ;
 
integer iFile ;
dec_dis_type stcDec ;

function get_inst_format( rv32i_opcode eOpCode );

   case( eOpCode )
   op_b_lui  : return "J-Type" ;
   op_b_auipc: return "J-Type" ;
   op_b_jal  : return "J-Type" ;
   op_b_jalr : return "J-Type" ;
   op_b_br   : return "J-Type" ;   
   op_b_load : return "J-Type" ;
   op_b_store: return "J-Type" ;
   op_b_imm  : return "J-Type" ;
   op_b_reg  : return "J-Type" ;
   default   : return "Unknown";
   endcase

endfunction

function void get_dec_info () ;

   
   stcDec.strAssembly = "";
   stcDec.strBinary   = "";//$sformatf("%b",inst);
   stcDec.strHex      = "";//$sformatf("0x%x",inst);
   stcDec.strFormat   = "";
   stcDec.strInst_set = "";
   stcDec.strManual   = "";

   if( `DEC.dec2alu_rsi.req )
   begin
      stcDec.strStatus   = `DEC.dec2alu_rsi.rdy ? "ALU REQ RDY" : "ALU REQ WAIT" ;
   end
   else if( `DEC.dec2mdu_rsi.req )
   begin
      stcDec.strStatus   = `DEC.dec2mdu_rsi.rdy ? "MDU REQ RDY" : "MDU REQ WAIT" ;
   end
   else if( `DEC.dec2lsu_rsi.req )
   begin
      stcDec.strStatus   = `DEC.dec2lsu_rsi.rdy ? "LSU REQ RDY" : "LSU REQ WAIT" ;
   end
   else if( `DEC.dec2jmp_rsi.req )
   begin
      stcDec.strStatus   = `DEC.dec2jmp_rsi.rdy ? "JMP REQ RDY" : "JMP REQ WAIT" ;
   end
   else
   begin
      stcDec.strStatus   = "IDLE" ;
   end



endfunction

function void write_dec(input integer iFile );
   
   get_dec_info();

   $fwrite(iFile,"dec_ary.push(");

   $fwrite(iFile,"['0x%08x','%s']",
   inst,
   stcDec.strStatus
   );

   $fwrite(iFile,");\n");

endfunction

initial
begin
   iFile = $fopen(FILE_NAME,"w");
   $fwrite(iFile,"let dec_ary = [];\n");
end

always@(posedge clk iff !rst)
begin
   if( int'(mon_order) >= INST_ORDER_START && int'(mon_order) < INST_ORDER_END )
   begin
      write_dec(iFile);
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

//bind top_tb dec_visual u_dec_visual (.*);
