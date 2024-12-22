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
      //$display("@%t [INF] Waiting for dmem read...",$time);
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
      $display("@%t [INF] Waiting for end_of_sim ...",$time);
   while(1)
   begin
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
   end
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

   task run_direct_jalr_instrs ();

      @(posedge itf.clk iff (itf.read));

      for(int i=0;i<8;i++)
      begin
         bInstAry[i] = 32'H0000_0013 ;
      end

      gen.randomize() with {
          instr.j_type.opcode == op_b_lui    ;
          instr.j_type.rd     == 5'H1        ;
          //instr.j_type.imm    == 20'H12345   ;
      };
      bInstAry[0] = gen.instr.word ;

      gen.randomize() with {
          instr.i_type.opcode == op_b_imm    ;
          instr.i_type.rs1    == 5'H1        ;
          instr.i_type.funct3 == arith_f3_add;
          instr.i_type.rd     == 5'H1        ;
          //instr.i_type.i_imm  == 12'H1234    ;
          instr.i_type.i_imm[11]  == 1'H0    ;
          instr.i_type.i_imm[1:0]  == 2'H0    ;
      };
      bInstAry[1] = gen.instr.word ;

      gen.randomize() with {
          instr.i_type.opcode == op_b_jalr   ;
          instr.i_type.rs1    == 5'H1        ;
          instr.i_type.funct3 == '0          ;
          instr.i_type.i_imm[1:0]  == 2'H0    ;
      };
      bInstAry[2] = gen.instr.word ;

      do_dmem_read( '0, bInstAry ) ;
   endtask


   task run_direct_mem_instrs ();

      @(posedge itf.clk iff (itf.read));

      for(int i=0;i<8;i++)
      begin
         bInstAry[i] = 32'H0000_0013 ;
      end

      gen.randomize() with {
          instr.j_type.opcode == op_b_lui    ;
          instr.j_type.rd     == 5'H1        ;
          //instr.j_type.imm    == 20'H12345   ;
      };
      bInstAry[0] = gen.instr.word ;

      gen.randomize() with {
          instr.i_type.opcode == op_b_imm    ;
          instr.i_type.rs1    == 5'H1        ;
          instr.i_type.funct3 == arith_f3_add;
          instr.i_type.rd     == 5'H1        ;
          //instr.i_type.i_imm  == 12'H1234    ;
          instr.i_type.i_imm[1:0]  == 2'H0    ;
      };
      bInstAry[1] = gen.instr.word ;

      gen.randomize() with {
          instr.i_type.opcode == op_b_load   ;
          instr.i_type.rs1    == 5'H1        ;
          instr.i_type.funct3 inside {load_f3_lb,load_f3_lh,load_f3_lw,load_f3_lbu,load_f3_lhu} ;
          instr.i_type.rd     != 5'H1        ;
          //instr.i_type.i_imm  == 12'H1234    ;
          instr.i_type.i_imm[1:0]  == 2'H0    ;
      };
      bInstAry[2] = gen.instr.word ;

      gen.randomize() with {
          instr.s_type.opcode == op_b_store   ;
          instr.s_type.rs1    == 5'H1        ;
          instr.s_type.funct3 inside {store_f3_sb,store_f3_sh,store_f3_sw} ;
          instr.s_type.imm_s_bot[1:0]  == 2'H0    ;
      };
      bInstAry[3] = gen.instr.word ;

      do_dmem_read( '0, bInstAry ) ;

   endtask

    // Note that this memory model is not consistent! It ignores
    // writes and always reads out a random, valid instruction.
    task run_random_instrs();

         $display("Start random instruction testing!");
        //repeat (5000) begin
        for(int i=0;i<6000;i++) begin
            //$display("@%t [INF] Waiting for dmem_read...",$time);

            @(posedge itf.clk iff (itf.read));

            //random response delay
            repeat($urandom()%4)
            begin
               @(posedge itf.clk);
            end
            //$display("@%t [INF] generate instruction ...",$time);

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
                  ,(1<<4)//br
                  //,(1<<5)//jalr
                  ,(1<<6)//jal
                  ,(1<<7)//auipc
                  ,(1<<8)//lui
                  ,(1<<9)//mul/div
                  } ; 
                  } ;

                  if( gen.instr.j_type.opcode == op_b_jal )
                  begin
                     gen.instr.j_type.imm[31] = 1'H0 ;
                  end

                  if( gen.instr.b_type.opcode == op_b_br )
                  begin
                     gen.instr.b_type.imm_b_top[11] = 1'H0 ;
                     gen.instr.b_type.imm_b_top[10] = 1'H1 ;
                  end

                  bInstAry[j] = gen.instr.word ;
               end
            //$display("@%t [INF] dmem_rvalid assert ...",$time);
               do_dmem_read( '0, bInstAry ) ;
            //$display("@%t [INF] dmem_rvalid deassert...",$time);

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

      for(int i=0;i<64;i++)
      begin
         run_direct_mem_instrs();
      end

      for(int i=0;i<64;i++)
      begin
         run_direct_jalr_instrs();
      end
        // Run!
        run_random_instrs();

        // Finish up
        end_of_sim();
        //$display("Random testbench finished!");
        //$finish;
    end

endmodule : random_tb


