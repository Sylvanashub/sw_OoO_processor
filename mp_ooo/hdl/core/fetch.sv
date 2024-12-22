
module fetch 
import rv32i_types::*;
(

    input   logic          clk
   ,input   logic          rst

   ,output  logic   [31:0] ufp_addr
   ,output  logic   [3:0]  ufp_rmask
   ,output  logic   [3:0]  ufp_wmask
   ,input   logic   [31:0] ufp_rdata
   ,output  logic   [31:0] ufp_wdata
   ,input   logic          ufp_resp

   ,input   logic          dequeue
   ,output  logic          is_empty
   ,output  logic   [65:0] dequeue_rdata

   ,input   logic          flush
   ,input   logic [31:0]   pc_new
   ,input   logic [31:0]   pc_org
   ,input   logic          btb_update

   ,ifu2bpu_itf.ifu        ifu2bpu_itf

);

localparam  PC_RESET = 32'H1ECE_B000 ;
localparam DATA_WIDTH   = 64 + 2;
localparam IDLE   = 3'H0 ;
localparam READ   = 3'H1 ;
localparam WAIT   = 3'H2 ;
localparam FLUSH  = 3'H3 ;

localparam  BPU   = 1'H1 ;


logic [31:0]   pc_r ;
logic [31:0]   pc_fifo_r ;
logic [2:0]    state_r ;
logic [2:0]    state_nxt ;

logic          predict_valid ;
logic          predict_taken ;
logic          predict_jmp ;
logic [31:0]   predict_pc  ;

logic                   enqueue ;
logic [DATA_WIDTH-1:0]  wdata   ;
logic [DATA_WIDTH-1:0]  rdata   ;
logic                   is_full ;
//logic                   afull ;
//logic [4:0]             count    ;
logic pc_inc ;
assign predict_jmp = enqueue && predict_valid && predict_taken ;//&& (fifo_inst[6:0] == 7'B1100011);

assign pc_inc = (state_r == IDLE) || enqueue ;
always_ff@(posedge clk)
begin
   if( rst )
      pc_r <= PC_RESET ;
   else if( flush )
      pc_r <= pc_new ;

   else if( predict_jmp )
      pc_r <= predict_pc ;

   else if( pc_inc )
      pc_r <= pc_r + 32'H0000_0004 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      pc_fifo_r <= PC_RESET ;
   else if( pc_inc )
      pc_fifo_r <= pc_r ;
end

always_ff@(posedge clk)
begin
   if( rst )
      state_r <= IDLE ;
   else
      state_r <= state_nxt ;
end

//assign afull = count > 5'H08 ;

always_comb
begin
   state_nxt = state_r ;
   case( state_r )
   IDLE :
   begin
      //flush right after predict_jmp
      if( !flush )
         state_nxt = READ ;
   end
   READ :
   begin
      if( ufp_resp ) 
      begin
         if( flush || predict_jmp )
            state_nxt = IDLE ;
         else if( is_full )
            state_nxt = WAIT ;
      end
      else
      begin
         if( flush || predict_jmp )
            state_nxt = FLUSH ;
      end
   end
   WAIT : 
      if( flush || predict_jmp  )
         state_nxt = IDLE ;
      else if( ~is_full)
         state_nxt = READ ;
   FLUSH :
   begin
      if( ufp_resp )
         state_nxt = IDLE ;
   end
   default : state_nxt = state_r ;
   endcase
end

logic [31:0] ufp_rdata_r ;
always_ff@(posedge clk)
begin
   if( rst )
      ufp_rdata_r <= '0 ;
   else if( is_full && ufp_resp )
      ufp_rdata_r <= ufp_rdata ;
end

wire [31:0] fifo_inst = state_r == WAIT ? ufp_rdata_r : ufp_rdata ;

assign enqueue = ~flush && ((state_r == READ) && ~is_full && ufp_resp || state_r == WAIT && ~is_full) ;
//assign wdata   = {predict_valid , pc_fifo_r, state_r == WAIT ? ufp_rdata_r : ufp_rdata} ;
//assign wdata   = {predict_valid , pc_fifo_r, fifo_inst } ;
assign wdata   = {predict_taken,predict_valid , pc_fifo_r, fifo_inst } ;

sync_fifo #(

    .DATA_WIDTH   (DATA_WIDTH)
   ,.QUEUE_DEPTH  (16)

) u_sync_fifo (

   .* 
   ,.rst ( rst | flush )

);
assign dequeue_rdata = rdata ;

assign ufp_addr  = pc_r ;
//assign ufp_rmask = ~flush && pc_inc ? '1 : '0 ;
assign ufp_rmask = ~(flush|predict_jmp) && pc_inc ? '1 : '0 ;
assign ufp_wmask = '0 ;
assign ufp_wdata = '0 ;


//------------------------------------------------------------------------------
// BTB
//------------------------------------------------------------------------------

generate

if( BPU == 1'H1 )
begin : bpu

   wire [6:0] opcode = fifo_inst[6:0] ;
   //wire is_branch_inst = opcode == op_b_br || opcode == op_b_jal ;

   assign predict_pc    = ifu2bpu_itf.predict_pc      ;
   assign predict_taken = ifu2bpu_itf.predict_taken || opcode == op_b_jal ;
   assign predict_valid = ifu2bpu_itf.predict_valid   ;

   wire nu = |pc_org | btb_update ;

end
else
begin : btb

   btb u_btb (
      .*
      ,.pc           ( pc_org    )
      ,.target       ( pc_new    )
      ,.update       ( btb_update)
   
      ,.fetch_pc     ( pc_fifo_r )
      ,.predict_pc   ( predict_pc      )
      ,.predict_valid( predict_valid   )
   );
   
   assign predict_taken = 1'H1 ;

end

endgenerate

//------------------------------------------------------------------------------
// Branch Predict
//------------------------------------------------------------------------------
assign ifu2bpu_itf.fetch      = |ufp_rmask ;
assign ifu2bpu_itf.fetch_pc   = pc_r ;


//assign ifu2bpu_itf.fetch      = enqueue ;
//assign ifu2bpu_itf.fetch_pc   = pc_fifo_r ;

endmodule
