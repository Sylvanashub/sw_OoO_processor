//module rob_mon
//import rv32i_types::*;
// (
//    input   logic    clk
//   ,input   logic    rst
////   ,rob2mon_itf  rob2mon_itf
//   ,input   logic          mon_valid    
//   ,input   logic [63:0]   mon_order    
//   ,input   logic [31:0]   mon_inst     
//   ,input   logic [4:0]    mon_rs1_addr 
//   ,input   logic [4:0]    mon_rs2_addr 
//   ,input   logic [31:0]   mon_rs1_rdata
//   ,input   logic [31:0]   mon_rs2_rdata
//   ,input   logic [4:0]    mon_rd_addr  
//   ,input   logic [31:0]   mon_rd_wdata 
//   ,input   logic [31:0]   mon_pc_rdata 
//   ,input   logic [31:0]   mon_pc_wdata 
//   ,input   logic [31:0]   mon_mem_addr 
//   ,input   logic [3:0]    mon_mem_rmask
//   ,input   logic [3:0]    mon_mem_wmask
//   ,input   logic [31:0]   mon_mem_rdata
//   ,input   logic [31:0]   mon_mem_wdata
//   
//);
//
//wire _x = 
//|mon_valid     | 
//|mon_order     | 
//|mon_inst      | 
//|mon_rs1_addr  | 
//|mon_rs2_addr  | 
//|mon_rs1_rdata | 
//|mon_rs2_rdata | 
//|mon_rd_addr   | 
//|mon_rd_wdata  | 
//|mon_pc_rdata  | 
//|mon_pc_wdata  | 
//|mon_mem_addr  | 
//|mon_mem_rmask | 
//|mon_mem_wmask | 
//|mon_mem_rdata | 
//|mon_mem_wdata ; 
//
//
//class alu_instr ;

covergroup alu_instr_cg with function sample ( instr_t instr , logic [31:0] rs1 , logic [31:0] rs2 ) ;
 
   coverpoint instr.r_type.opcode {
      bins VALID = { op_b_reg } ;
   }

   rs1_32b : coverpoint rs1 {
      bins MAX = { 32'HFFFF_FFFF } ;
      bins MIN = { 32'H0000_0000 } ;
      bins MID = { [1:32'HFFFF_FFFE] } ;
   }

   rs2_32b : coverpoint rs2 {
      bins MAX = { 32'HFFFF_FFFF } ;
      bins MIN = { 32'H0000_0000 } ;
      bins MID = { [1:32'HFFFF_FFFE] } ;
   }

   //rs2_5b : coverpoint rs2 {
   //   bins MAX = { 32'H0000_001F } ;
   //   bins MIN = { 32'H0000_0000 } ;
   //   bins MID = { [1:32'H0000_001E] } ;
   //}

    coverpoint instr.r_type.funct7 {
      bins ALU0   = { 7'H00 } ;
      bins ALU1   = { 7'H20 } ;
      bins MDU    = { 7'H01 } ;
    }


   operand_is_32b : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7,  rs1_32b , rs2_32b {

      ignore_bins NOT_32B_OP = operand_is_32b with (

         //SLL and SRX operation is excluded
         (instr.r_type.funct3 inside {arith_f3_sll,arith_f3_sr} && instr.r_type.funct7 inside {base,variant}) ||
         
         //ADD/SUB/XOR .. operation 
         (instr.r_type.funct3 inside {arith_f3_add}  && !(instr.r_type.funct7 inside {base,variant})) ||
         (instr.r_type.funct3 inside {arith_f3_slt}  && !(instr.r_type.funct7 inside {base})) ||
         (instr.r_type.funct3 inside {arith_f3_sltu} && !(instr.r_type.funct7 inside {base})) ||
         (instr.r_type.funct3 inside {arith_f3_xor}  && !(instr.r_type.funct7 inside {base})) ||
         (instr.r_type.funct3 inside {arith_f3_or}   && !(instr.r_type.funct7 inside {base})) ||
         (instr.r_type.funct3 inside {arith_f3_and}  && !(instr.r_type.funct7 inside {base})) 

      );


      ignore_bins MUL_DIV_OP = operand_is_32b with (
         instr.r_type.funct7 inside {muldiv}
      );
   }

   operand_is_5b : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7,  rs1_32b , rs2_32b {

      ignore_bins NOT_5B_OP = operand_is_5b with (

         //SLL and SRX operation is excluded
         (!(instr.r_type.funct3 inside {arith_f3_sll,arith_f3_sr}))  ||
         
         //ADD/SUB/XOR .. operation 
         (instr.r_type.funct3 inside {arith_f3_sll}  && !(instr.r_type.funct7 inside {base})) ||
         (instr.r_type.funct3 inside {arith_f3_sr}  && !(instr.r_type.funct7 inside {base,variant})) 

      );


      ignore_bins MUL_DIV_OP = operand_is_5b with (
         instr.r_type.funct7 inside {muldiv}
      );
   }

   mul_div : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7,  rs1_32b , rs2_32b {

      ignore_bins NOT_MUL_DIV_OP = mul_div with (
         !(instr.r_type.funct7 inside {muldiv})
      );

   }

endgroup

//function new () ;
//   alu_instr_cg = new();
//endfunction
//
//function do_sample ( bit [31:0] bInst , bit [31:0] bRs1 , bit [31:0] bRs2 ) ;
//   alu_instr_cg.sample( bInst , bRs1, bRs2 ) ;
//endfunction
//
//endclass
//
//alu_instr oALU = new() ;
//
//always@(posedge clk iff rst == 1'H0 )
//begin
//   if( mon_valid )
//   begin
//      oALU.do_sample( mon_inst , mon_rs1_rdata , mon_rs2_rdata ) ;
//   end
//end
//
//endmodule
//
//bind rvfi_connect rob_mon u_rob_mon (.*) ;
