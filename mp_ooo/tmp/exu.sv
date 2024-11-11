module exu
import rv32i_types::*;
(
    input   logic          clk_i
   ,input   logic          rst_i

//   ,input   logic          imem_resp_i

   ,input   logic [31:0]   alu_opa_i
   ,input   logic [31:0]   alu_opb_i
   ,input   logic [3:0]    aluop_i

   ,input   logic [4:0]    rd_addr_i
   ,input   logic          rd_wr_i

   ,output  logic [4:0]    rd_addr_o
   ,output  logic          rd_wr_o
   ,output  logic [31:0]   rd_wdata_o

   ,input   logic [2:0]    funct3_i
   ,output  logic [2:0]    funct3_o
   ,input   logic [31:0]   dmem_wdata_i

   //,input  logic [31:0]    dmem_addr_i
   ,output  logic [31:0]   dmem_addr_o
   ,output  logic [31:0]   dmem_wdata_o
   ,output  logic [3:0]    dmem_wmask_o
   ,output  logic [3:0]    dmem_rmask_o

   ,input   logic          opcode_load_i
   ,input   logic          opcode_store_i
   ,output  logic          opcode_load_o
   ,output  logic          opcode_store_o

   ,input   logic          valid_i
   ,output  logic          valid_o

);
logic [31:0]   aluout ;
logic [31:0]   aluout_r ;
logic signed   [31:0] as;
logic signed   [31:0] bs;
logic unsigned [31:0] au;
logic unsigned [31:0] bu;

assign as =   signed'(alu_opa_i);
assign bs =   signed'(alu_opb_i);
assign au = unsigned'(alu_opa_i);
assign bu = unsigned'(alu_opb_i);

always_comb begin
    unique case (aluop_i)
        alu_op_add  : aluout = au +   bu;
        alu_op_sub  : aluout = au -   bu;
        alu_op_sll  : aluout = au <<  bu[4:0];
        alu_op_slt  : aluout = {{31{1'H0}},as<bs};
        alu_op_sltu : aluout = {{31{1'H0}},au<bu};
        alu_op_xor  : aluout = au ^   bu;
        alu_op_srl  : aluout = au >>  bu[4:0];
        alu_op_sra  : aluout = unsigned'(as >>> bu[4:0]);
        alu_op_or   : aluout = au |   bu;
        alu_op_and  : aluout = au &   bu;
        default     : aluout = 'x;
    endcase
end

always_ff @(posedge clk_i) 
begin
   if (rst_i) 
      funct3_o <= '0 ;
   else
      funct3_o <= funct3_i ;
end

always_ff @(posedge clk_i) 
begin
   if (rst_i) 
      aluout_r <= '0 ;
   else if( valid_i )
      aluout_r <= aluout ;
end

always_ff @(posedge clk_i) 
begin
   if (rst_i) 
   begin
      rd_addr_o   <= 5'H00 ;
      rd_wr_o     <= 1'H0 ;
      //rd_wdata_o  <= {32{1'H0}} ;
   end
   else if( valid_i )
   begin
      rd_addr_o   <= opcode_store_i ? '0 : rd_addr_i;
      rd_wr_o     <= rd_wr_i  ;
      //rd_wdata_o  <= opcode_store_i ? '0 : aluout   ;
   end
   else
   begin
   //   rd_addr_o   <= 5'H00 ;
      rd_wr_o     <= 1'H0 ;
   //   rd_wdata_o  <= {32{1'H0}} ;
   end
end

assign rd_wdata_o = opcode_store_o ? '0 : aluout_r ;

//assign dmem_addr_o   = {aluout_r[31:2],2'H0} ;
assign dmem_addr_o   = aluout_r ;

logic [31:0] dmem_wdata_r ;
always_ff@(posedge clk_i)
begin
   if( rst_i )
      dmem_wdata_r <= '0 ;
   else if( valid_i )
      dmem_wdata_r <= dmem_wdata_i ;
end

always_comb
begin
   dmem_wdata_o = '0 ;
   unique case (funct3_o)
      store_f3_sb: dmem_wdata_o[8 *aluout_r[1:0] +: 8 ] = dmem_wdata_r[7 :0];
      store_f3_sh: dmem_wdata_o[16*aluout_r[1]   +: 16] = dmem_wdata_r[15:0];
      store_f3_sw: dmem_wdata_o = dmem_wdata_r;
      default    : dmem_wdata_o = '0;
   endcase
end

always_comb
begin
   if( opcode_load_o && valid_o)
   begin
   case( funct3_o[1:0] )
   2'H0 : dmem_rmask_o  = 4'H1<<(aluout_r[1:0]) ;
   2'H1 : dmem_rmask_o  = aluout_r[1] ? 4'B1100 : 4'B0011 ;
   2'H2 : dmem_rmask_o  = 4'HF ;
   default:dmem_rmask_o = '0 ;
   endcase
   end
   else
      dmem_rmask_o = '0 ;
end

always_comb
begin
   if( opcode_store_o && valid_o )
   begin
   case( funct3_o[1:0] )
   2'H0 : dmem_wmask_o  = 4'H1<<(aluout_r[1:0]) ;
   2'H1 : dmem_wmask_o  = aluout_r[1] ? 4'B1100 : 4'B0011 ;
   2'H2 : dmem_wmask_o  = 4'HF ;
   default:dmem_wmask_o = '0 ;
   endcase
   end
   else
      dmem_wmask_o = '0 ;
end

always_ff@(posedge clk_i)
begin
   if( rst_i )
      valid_o <= 1'H0 ;
   else
      valid_o <= valid_i  ;
end

always_ff@(posedge clk_i)
begin
   if( rst_i )
   begin
      opcode_load_o  <= 1'H0 ;
      opcode_store_o <= 1'H0 ;
   end
   else if( valid_i )
   begin
      opcode_load_o  <= opcode_load_i  ;
      opcode_store_o <= opcode_store_i ;
   end
end


endmodule
