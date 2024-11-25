
module dec
import rv32i_types::* ;
#(

   parameter   TAG_W    = 32'D4

) (

    input   logic                clk
   ,input   logic                rst

   ,output  logic                dequeue
   ,input   logic [63:0]         dequeue_rdata
   ,input   logic                is_empty

   ,dec2rvs_itf.dec              dec2alu_rvs_itf
   ,dec2rvs_itf.dec              dec2mdu_rvs_itf
   ,dec2rvs_itf.dec              dec2lsu_rvs_itf
   ,dec2rvs_itf.dec              dec2jmp_rvs_itf

//   ,dec2rfu_itf.dec              dec2rfu_itf

   ,dec2rob_itf.dec              dec2rob_itf

   ,dec2rat_itf.dec              dec2rat_itf

);

//------------------------------------------------------------------------------
// Main
//------------------------------------------------------------------------------
logic rvs_rdy ;
logic rvs_req  ;
logic rvs_req_r  ;

//------------------------------------------------------------------------------
// instruction decode
//------------------------------------------------------------------------------
logic [31:0]   pc ;
logic   [31:0]  inst;
logic   [2:0]   funct3;
logic   [6:0]   funct7;
logic   [6:0]   opcode;
logic   [31:0]  i_imm;
//logic   [31:0]  s_imm;
logic   [11:0]  s_imm;
logic   [31:0]  b_imm;
logic   [31:0]  u_imm;
logic   [31:0]  j_imm;
logic   [4:0]   rs1_s;
logic   [4:0]   rs2_s;
logic   [4:0]   rd_s;

assign {pc,inst} = dequeue_rdata ;

assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign opcode = inst[6:0];
assign i_imm  = {{21{inst[31]}}, inst[30:20]};
//assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign s_imm  = {inst[31:25], inst[11:7]};
assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign u_imm  = {inst[31:12], 12'h000};
assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
assign rs1_s  = inst[19:15];
assign rs2_s  = inst[24:20];
assign rd_s   = inst[11:7];

//------------------------------------------------------------------------------
// Regfile interface
//------------------------------------------------------------------------------

//assign dec2rfu_itf.rs1_addr   = rs1_s ;
//assign dec2rfu_itf.rs2_addr   = rs2_s ;
//
//assign dec2rfu_itf.rd_addr    = rd_s ;
//
//assign dec2rfu_itf.rd_tag     =  ({TAG_W{dec2alu_rvs_itf.req}} & dec2alu_rvs_itf.tag) |
//                                 ({TAG_W{dec2mdu_rvs_itf.req}} & dec2mdu_rvs_itf.tag) |
//                                 ({TAG_W{dec2lsu_rvs_itf.req}} & dec2lsu_rvs_itf.tag) ;
wire exu_end = (dec2alu_rvs_itf.req && dec2alu_rvs_itf.rdy) ||
               (dec2mdu_rvs_itf.req && dec2mdu_rvs_itf.rdy) ||
               (dec2lsu_rvs_itf.req && dec2lsu_rvs_itf.rdy) ||
               (dec2jmp_rvs_itf.req && dec2jmp_rvs_itf.rdy) ;
//assign dec2rfu_itf.rd_wr = opcode == op_b_store ? 1'H0 : exu_end ;

//------------------------------------------------------------------------------
// RVS interface
//------------------------------------------------------------------------------

assign rvs_rdy =  dec2alu_rvs_itf.req ? dec2alu_rvs_itf.rdy :
                  dec2mdu_rvs_itf.req ? dec2mdu_rvs_itf.rdy :
                  dec2lsu_rvs_itf.req ? dec2lsu_rvs_itf.rdy : 
                  dec2jmp_rvs_itf.req ? dec2jmp_rvs_itf.rdy : 
                  1'H1 ;

assign dequeue = ~is_empty && rvs_rdy  ;

always@(posedge clk)
begin
   if( rst )
      rvs_req_r <= 1'H0 ;
   else if( rvs_rdy )
      rvs_req_r <= dequeue ;
end
//assign rvs_req = ~dec2rfu_itf.rd_busy & rvs_req_r ;
assign rvs_req = rvs_req_r ;

always_comb
begin

   dec2alu_rvs_itf.req        = '0 ;
   dec2alu_rvs_itf.opc        = '0 ;
   dec2alu_rvs_itf.src1_vld   = '0 ;
   dec2alu_rvs_itf.src1_tag   = '0 ;
   dec2alu_rvs_itf.src1_wdata = '0 ;
   dec2alu_rvs_itf.src2_vld   = '0 ;
   dec2alu_rvs_itf.src2_tag   = '0 ;
   dec2alu_rvs_itf.src2_wdata = '0 ;
   dec2alu_rvs_itf.offset     = '0 ;

   dec2mdu_rvs_itf.req        = '0 ;
   dec2mdu_rvs_itf.opc        = '0 ;
   dec2mdu_rvs_itf.src1_vld   = '0 ;
   dec2mdu_rvs_itf.src1_tag   = '0 ;
   dec2mdu_rvs_itf.src1_wdata = '0 ;
   dec2mdu_rvs_itf.src2_vld   = '0 ;
   dec2mdu_rvs_itf.src2_tag   = '0 ;
   dec2mdu_rvs_itf.src2_wdata = '0 ;
   dec2mdu_rvs_itf.offset     = '0 ;

   dec2lsu_rvs_itf.req        = '0 ;
   dec2lsu_rvs_itf.opc        = '0 ;
   dec2lsu_rvs_itf.src1_vld   = '0 ;
   dec2lsu_rvs_itf.src1_tag   = '0 ;
   dec2lsu_rvs_itf.src1_wdata = '0 ;
   dec2lsu_rvs_itf.src2_vld   = '0 ;
   dec2lsu_rvs_itf.src2_tag   = '0 ;
   dec2lsu_rvs_itf.src2_wdata = '0 ;
   dec2lsu_rvs_itf.offset     = '0 ;

   dec2jmp_rvs_itf.req        = '0 ;
   dec2jmp_rvs_itf.opc        = '0 ;
   dec2jmp_rvs_itf.src1_vld   = '0 ;
   dec2jmp_rvs_itf.src1_tag   = '0 ;
   dec2jmp_rvs_itf.src1_wdata = '0 ;
   dec2jmp_rvs_itf.src2_vld   = '0 ;
   dec2jmp_rvs_itf.src2_tag   = '0 ;
   dec2jmp_rvs_itf.src2_wdata = '0 ;
   dec2jmp_rvs_itf.offset     = '0 ;

   unique case(opcode )
   op_b_lui :
   begin

      dec2alu_rvs_itf.req        = rvs_req      ;
      dec2alu_rvs_itf.opc        = alu_op_add   ;
      dec2alu_rvs_itf.src1_vld   = '1           ;
      dec2alu_rvs_itf.src1_tag   = '0           ;
      dec2alu_rvs_itf.src1_wdata = u_imm        ;
      dec2alu_rvs_itf.src2_vld   = '1           ;
      dec2alu_rvs_itf.src2_tag   = '0           ;
      dec2alu_rvs_itf.src2_wdata = '0           ;

   end
   op_b_auipc :
   begin

      dec2alu_rvs_itf.req        = rvs_req      ;
      dec2alu_rvs_itf.opc        = alu_op_add   ;
      dec2alu_rvs_itf.src1_vld   = '1           ;
      dec2alu_rvs_itf.src1_tag   = '0           ;
      dec2alu_rvs_itf.src1_wdata = u_imm        ;
      dec2alu_rvs_itf.src2_vld   = '1           ;
      dec2alu_rvs_itf.src2_tag   = '0           ;
      dec2alu_rvs_itf.src2_wdata = pc           ;

   end
   op_b_jal:
   begin

      dec2jmp_rvs_itf.req        = rvs_req      ;
      dec2jmp_rvs_itf.opc        = jmp_op_jal   ;
      dec2jmp_rvs_itf.src1_vld   = '1           ;
      dec2jmp_rvs_itf.src1_tag   = '0           ;
      dec2jmp_rvs_itf.src1_wdata = j_imm        ;
      dec2jmp_rvs_itf.src2_vld   = '1           ;
      dec2jmp_rvs_itf.src2_tag   = '0           ;
      dec2jmp_rvs_itf.src2_wdata = pc           ;
      dec2jmp_rvs_itf.offset     = 4            ;

   end
   op_b_jalr:
   begin

      dec2jmp_rvs_itf.req        = rvs_req               ;
      dec2jmp_rvs_itf.opc        = jmp_op_jalr           ;
      dec2jmp_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
      dec2jmp_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
      dec2jmp_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
      dec2jmp_rvs_itf.src2_vld   = '1                    ;
      dec2jmp_rvs_itf.src2_tag   = '0                    ;
      dec2jmp_rvs_itf.src2_wdata = i_imm                 ;
      dec2jmp_rvs_itf.offset     = 4                     ;

   end
   op_b_br:
   begin

      dec2jmp_rvs_itf.req        = rvs_req               ;
      dec2jmp_rvs_itf.opc        = {1'H0,funct3}         ;
      dec2jmp_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
      dec2jmp_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
      dec2jmp_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
      dec2jmp_rvs_itf.src2_vld   = dec2rob_itf.rs2_valid ;
      dec2jmp_rvs_itf.src2_tag   = dec2rob_itf.rs2_tag   ;
      dec2jmp_rvs_itf.src2_wdata = dec2rob_itf.rs2_rdata ;
      dec2jmp_rvs_itf.offset     = b_imm[12:1]           ;

   end
   op_b_load :
   begin
   
      dec2lsu_rvs_itf.req        = rvs_req               ;
      dec2lsu_rvs_itf.opc        = {1'H0,funct3}         ;
      dec2lsu_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
      dec2lsu_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
      dec2lsu_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
      dec2lsu_rvs_itf.src2_vld   = '1                    ;
      dec2lsu_rvs_itf.src2_tag   = '0                    ;
      dec2lsu_rvs_itf.src2_wdata = '0                    ;
      dec2lsu_rvs_itf.offset     = i_imm[11:0]                 ;

   end
   op_b_store :
   begin
   
      dec2lsu_rvs_itf.req        = rvs_req               ;
      dec2lsu_rvs_itf.opc        = {1'H1,funct3}         ;
      dec2lsu_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
      dec2lsu_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
      dec2lsu_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
      dec2lsu_rvs_itf.src2_vld   = dec2rob_itf.rs2_valid ;
      dec2lsu_rvs_itf.src2_tag   = dec2rob_itf.rs2_tag   ;
      dec2lsu_rvs_itf.src2_wdata = dec2rob_itf.rs2_rdata ;
      dec2lsu_rvs_itf.offset     = s_imm[11:0]                 ;

   end
   op_b_imm :
   begin

      dec2alu_rvs_itf.req        = rvs_req               ;
      //dec2alu_rvs_itf.opc        =  ;
      dec2alu_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
      dec2alu_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
      dec2alu_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
      dec2alu_rvs_itf.src2_vld   = '1                    ;
      dec2alu_rvs_itf.src2_tag   = '0                    ;
      dec2alu_rvs_itf.src2_wdata = i_imm                 ;

      unique case ( funct3 )
      arith_f3_sr:
      begin
         if (funct7[5]) begin
            dec2alu_rvs_itf.opc = alu_op_sra;
         end else begin
            dec2alu_rvs_itf.opc = alu_op_srl;
         end
      end
      default:
      begin
         dec2alu_rvs_itf.opc = {1'H0,funct3} ;
      end
      endcase

   end
   op_b_reg :
   begin

      if( funct7 == 7'H01 )
      begin
         dec2mdu_rvs_itf.req        = rvs_req               ;
         dec2mdu_rvs_itf.opc        = funct3                ;
         dec2mdu_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
         dec2mdu_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
         dec2mdu_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
         dec2mdu_rvs_itf.src2_vld   = dec2rob_itf.rs2_valid ;
         dec2mdu_rvs_itf.src2_tag   = dec2rob_itf.rs2_tag   ;
         dec2mdu_rvs_itf.src2_wdata = dec2rob_itf.rs2_rdata ;
      end
      else
      begin
         dec2alu_rvs_itf.req        = rvs_req               ;
         //dec2alu_rvs_itf.opc        = get_op_reg_aluop(funct3,funct7) ;
         dec2alu_rvs_itf.src1_vld   = dec2rob_itf.rs1_valid ;
         dec2alu_rvs_itf.src1_tag   = dec2rob_itf.rs1_tag   ;
         dec2alu_rvs_itf.src1_wdata = dec2rob_itf.rs1_rdata ;
         dec2alu_rvs_itf.src2_vld   = dec2rob_itf.rs2_valid ;
         dec2alu_rvs_itf.src2_tag   = dec2rob_itf.rs2_tag   ;
         dec2alu_rvs_itf.src2_wdata = dec2rob_itf.rs2_rdata ;

         unique case ( funct3 )
         arith_f3_sr:
         begin
            if (funct7[5]) begin
               dec2alu_rvs_itf.opc = alu_op_sra;
            end else begin
               dec2alu_rvs_itf.opc = alu_op_srl;
            end
         end
         arith_f3_add:
         begin
            if (funct7[5]) begin
               dec2alu_rvs_itf.opc = alu_op_sub;
            end else begin
               dec2alu_rvs_itf.opc = alu_op_add;
            end
         end
         default:
         begin
            dec2alu_rvs_itf.opc = {1'H0,funct3} ;
         end
         endcase

      end

   end
   default :
   begin

      dec2alu_rvs_itf.req        = '0 ;
      dec2alu_rvs_itf.opc        = '0 ;
      dec2alu_rvs_itf.src1_vld   = '0 ;
      dec2alu_rvs_itf.src1_tag   = '0 ;
      dec2alu_rvs_itf.src1_wdata = '0 ;
      dec2alu_rvs_itf.src2_vld   = '0 ;
      dec2alu_rvs_itf.src2_tag   = '0 ;
      dec2alu_rvs_itf.src2_wdata = '0 ;

      dec2mdu_rvs_itf.req        = '0 ;
      dec2mdu_rvs_itf.opc        = '0 ;
      dec2mdu_rvs_itf.src1_vld   = '0 ;
      dec2mdu_rvs_itf.src1_tag   = '0 ;
      dec2mdu_rvs_itf.src1_wdata = '0 ;
      dec2mdu_rvs_itf.src2_vld   = '0 ;
      dec2mdu_rvs_itf.src2_tag   = '0 ;
      dec2mdu_rvs_itf.src2_wdata = '0 ;

      dec2lsu_rvs_itf.req        = '0 ;
      dec2lsu_rvs_itf.opc        = '0 ;
      dec2lsu_rvs_itf.src1_vld   = '0 ;
      dec2lsu_rvs_itf.src1_tag   = '0 ;
      dec2lsu_rvs_itf.src1_wdata = '0 ;
      dec2lsu_rvs_itf.src2_vld   = '0 ;
      dec2lsu_rvs_itf.src2_tag   = '0 ;
      dec2lsu_rvs_itf.src2_wdata = '0 ;
      dec2lsu_rvs_itf.offset     = '0 ;

      dec2jmp_rvs_itf.req        = '0 ;
      dec2jmp_rvs_itf.opc        = '0 ;
      dec2jmp_rvs_itf.src1_vld   = '0 ;
      dec2jmp_rvs_itf.src1_tag   = '0 ;
      dec2jmp_rvs_itf.src1_wdata = '0 ;
      dec2jmp_rvs_itf.src2_vld   = '0 ;
      dec2jmp_rvs_itf.src2_tag   = '0 ;
      dec2jmp_rvs_itf.src2_wdata = '0 ;
      dec2jmp_rvs_itf.offset     = '0 ;

   end
   endcase
end

assign dec2alu_rvs_itf.inst_id = dec2rob_itf.inst_id ;
assign dec2mdu_rvs_itf.inst_id = dec2rob_itf.inst_id ;
assign dec2lsu_rvs_itf.inst_id = dec2rob_itf.inst_id ;
assign dec2jmp_rvs_itf.inst_id = dec2rob_itf.inst_id ;

assign dec2rob_itf.issue      = rvs_req && rvs_rdy    ;
assign dec2rob_itf.inst       = inst                  ;
assign dec2rob_itf.pc         = pc                    ;
assign dec2rob_itf.tag        = ({TAG_W{dec2alu_rvs_itf.req}} & dec2alu_rvs_itf.tag) |
                                ({TAG_W{dec2mdu_rvs_itf.req}} & dec2mdu_rvs_itf.tag) |
                                ({TAG_W{dec2lsu_rvs_itf.req}} & dec2lsu_rvs_itf.tag) |
                                ({TAG_W{dec2jmp_rvs_itf.req}} & dec2jmp_rvs_itf.tag) ;

//assign dec2rob_itf.tag        = dec2rfu_itf.rd_tag    ;
//assign dec2rob_itf.rs1_tag    = dec2rfu_itf.rs1_tag   ;
//assign dec2rob_itf.rs2_tag    = dec2rfu_itf.rs2_tag   ;
//assign dec2rob_itf.rs1_rdata  = dec2rfu_itf.rs1_rdata ;
//assign dec2rob_itf.rs2_rdata  = dec2rfu_itf.rs2_rdata ;

//------------------------------------------------------------------------------
// RAT
//------------------------------------------------------------------------------

assign dec2rat_itf.rd_wr   = (opcode == op_b_store|| opcode == op_b_br) ? 1'H0 : exu_end ;
assign dec2rat_itf.rd_addr = rd_s ;
assign dec2rat_itf.rob_id  = dec2rob_itf.inst_id ;
assign dec2rat_itf.rs1_addr= rs1_s ;
assign dec2rat_itf.rs2_addr= rs2_s ;








endmodule
