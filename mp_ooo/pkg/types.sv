package rv32i_types;

    typedef enum logic [6:0] {
        op_b_lui       = 7'b0110111, // load upper immediate (U type)
        op_b_auipc     = 7'b0010111, // add upper immediate PC (U type)
        op_b_jal       = 7'b1101111, // jump and link (J type)
        op_b_jalr      = 7'b1100111, // jump and link register (I type)
        op_b_br        = 7'b1100011, // branch (B type)
        op_b_load      = 7'b0000011, // load (I type)
        op_b_store     = 7'b0100011, // store (S type)
        op_b_imm       = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_b_reg       = 7'b0110011  // arith ops with register operands (R type)
    } rv32i_opcode;

    typedef enum logic [2:0] {
        arith_f3_add   = 3'b000, // check logic 30 for sub if op_reg op
        arith_f3_sll   = 3'b001,
        arith_f3_slt   = 3'b010,
        arith_f3_sltu  = 3'b011,
        arith_f3_xor   = 3'b100,
        arith_f3_sr    = 3'b101, // check logic 30 for logical/arithmetic
        arith_f3_or    = 3'b110,
        arith_f3_and   = 3'b111
    } arith_f3_t;

    typedef enum logic [2:0] {
        load_f3_lb     = 3'b000,
        load_f3_lh     = 3'b001,
        load_f3_lw     = 3'b010,
        load_f3_lbu    = 3'b100,
        load_f3_lhu    = 3'b101
    } load_f3_t;

    typedef enum logic [2:0] {
        store_f3_sb    = 3'b000,
        store_f3_sh    = 3'b001,
        store_f3_sw    = 3'b010
    } store_f3_t;

    typedef enum logic [2:0] {
        branch_f3_beq  = 3'b000,
        branch_f3_bne  = 3'b001,
        branch_f3_blt  = 3'b100,
        branch_f3_bge  = 3'b101,
        branch_f3_bltu = 3'b110,
        branch_f3_bgeu = 3'b111
    } branch_f3_t;

    typedef enum logic [2:0] {
        muldiv_f3_mul   = 3'b000, // check logic 30 for sub if op_reg op
        muldiv_f3_mulh  = 3'b001,
        muldiv_f3_mulhsu= 3'b010,
        muldiv_f3_mulhu = 3'b011,
        muldiv_f3_div   = 3'b100,
        muldiv_f3_divu  = 3'b101, // check logic 30 for logical/arithmetic
        muldiv_f3_rem   = 3'b110,
        muldiv_f3_remu  = 3'b111
    } muldiv_f3_t;

    // You'll need this type to randomly generate variants of certain
    // instructions that have the funct7 field.
    typedef enum logic [6:0] {
        base           = 7'b0000000,
        muldiv          = 7'b0000001,
        variant        = 7'b0100000
    } funct7_t;

    // Various ways RISC-V instruction words can be interpreted.
    // See page 104, Chapter 19 RV32/64G Instruction Set Listings
    // of the RISC-V v2.2 spec.
    typedef union packed {
        logic [31:0] word;

        struct packed {
            logic [11:0] i_imm;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } i_type;

        struct packed {
            logic [6:0]  funct7;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  rd;
            rv32i_opcode opcode;
        } r_type;

        struct packed {
            logic [11:5] imm_s_top;
            logic [4:0]  rs2;
            logic [4:0]  rs1;
            logic [2:0]  funct3;
            logic [4:0]  imm_s_bot;
            rv32i_opcode opcode;
        } s_type;

        // TODO: Write the struct for b-type instructions.
        struct packed {
         // Fill this out to get branches running!
            logic [11:5] imm_b_top ;
            logic [4:0] rs2 ;
            logic [4:0] rs1 ;
            logic [2:0] funct3 ;
            logic [4:0]  imm_b_bot;
            rv32i_opcode opcode;

        } b_type;
        //

        struct packed {
            logic [31:12] imm;
            logic [4:0]   rd;
            rv32i_opcode  opcode;
        } j_type;

    } instr_t;

    // add your types in this file if needed.


   typedef enum logic [3:0] {
      alu_op_add = 4'B0000 ,
      alu_op_sub = 4'B1000 ,
      alu_op_sll = 4'B0001 ,
      alu_op_slt = 4'B0010 ,
      alu_op_sltu= 4'B0011 ,
      alu_op_xor = 4'B0100 ,
      alu_op_srl = 4'B0101 ,
      alu_op_sra = 4'B1101 ,
      alu_op_or  = 4'B0110 ,
      alu_op_and = 4'B0111  

   } alu_op_type ;

   typedef enum logic [2:0] {

      mdu_op_mul     = 3'B000 ,
      mdu_op_mulh    = 3'B001 ,
      mdu_op_mulhsu  = 3'B010 ,
      mdu_op_mulhu   = 3'B011 ,
      mdu_op_div     = 3'B100 ,
      mdu_op_divu    = 3'B101 ,
      mdu_op_rem     = 3'B110 ,
      mdu_op_remu    = 3'B111  

   } mdu_op_type ;

    typedef enum logic [3:0] {

        lsu_op_lb    = 4'b0000,
        lsu_op_lh    = 4'b0001,
        lsu_op_lw    = 4'b0010,
        lsu_op_lbu   = 4'b0100,
        lsu_op_lhu   = 4'b0101,
        lsu_op_sb    = 4'b1000,
        lsu_op_sh    = 4'b1001,
        lsu_op_sw    = 4'b1010

    } lsu_op_type ;

   typedef enum logic [3:0] {
      jmp_op_jal  = 4'B1000,
      jmp_op_jalr = 4'B1001,
      jmp_op_beq  = 4'B0000,
      jmp_op_bne  = 4'B0001,
      jmp_op_blt  = 4'B0100,
      jmp_op_bge  = 4'B0101,
      jmp_op_bltu = 4'B0110,
      jmp_op_bgeu = 4'B0111
   } jmp_op_type ;

endpackage : rv32i_types
