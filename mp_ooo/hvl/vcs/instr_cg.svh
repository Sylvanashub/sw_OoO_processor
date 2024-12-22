covergroup instr_cg with function sample(instr_t instr);
    // Easy covergroup to see that we're at least exercising
    // every opcode. Since opcode is an enum, this makes bins
    // for all its members.
    all_opcodes : coverpoint instr.i_type.opcode;


    // Some simple coverpoints on various instruction fields.
    // Recognize that these coverpoints are inherently less useful
    // because they really make sense in the context of the opcode itself.
    all_funct7 : coverpoint funct7_t'(instr.r_type.funct7);

    // TODO: Write the following coverpoints:

    // Check that funct3 takes on all possible values.
    // all_funct3 : coverpoint ... ;
     all_funct3 : coverpoint arith_f3_t'(instr.r_type.funct3) ;

    // Check that the rs1 and rs2 fields across instructions take on
    // all possible values (each register is touched).
   all_regs_rs1 : coverpoint instr.r_type.rs1 ;
   all_regs_rs2 : coverpoint instr.r_type.rs2 ;

     //all_regs_rs1 : cross instr.r_type.opcode, instr.r_type.rs1 {
     // ignore_bins NO_RS1 = all_regs_rs1 with ( instr.r_type.opcode inside {op_b_lui,op_b_auipc,op_b_jal,op_b_jalr} ) ; 
     //}

     //all_regs_rs2 : cross instr.r_type.opcode, instr.r_type.rs2 {
     // ignore_bins NO_RS2 = all_regs_rs2 with ( instr.r_type.opcode inside {op_b_lui,op_b_auipc,op_b_jal,op_b_jalr,op_b_load,op_b_imm} ) ; 
     //}

    // Now, cross coverage takes in the opcode context to correctly
    // figure out the /real/ coverage.
    funct3_cross : cross instr.i_type.opcode, instr.i_type.funct3 {

        // We want to ignore the cases where funct3 isn't relevant.

        // For example, for JAL, funct3 doesn't exist. Put it in an ignore_bins.
        ignore_bins JAL_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_jal);

        // TODO:    What other opcodes does funct3 not exist for? Put those in
        // ignore_bins.
        ignore_bins LUI_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_lui);
        ignore_bins AUIPC_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_b_auipc);


        // Branch instructions use funct3, but only 6 of the 8 possible values
        // are valid. Ignore the other two -- don't add them into the coverage
        // report. In fact, if they're generated, that's an illegal instruction.
        illegal_bins BR_FUNCT3 = funct3_cross with
        (instr.i_type.opcode == op_b_br
        && !(instr.i_type.funct3 inside {branch_f3_beq, branch_f3_bne, branch_f3_blt, branch_f3_bge, branch_f3_bltu, branch_f3_bgeu}));

        // TODO: You'll also have to ignore some funct3 cases in JALR, LOAD, and
        // STORE. Write the illegal_bins/ignore_bins for those cases.
        illegal_bins JALR_FUNCT3 = funct3_cross with 
        (instr.i_type.opcode == op_b_jalr && instr.i_type.funct3 != 3'H0);

         illegal_bins LOAD_FUNCT3 = funct3_cross with 
         (instr.i_type.opcode == op_b_load &&
         !(instr.i_type.funct3 inside {load_f3_lb,load_f3_lh,load_f3_lw,load_f3_lbu,load_f3_lhu})) ;

         illegal_bins STORE_FUNCT3 = funct3_cross with 
         (instr.i_type.opcode == op_b_store &&
         !(instr.i_type.funct3 inside {store_f3_sb, store_f3_sh, store_f3_sw})) ;


    }

    // Coverpoint to make separate bins for funct7.
    coverpoint instr.r_type.funct7 {
        bins range[] = {[0:$]};

        //Add b000_0001 as valid value for funct7
        //ignore_bins not_in_spec = {[1:31], [33:127]};
        ignore_bins not_in_spec = {[2:31], [33:127]};
    }

    // Cross coverage for funct7.
    funct7_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {

        // No opcodes except op_b_reg and op_b_imm use funct7, so ignore the rest.
        ignore_bins OTHER_INSTS = funct7_cross with
        (!(instr.r_type.opcode inside {op_b_reg, op_b_imm}));

        // TODO: Get rid of all the other cases where funct7 isn't necessary, or cannot
        // take on certain values.

         ignore_bins INST_IMM_NOT_SX = funct7_cross with (
         instr.r_type.opcode == op_b_imm &&  !(instr.r_type.funct3 inside {arith_f3_sll,arith_f3_sr}) 
         );

         illegal_bins INST_IMM_SLL = funct7_cross with (
         instr.r_type.opcode == op_b_imm && instr.r_type.funct3 == arith_f3_sll &&  instr.r_type.funct7 != base
         );

         illegal_bins INST_IMM_SRX = funct7_cross with (
         instr.r_type.opcode == op_b_imm && instr.r_type.funct3 == arith_f3_sr &&  !(instr.r_type.funct7 inside {base,variant})
         );

         illegal_bins INST_REG_0 = funct7_cross with (
         //Add mul/div instruction
         //instr.r_type.opcode == op_b_reg && !(instr.r_type.funct3 inside {arith_f3_add,arith_f3_sr})  &&  instr.r_type.funct7 != base
         instr.r_type.opcode == op_b_reg && !(instr.r_type.funct3 inside {arith_f3_add,arith_f3_sr})  &&  !(instr.r_type.funct7 inside {base,muldiv})
         );

    }

    md_inst_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {

      ignore_bins OTHRE_INST = md_inst_cross with (
         !(instr.r_type.opcode inside {op_b_reg}) ||
         (instr.r_type.funct7 != muldiv)
      );

    }

endgroup : instr_cg

//covergroup alu_instr_cg with function sample ( instr_t instr , bit [31:0] rs1 , bit [31:0] rs2 ) ;
// 
//   coverpoint instr.i_type.opcode {
//      bins VALID = { op_b_reg } ;
//   }
//
//   rs1_32b : coverpoint rs1 {
//      bins MAX = { 32'HFFFF_FFFF } ;
//      bins MIN = { 32'H0000_0000 } ;
//      bins MID = { [1:32'HFFFF_FFFE] } ;
//   }
//
//   rs2_32b : coverpoint rs2 {
//      bins MAX = { '1 } ;
//      bins MIN = { '0 } ;
//      bins MID = { [1:32'HFFFF_FFFE] } ;
//   }
//
//   rs2_5b : coverpoint rs2 {
//      bins MAX = { 32'H0000_001F } ;
//      bins MIN = { 32'H0000_0000 } ;
//      bins MID = { [1:32'H0000_001E] } ;
//   }
//
//    coverpoint instr.r_type.funct7 {
//      bins ALU0   = { 7'H00 } ;
//      bins ALU1   = { 7'H20 } ;
//      bins MDU    = { 7'H01 } ;
//    }
//
//
//   operand_is_32b : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7,  rs1_32b , rs2_32b {
//      
//      ignore_bins NOT_32B_OP = operand_is_32b with (
//
//         instr.r_type.funct3 inside {arith_f3_sll,arith_f3_sr} && instr.r_type.funct7 inside {base,variant}
//
//      );
//   }
//
//endgroup


