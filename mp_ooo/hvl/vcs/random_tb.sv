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

        // Run!
        run_random_instrs();

        // Finish up
        end_of_sim();
        //$display("Random testbench finished!");
        //$finish;
    end

endmodule : random_tb
