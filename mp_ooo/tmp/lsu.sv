module lsu
import rv32i_types::*;
(
    input   logic          clk_i
   ,input   logic          rst_i

   ,input   logic [1:0]    dmem_addr_i
   ,input   logic          dmem_resp_i
   ,input   logic [31:0]   dmem_rdata_i
   ,output  logic          lsu_dmem_resp_o

   ,input   logic [4:0]    rd_addr_i
   ,input   logic          rd_wr_i
   ,input   logic [31:0]   rd_wdata_i

   ,output  logic [4:0]    rd_addr_o
   ,output  logic          rd_wr_o
   ,output  logic [31:0]   rd_wdata_o

   ,output  logic          lsu2idu_rd_wr_o
   ,output  logic [31:0]   lsu2idu_rd_wdata_o

   ,input   logic [2:0]    funct3_i
   ,input   logic          opcode_load_i
   ,input   logic          opcode_store_i

//   ,output  logic          load_resp_o
   ,input   logic          valid_i
//   ,output  logic          valid_o

   ,output  logic          commit

);

localparam  SM_IDLE  = 3'H0 ;
localparam  SM_NORM  = 3'H1 ;
localparam  SM_LOAD  = 3'H2 ;
localparam  SM_STORE = 3'H3 ;
localparam  SM_RESP  = 3'H4 ;


logic          valid_o ;
logic [4:0]    rd_addr_r   ;
logic [31:0]   rd_wdata_r  ;
logic          rd_wr_r     ;

logic [2:0]    state_r  ;
logic [2:0]    state_nxt;

always_ff@(posedge clk_i)
begin
   if( rst_i )
      state_r <= SM_IDLE ;
   else 
      state_r <= state_nxt ;
end

//wire opc_ls = opcode_load_i || opcode_store_i ;

always_comb
begin
   state_nxt = state_r ;
   unique case( state_r )
   SM_IDLE : 
   begin
      if( valid_i ) 
         state_nxt = opcode_load_i ? SM_LOAD :
                     opcode_store_i? SM_STORE : SM_NORM ;
   end
   SM_NORM : 
   begin
      if( valid_i ) 
         state_nxt = opcode_load_i ? SM_LOAD :
                     opcode_store_i? SM_STORE : SM_NORM ;
      else
         state_nxt = SM_IDLE ;
   end
   SM_LOAD ,
   SM_STORE:
   begin
      if( dmem_resp_i )
         state_nxt = SM_RESP ;
   end
   SM_RESP:
      state_nxt = SM_IDLE ;
   default:
      state_nxt = SM_IDLE ;
   endcase
end

always_ff@(posedge clk_i)
begin
   if( rst_i )
   begin
      rd_addr_r   <= '0 ;
      rd_wdata_r  <= '0 ;
      rd_wr_r     <= '0 ;
   end
   else if (valid_i )
   begin
      //rd_addr_r   <= rd_addr_i   ;
      rd_addr_r   <= rd_wr_i ? rd_addr_i : '0  ;
      rd_wdata_r  <= rd_wdata_i  ;
      rd_wr_r     <= rd_wr_i     ;
   end
   else
   begin
      //rd_addr_r   <= '0 ;
      //rd_wdata_r  <= '0 ;
      rd_wr_r     <= '0 ;
   end
end

logic [31:0] ls_wdata ;
logic [1:0] dmem_addr ;
logic [2:0] funct3_r ;

always_ff@(posedge clk_i)
begin
   if( rst_i )
      dmem_addr <= 2'H0 ;
   else if( valid_i && (opcode_load_i || opcode_store_i) )
      dmem_addr <= dmem_addr_i ;
end

always_ff@(posedge clk_i)
begin
   if( rst_i )
      funct3_r <= 3'H0 ;
   else  if( valid_i && (opcode_load_i || opcode_store_i) )
      funct3_r <= funct3_i;
end


always_comb
begin
   unique case( funct3_r )
      load_f3_lb : ls_wdata = {{24{dmem_rdata_i[7 +8 *dmem_addr[1:0]]}}, dmem_rdata_i[8 *dmem_addr[1:0] +: 8 ]};
      load_f3_lbu: ls_wdata = {{24{1'b0}}                          , dmem_rdata_i[8 *dmem_addr[1:0] +: 8 ]};
      load_f3_lh : ls_wdata = {{16{dmem_rdata_i[15+16*dmem_addr[1]  ]}}, dmem_rdata_i[16*dmem_addr[1]   +: 16]};
      load_f3_lhu: ls_wdata = {{16{1'b0}}                          , dmem_rdata_i[16*dmem_addr[1]   +: 16]};
      load_f3_lw : ls_wdata = dmem_rdata_i;
      default    : ls_wdata = '0;
   endcase
end

//assign rd_addr_o  = rd_wr_o ? rd_addr_r : '0 ;
assign rd_addr_o  = rd_addr_r ;
assign rd_wr_o    = (state_r == SM_LOAD) ? dmem_resp_i : rd_wr_r ;
assign rd_wdata_o = rd_wr_o ? ((state_r == SM_LOAD) ? ls_wdata : rd_wdata_r) : '0 ;

assign lsu2idu_rd_wr_o     = rd_wr_r ;
assign lsu2idu_rd_wdata_o  = rd_wdata_r ;

assign lsu_dmem_resp_o = state_r == SM_RESP ;

assign commit = (state_r == SM_LOAD||state_r == SM_STORE) ? dmem_resp_i : valid_o ;

always_ff@(posedge clk_i)
begin
   if( rst_i )
      valid_o <= 1'H0 ;
   else 
      valid_o <= valid_i ;
end

endmodule : lsu
