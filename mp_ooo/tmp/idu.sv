`ifndef DATA_HAZARD
`define DATA_HAZARD
`endif

module idu 
import rv32i_types::*;
(
    input   logic          clk_i
   ,input   logic          rst_i

   ,input   logic [31:0]   imem_addr_i
   ,input   logic [31:0]   imem_rdata_i
   ,input   logic          imem_resp_i
   ,input   logic          dmem_resp_i
   
   ,output  logic [31:0]   alu_opa_o
   ,output  logic [31:0]   alu_opb_o
   ,output  logic [3:0]    aluop_o

   ,output  logic [4:0]    rs1_addr_o
   ,output  logic [4:0]    rs2_addr_o
   ,input   logic [31:0]   rs1_rdat_i
   ,input   logic [31:0]   rs2_rdat_i
   
   ,output  logic [4:0]    rd_addr_o
   ,output  logic          rd_wr_o

   ,output  logic [2:0]    funct3_o
   //,output  logic [31:0]   dmem_addr_o
   ,output  logic [31:0]   dmem_wdata_o

   `ifdef DATA_HAZARD
   ,input   logic          exu_rd_wr_i
   ,input   logic [4:0]    exu_rd_addr_i
   ,input   logic [31:0]   exu_rd_wdata_i

   ,input   logic          lsu_rd_wr_i
   ,input   logic [4:0]    lsu_rd_addr_i
   ,input   logic [31:0]   lsu_rd_wdata_i
   `endif

   ,output  logic          opcode_load_o
   ,output  logic          opcode_store_o

//   ,input   logic          load_resp_i
   ,input   logic          valid_i
   ,output  logic          valid_o

   ,output  logic [31:0]   rs1_rdata_o
   ,output  logic [31:0]   rs2_rdata_o
   ,output  logic [31:0]   inst_o

   ,output  logic          pc_update_o
   ,output  logic [31:0]   pc_new_o
   ,output  logic [31:0]   pc_o

);

logic   [31:0]  inst;
logic   [2:0]   funct3;
logic   [6:0]   funct7;
logic   [6:0]   opcode;
logic   [31:0]  i_imm;
logic   [31:0]  s_imm;
logic   [31:0]  b_imm;
logic   [31:0]  u_imm;
logic   [31:0]  j_imm;
logic   [4:0]   rs1_s;
logic   [4:0]   rs2_s;
logic   [4:0]   rd_s;

logic [31:0]   pc_r ;

assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign opcode = inst[6:0];
assign i_imm  = {{21{inst[31]}}, inst[30:20]};
assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
assign u_imm  = {inst[31:12], 12'h000};
assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
assign rs1_s  = inst[19:15];
assign rs2_s  = inst[24:20];
assign rd_s   = inst[11:7];

assign funct3_o = funct3 ;
logic [31:0]   rs1_rdata   ;
logic [31:0]   rs2_rdata   ;

always_ff @(posedge clk_i ) begin
    if (rst_i) begin
        inst <= '0;
    end 
    else if ( dmem_resp_i && ~imem_resp_i )
    begin
      inst <= '0 ;
    end
    else if ( valid_i ) begin
        inst <= imem_rdata_i;
    end
end

always_ff @(posedge clk_i ) begin
    if (rst_i) begin
        pc_r <= '0;
    end else if ( valid_i ) begin
        pc_r <= imem_addr_i ;
    end
end
assign pc_o = pc_r ;
assign rd_addr_o = rd_s ;
assign rs1_addr_o = rs1_s ;
assign rs2_addr_o = rs2_s ;

//assign dmem_addr_o = rs1_rdata + (opcode == op_b_load ? i_imm : s_imm ) ;




//------------------------------------------------------------------------------
// BRANCH
//------------------------------------------------------------------------------

logic           br_en;
logic signed   [31:0] as;
logic signed   [31:0] bs;
logic unsigned [31:0] au;
logic unsigned [31:0] bu;

assign as =   signed'(alu_opa_o);
assign bs =   signed'(alu_opb_o);
assign au = unsigned'(alu_opa_o);
assign bu = unsigned'(alu_opb_o);

always_comb begin
   br_en = 1'H0 ;
   if( opcode == op_b_br )
   begin
    unique case (funct3)
        branch_f3_beq : br_en = (au == bu);
        branch_f3_bne : br_en = (au != bu);
        branch_f3_blt : br_en = (as <  bs);
        branch_f3_bge : br_en = (as >=  bs);
        branch_f3_bltu: br_en = (au <  bu);
        branch_f3_bgeu: br_en = (au >=  bu);
        default       : br_en = 1'b0;
    endcase
   end
end


assign pc_update_o = valid_o && ((opcode == op_b_jal) || (opcode == op_b_jalr) || (opcode == op_b_br) && br_en) ;
wire [31:0] pc_jal  = pc_r + j_imm ;
wire [31:0] pc_jalr = rs1_rdata + i_imm ;
wire [31:0] pc_br   = pc_r + b_imm ;

always_comb
begin
   unique case( opcode )
   op_b_jal : pc_new_o = pc_jal ;
   op_b_jalr: pc_new_o = {pc_jalr[31:1],1'H0} ;
   op_b_br  : pc_new_o = pc_br  ;
   default  : pc_new_o = 'x ;
   endcase
end

//------------------------------------------------------------------------------
//data hazard
//------------------------------------------------------------------------------


`ifdef DATA_HAZARD
assign rs1_rdata =   rs1_s == '0                             ? '0             :
                     exu_rd_wr_i && (rs1_s == exu_rd_addr_i) ? exu_rd_wdata_i :
                     lsu_rd_wr_i && (rs1_s == lsu_rd_addr_i) ? lsu_rd_wdata_i : 
                                                               rs1_rdat_i     ;

