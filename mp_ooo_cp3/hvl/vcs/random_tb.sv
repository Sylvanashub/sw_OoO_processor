//-----------------------------------------------------------------------------
// Title                 : random_tb
// Project               : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File                  : random_tb.sv
// Author                : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32i_types::*;
#(
   parameter CHANNELS = 2 
)
(
    mem_itf_banked.mem itf
);

   bit [31:0] bInstAry [8] ;

    `include "../../hvl/vcs/randinst.svh"

    RandInst gen = new();


   task do_dmem_read ( bit [31:0] bAddr , bit [31:0] bInstAry [8] ) ;
      
      itf.ready   <= '0 ;
      itf.rvalid  <= '1;
      itf.raddr   <= bAddr;

      for(int j=0;j<4;j++)
      begin
         itf.rdata[31:0]   <= bInstAry[j*2+0];
         itf.rdata[63:32]  <= bInstAry[j*2+1];
         @(posedge itf.clk) ;
      end
      itf.rvalid <= '0 ;
      itf.ready <= '1 ;

   endtask

   task end_of_sim ();
      @(posedge itf.clk iff itf.read);
      itf.ready <= '0 ;
      itf.rvalid  <= '1;
      itf.raddr   <= '0;
      for(int j=0;j<4;j++)
      begin
         itf.rdata[31:0]   <= 32'HF0002013;
         itf.rdata[63:32]  <= 32'HF0002013;
         @(posedge itf.clk) ;
      end
      itf.rvalid <= '0 ;
      itf.ready <= '1 ;

   endtask

    // Do a bunch of LUIs to get useful register state.
    task init_register_state();
        for (int i = 0; i < 4; ++i) begin
            @(posedge itf.clk iff itf.read);

            // Your code here: package these memory interactions into a task.
            itf.ready <= '0 ;
            itf.rvalid  <= '1;
            itf.raddr   <= '0;
            for(int j=0;j<4;j++)
            begin
               gen.randomize() with {
                   instr.j_type.opcode == op_b_lui;
                   instr.j_type.rd == {i[1:0],j[1:0],1'H0};
               };
               itf.rdata[31:0]   <= gen.instr.word;
               gen.randomize() with {
                   instr.j_type.opcode == op_b_lui;
                   instr.j_type.rd == {i[1:0],j[1:0],1'H1};
               };
               itf.rdata[63:32]   <= gen.instr.word;
               @(posedge itf.clk) ;
            end
            itf.rvalid <= '0 ;
            itf.ready <= '1 ;

            ////insert nop instruction to ensure no data hazard
            //repeat(4)
            //begin
            //@(posedge itf.clk iff |itf.rmask[0]);
            //itf.resp[0] <= 1'b1;
            //itf.rdata[0] <= 32'H00000013 ;
            //@(posedge itf.clk) itf.resp[0] <= 1'b0;
            //end

        end
    endtask : init_register_state


   task set_reg_value () ;

      @(posedge itf.clk iff (itf.read));

      for(int i=0;i<8;i++)
      begin
         bInstAry[i] = 32'H0000_0013 ;
      end

      gen.randomize() with {
          instr.j_type.opcode == op_b_lui;
          instr.j_type.rd == {5'H01};
          instr.j_type.imm == '0 ;
      };
      
      bInstAry[0] = gen.instr.word ;

      gen.randomize() with {
          instr.i_type.opcode == op_b_imm;
          instr.i_type.rs1 == {5'H01};
          instr.i_type.rd == {5'H01};
          instr.i_type.funct3 == arith_f3_add ;
          instr.i_type.i_imm == '1 ;
      };

      bInstAry[1] = gen.instr.word ;

      do_dmem_read( '0, bInstAry ) ;


   endtask

   task run_direct_test ( arith_f3_t funct3 , funct7_t funct7  );

      @(posedge itf.clk iff (itf.read));

      for(int i=0;i<8;i++)
      begin
         bInstAry[i] = 32'H0000_0013 ;
      end

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H00};
          instr.r_type.rs2 == {5'H00};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };
      
      bInstAry[0] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H00};
          instr.r_type.rs2 == {5'H01};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };

      bInstAry[1] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H00};
          instr.r_type.rs2 == {5'H02};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };
      
      bInstAry[2] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H01};
          instr.r_type.rs2 == {5'H00};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };

      bInstAry[3] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H01};
          instr.r_type.rs2 == {5'H01};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };
      
      bInstAry[4] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H01};
          instr.r_type.rs2 == {5'H02};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };

      bInstAry[5] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H02};
          instr.r_type.rs2 == {5'H00};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };
      
      bInstAry[6] = gen.instr.word ;

      gen.randomize() with {
          instr.r_type.opcode == op_b_reg;
          instr.r_type.rs1 == {5'H02};
          instr.r_type.rs2 == {5'H01};
          instr.r_type.rd == {5'H03};
          instr.r_type.funct3 == funct3 ;
          instr.r_type.funct7 == funct7 ;
      };

      bInstAry[7] = gen.instr.word ;

      do_dmem_read( '0, bInstAry ) ;

      @(posedge itf.clk iff (itf.read));

      for(int i=0;i<8;i++)
      begin
         bInstAry[i] = 32'H0000_0013 ;
      end

      do_dmem_read( '0, bInstAry ) ;

   endtask

    // Note that this memory model is not consistent! It ignores
    // writes and always reads out a random, valid instruction.
    task run_random_instrs();
        //repeat (5000) begin
        for(int i=0;i<5000;i++) begin
            @(posedge itf.clk iff (itf.read));

            //random response delay
            repeat($urandom()%4)
            begin
               @(posedge itf.clk);
            end

            // Always read out a valid instruction.
            //if (itf.read) begin
                //FIXME
                //gen.randomize();
               
               for(int j=0;j<8;j++)
               begin
                  gen.randomize() with { instr_type inside {
                   1     //reg-imm
                  ,2     //reg-reg
                  //,4     //store
                  //,(1<<3)//load
                  //,(1<<4)//br
                  //,(1<<5)//jalr
                  //,(1<<6)//jal
                  ,(1<<7)//auipc
                  ,(1<<8)//lui
                  ,(1<<9)//mul/div
                  } ; 
                  } ;
                  bInstAry[j] = gen.instr.word ;
               end

               do_dmem_read( '0, bInstAry ) ;

                //gen.randomize() with { instr_type inside {1,2,4,8,16,32,64,128,256} ; } ;
                ////gen.randomize() with { instr_type inside {1,2,4,8,128,256} ; } ;
                ////gen.randomize() with { instr_type dist {1:=100,2:=100,4:=1,8:=1,128:=10,256:=10} ; } ;
                ////gen.randomize() with { instr_type inside {4} ; } ;
                //if( gen.instr.s_type.opcode == op_b_store ) 
                //begin
                //  gen.instr.s_type.rs1 = '0 ;
                //  //gen.instr.s_type.imm_s_bot[1:0] = '0 ;
                //  case( gen.instr.i_type.funct3[1:0])
                //  2'H1 : gen.instr.s_type.imm_s_bot[0] = '0 ;
                //  2'H2 : gen.instr.s_type.imm_s_bot[1:0] = '0 ;
                //  endcase
                //end
                //if( gen.instr.i_type.opcode == op_b_load ) 
                //begin
                //  gen.instr.i_type.rs1 = '0 ;
                //  //gen.instr.i_type.i_imm[1:0] = '0 ;
                //  case( gen.instr.i_type.funct3[1:0])
                //  2'H1 : gen.instr.i_type.i_imm[0] = '0 ;
                //  2'H2 : gen.instr.i_type.i_imm[1:0] = '0 ;
                //  endcase
                //end

                ////if( i % 5 == 0 )
                //itf.rdata[0] <= gen.instr.word;
                //else
                //itf.rdata[0] <= 32'H0000_0013;
            //end

            // If it's a write, do nothing and just respond.
            //itf.resp[0] <= 1'b1;
         //repeat($urandom()%10)
         //begin
         //   @(posedge itf.clk);
         //end

            //@(posedge itf.clk) itf.resp[0] <= 1'b0;
        end
    endtask : run_random_instrs

    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.read) || $isunknown(itf.write)) begin
            $error("Memory Error: mask containes 1'bx");
            itf.error <= 1'b1;
        end
        if ((|itf.read) && (|itf.write)) begin
            $error("Memory Error: Simultaneous memory read and write");
            itf.error <= 1'b1;
        end
        if ((|itf.read) || (|itf.write)) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: Address contained 'x");
                itf.error <= 1'b1;
            end
            // Only check for 16-bit alignment since instructions are
            // allowed to be at 16-bit boundaries due to JALR.
            if (itf.addr[0] != 1'b0) begin
                $error("Memory Error: Address is not 16-bit aligned");
                itf.error <= 1'b1;
            end
        end
    end

//   always @(posedge itf.clk iff !itf.rst) begin
//      if(|itf.rmask[1] || |itf.wmask[1])
//      begin
//         
//         //repeat($urandom()%10)
//         //begin
//         //   @(posedge itf.clk);
//         //end
//         itf.resp[1] <= 1'b1 ;
//         itf.rdata[1] <= $urandom() ;
//         //@(posedge itf.clk) itf.resp[1] <= 1'b1;
//         //@(posedge itf.clk) itf.resp[1] <= 1'b0;
//         //@(posedge itf.clk);
//         //itf.resp[1] <= 1'b0 ;
//
//      end
//      else
//      begin
//         itf.resp[1] <= 1'b0 ;
//
//      end
//      
//   end


    // A single initial block ensures random stability.
    initial begin
         itf.ready   = '1 ;
         itf.rvalid  = '0 ;
         itf.rdata   = '0 ;
         itf.raddr   = '0 ;
        // Wait for reset.
        @(posedge itf.clk iff itf.rst == 1'b0);

        // Get some useful state into the processor by loading in a bunch of state.
        init_register_state();

      set_reg_value();
      for(int i=0;i<64;i++)
      begin
         run_direct_test( arith_f3_t'(i[2:0]) , base ) ;
         run_direct_test( arith_f3_add , variant ) ;
         run_direct_test( arith_f3_sr , variant ) ;
      end

      for(int i=0;i<64;i++)
      begin
         //run_direct_test( muldiv_f3_t'(i[2:0]) , muldiv ) ;
         run_direct_test( arith_f3_t'(i[2:0]) , muldiv ) ;
      end

        // Run!
        run_random_instrs();

        // Finish up
        end_of_sim();
        //$display("Random testbench finished!");
        //$finish;
    end

endmodule : random_tb


module rob_mon
import rv32i_types::*;
 (
    input   logic    clk
   ,input   logic    rst
   ,rob2mon_itf  rob2mon_itf
);



class alu_instr ;

covergroup alu_instr_cg with function sample ( instr_t instr , bit [31:0] rs1 , bit [31:0] rs2 ) ;
 
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

function new () ;
   alu_instr_cg = new();
endfunction

function do_sample ( bit [31:0] bInst , bit [31:0] bRs1 , bit [31:0] bRs2 ) ;
   alu_instr_cg.sample( bInst , bRs1, bRs2 ) ;
endfunction

endclass

alu_instr oALU = new() ;

always@(posedge clk iff rst == 1'H0 )
begin
   if( rob2mon_itf.valid )
   begin
      oALU.do_sample( rob2mon_itf.inst , rob2mon_itf.rs1_rdata , rob2mon_itf.rs2_rdata ) ;
   end
end

endmodule

//bind rob rob_cov u_rob_cov (.*) ;
