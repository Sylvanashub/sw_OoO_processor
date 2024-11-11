
module ifu 
import rv32i_types::*;
(

    input   logic          clk_i
   ,input   logic          rst_i

   ,input   logic          pc_update_i
   ,input   logic [31:0]   pc_new_i

   ,output  logic [31:0]   imem_addr_o
   ,output  logic [3:0]    imem_rmask_o
   ,input   logic          imem_resp_i

   ,input   logic          opcode_ls_i
   ,input   logic          dmem_resp_i

   ,output  logic          valid_o

);

localparam  RVCPU_PC_RV = 32'H1ECE_B000 ;

localparam  SM_IDLE  = 3'H0 ;
localparam  SM_NORM  = 3'H1 ;
localparam  SM_IDRSP = 3'H2 ;
localparam  SM_IRSP  = 3'H3 ;
localparam  SM_DRSP  = 3'H4 ;
localparam  SM_WAIT  = 3'H5 ;

logic [2:0]    state_r ;
logic [2:0]    state_nxt ;

logic [31:0]   pc_r     ;
//logic          stall_r  ;

always_ff@(posedge clk_i)
begin
   if( rst_i )
      state_r <= SM_IDLE ;
   else 
      state_r <= state_nxt ;
end

always_comb
begin
   state_nxt = state_r ;
   unique case( state_r )
   SM_IDLE  : state_nxt = SM_NORM ;
   SM_NORM  : 
   begin
      if( opcode_ls_i ) 
      begin
         if( dmem_resp_i )
            state_nxt = SM_IRSP ;
         else
            state_nxt = SM_IDRSP ;
      end
      else if( pc_update_i )
      begin
         if( ~imem_resp_i )
            state_nxt = SM_IRSP ;
      end
   end
   SM_IDRSP : 
   if( dmem_resp_i && ~imem_resp_i ) 
      state_nxt = SM_IRSP ;
   else if( ~dmem_resp_i && imem_resp_i )
      state_nxt = SM_DRSP ;
   else if( dmem_resp_i && imem_resp_i )
      state_nxt = SM_NORM ;
   SM_IRSP : if( imem_resp_i ) state_nxt = SM_NORM ;
   SM_DRSP : if( dmem_resp_i ) state_nxt = SM_NORM ;
   //SM_WAIT : if( imem_resp_i ) state_nxt = SM_NORM ;
   default  : state_nxt = SM_IDLE ;
   endcase
end

wire [31:0] pc_inc = opcode_ls_i ? 32'HFFFF_FFFC : 32'H0000_0004 ;
wire pc_inc_en =  opcode_ls_i ||
                  ((state_r == SM_NORM) && imem_resp_i) ||
                  //((state_r == SM_WAIT) && imem_resp_i) ||
                  (state_r == SM_IDLE) ||
                  ((state_r == SM_DRSP) && dmem_resp_i) ||
                  ((state_r == SM_IRSP) && imem_resp_i) ;
always_ff@(posedge clk_i)
begin
   if( rst_i )
      pc_r <= RVCPU_PC_RV ;
   else if( pc_update_i )
      pc_r <= pc_new_i + (imem_resp_i ? 32'H0000_0004 : 32'H0) ;
   else if( pc_inc_en )
      pc_r <= pc_r + pc_inc ;
end

//always_ff@(posedge clk_i)
//begin
//   if( rst_i )
//      stall_r <= 1'H0 ;
//   else if( opcode_ls_i )
//      stall_r <= 1'H1 ;
//   else if( dmem_resp_i )
//      stall_r <= 1'H0 ;
//end

assign valid_o = (state_r == SM_NORM) && imem_resp_i ;

assign imem_addr_o   = pc_update_i ? pc_new_i : pc_r ;
assign imem_rmask_o  = rst_i ? 4'H0 : 4'HF ;

endmodule : ifu