assign rs2_rdata =   rs2_s == '0                             ? '0             :
                     exu_rd_wr_i && (rs2_s == exu_rd_addr_i) ? exu_rd_wdata_i :
                     lsu_rd_wr_i && (rs2_s == lsu_rd_addr_i) ? lsu_rd_wdata_i : 
                                                               rs2_rdat_i     ;
`else
assign rs1_rdata = rs1_rdat_i ;
assign rs2_rdata = rs2_rdat_i ;
`endif

assign rs1_rdata_o = rs1_rdata ;
assign rs2_rdata_o = rs2_rdata ;
assign inst_o      = inst ;

always_comb
begin
   alu_opa_o = rs1_rdata ;
   alu_opb_o = rs2_rdata ;
   aluop_o   = '0 ;
   rd_wr_o  = 1'H0 ;
   dmem_wdata_o = '0 ;
   unique case( opcode )
   op_b_lui :
   begin
      aluop_o     = alu_op_add ;
      alu_opa_o   = u_imm ;
      alu_opb_o   = '0 ;
      rd_wr_o  = 1'H1 ;
   end
   op_b_auipc :
   begin
      aluop_o     = alu_op_add ;
      alu_opa_o   = u_imm ;
      alu_opb_o   = pc_r ;
      rd_wr_o     = 1'H1 ;
   end
   op_b_jal ,
   op_b_jalr:
   begin
      aluop_o     = alu_op_add ;
      alu_opa_o   = 32'H0000_0004;
      alu_opb_o   = pc_r ;
      rd_wr_o     = 1'H1 ;
   end
   op_b_load :
   begin
      aluop_o     = alu_op_add ;
      rd_wr_o     = 1'H1 ;
      alu_opa_o   = rs1_rdata ;
      alu_opb_o   = i_imm ;
   end
   op_b_store :
   begin
      dmem_wdata_o = rs2_rdata ;
      aluop_o     = alu_op_add ;
      alu_opa_o   = rs1_rdata ;
      alu_opb_o   = s_imm ;
   end
   op_b_imm :
   begin
      alu_opb_o = i_imm ; 
      rd_wr_o  = 1'H1 ;
      unique case ( funct3 )
      arith_f3_sr:
      begin
         if (funct7[5]) begin
            aluop_o = alu_op_sra;
         end else begin
            aluop_o = alu_op_srl;
         end
      end
      default:
      begin
         aluop_o = {1'H0,funct3} ;
      end
      endcase
   end
   op_b_reg :
   begin
      rd_wr_o  = 1'H1 ;
      unique case ( funct3 )
      arith_f3_sr:
      begin
         if (funct7[5]) begin
            aluop_o = alu_op_sra;
         end else begin
            aluop_o = alu_op_srl;
         end
      end
      arith_f3_add:
      begin
         if (funct7[5]) begin
            aluop_o = alu_op_sub;
         end else begin
            aluop_o = alu_op_add;
         end
      end
      default:
      begin
         aluop_o = {1'H0,funct3} ;
      end
      endcase
   end
   default:
   begin
      alu_opa_o = rs1_rdata ;
      alu_opb_o = rs2_rdata ;
      aluop_o   = '0 ;
      rd_wr_o  = 1'H0 ;
      dmem_wdata_o = '0 ;
   end
   endcase
end

assign opcode_load_o    = valid_o && (opcode == op_b_load );
assign opcode_store_o   = valid_o && (opcode == op_b_store);

always_ff@(posedge clk_i)
begin
   if( rst_i )
      valid_o <= 1'H0 ;
   else if( opcode_load_o || opcode_store_o || pc_update_o )
      valid_o <= 1'H0 ;
   else
      valid_o <= valid_i  ;
end

endmodule : idu
