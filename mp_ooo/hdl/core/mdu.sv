
module mdu
import rv32i_types::*;
#(

   parameter   TAG_W    = 32'D4  

) (

    input   logic    clk
   ,input   logic    rst

   ,rvs2exu_itf.exu  rvs2mdu_itf
   ,exu2cdb_itf.exu  mdu2cdb_itf

);

localparam  IDLE  = 3'H0 ;
localparam  MUL   = 3'H1 ;
localparam  DIV   = 3'H2 ;
localparam  DONE  = 3'H3 ;
localparam  WAIT  = 3'H4 ;


logic [2:0] state_r ;
logic [2:0] state_nxt ;

logic [32:0] a;
logic [32:0] b;
logic [32:0] a_r;
logic [32:0] b_r;
logic [32:0] div_a;
logic [32:0] div_b;
logic signed [63:0]  mul_res ;
logic signed [63:0]  mul_res_r ;
logic [2:0] opc_r ;
logic is_mul_opc ;
logic is_div_opc ;
logic rvs2mdu_itf_rdy ;

logic div_start ;
logic div_complete   ;
logic div_divide_by_0   ;
logic [32:0] div_quotient ;
logic [32:0] div_remainder ;

logic wr_vld ;

assign wr_vld = rvs2mdu_itf.rdy && rvs2mdu_itf.req ;

assign is_div_opc = ~is_mul_opc ;

assign div_start = wr_vld & is_div_opc ;

assign div_a = state_r == DIV ? a_r : a ;
assign div_b = state_r == DIV ? b_r : b ;

DW_div_seq 
#(
    .a_width     ( 33   )
   ,.b_width     ( 33   )
   ,.tc_mode     ( 1    )
   ,.num_cyc     ( 3    )
   ,.rst_mode    ( 1    )
   ,.input_mode  ( 0    )
   ,.output_mode ( 1    )
   ,.early_start ( 0    )
) u_div (
    .clk          (clk              )
   ,.rst_n        (~rst             )
   ,.hold         ( 1'H0            )
   ,.start        (div_start        )
   ,.a            (div_a            )
   ,.b            (div_b            )
   ,.complete     (div_complete     )
   ,.divide_by_0  (div_divide_by_0  )
   ,.quotient     (div_quotient     )
   ,.remainder    (div_remainder    ) 
);

always_comb
begin
   case( rvs2mdu_itf.opc )
   mdu_op_mul  ,
   mdu_op_mulh ,
   mdu_op_div  ,
   mdu_op_rem  :
   begin
      a = signed'(rvs2mdu_itf.src1);
      b = signed'(rvs2mdu_itf.src2);
   end
   mdu_op_mulhsu:
   begin
      a = signed'(rvs2mdu_itf.src1);
      b = unsigned'(rvs2mdu_itf.src2);
   end
   //mdu_op_mulhu :
   default :
   begin
      a = unsigned'(rvs2mdu_itf.src1);
      b = unsigned'(rvs2mdu_itf.src2);
   end   
   endcase
end

assign mul_res = signed'(a) * signed'(b) ;
always_ff@(posedge clk)
begin
   if( rst )
   begin
      a_r <= '0 ;
      b_r <= '0 ;
   end
   else if( rvs2mdu_itf.req && rvs2mdu_itf.rdy )
   begin
      a_r <= a;
      b_r <= b ;
   end
end

always_ff@(posedge clk)
begin
   if( rst )
      mul_res_r <= '0 ;
   else if( rvs2mdu_itf.req && rvs2mdu_itf.rdy)
      mul_res_r <= mul_res ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rvs2mdu_itf_rdy <= '1 ;
   else if( rvs2mdu_itf_rdy && rvs2mdu_itf.req)
      rvs2mdu_itf_rdy <= '0 ;
   else
      rvs2mdu_itf_rdy <= '1 ;
end

//assign rvs2mdu_itf.rdy = rvs2mdu_itf_rdy ;
assign rvs2mdu_itf.rdy = (state_r == IDLE) || (((state_r == DONE) || (state_r==WAIT)) && mdu2cdb_itf.rdy) ;

always_ff@(posedge clk)
begin
   if( rst )
      state_r <= IDLE ;
   else
      state_r <= state_nxt ;
end


assign is_mul_opc =  rvs2mdu_itf.opc == mdu_op_mul    ||
                     rvs2mdu_itf.opc == mdu_op_mulh   ||
                     rvs2mdu_itf.opc == mdu_op_mulhsu ||
                     rvs2mdu_itf.opc == mdu_op_mulhu  ;

always_comb
begin
   state_nxt = state_r ;
   unique case( state_r )
   IDLE : 
   begin
      if( rvs2mdu_itf.req && rvs2mdu_itf.rdy )
         state_nxt = is_mul_opc ? MUL : DIV ;
   end
   MUL :
   begin
      state_nxt = DONE ;
   end
   DIV :
   begin
      if( div_complete )
         state_nxt = DONE ;
   end
   DONE :
   begin
      if( mdu2cdb_itf.rdy )
      begin
         if( rvs2mdu_itf.req )
            state_nxt = is_mul_opc ? MUL : DIV ;
         else
            state_nxt = IDLE ;
      end
   end
   WAIT :
   begin
      if( mdu2cdb_itf.rdy )
      begin
         if( rvs2mdu_itf.req )
            state_nxt = is_mul_opc ? MUL : DIV ;
         else
            state_nxt = IDLE ;
      end
   end
   default :
   begin
      state_nxt = state_r ;
   end
   endcase
end

always_ff@(posedge clk)
begin
   if( rst )
   begin
      mdu2cdb_itf.tag  <= '0 ;
   end
   else if( rvs2mdu_itf.req && rvs2mdu_itf.rdy )
   begin
      mdu2cdb_itf.tag  <= rvs2mdu_itf.tag ;
   end
end
assign mdu2cdb_itf.req   = state_r == DONE ;

//assign mdu2cdb_itf.wdata = mul_res_r[31:0] ;


always_ff@(posedge clk)
begin
   if( rst )
      opc_r <= '0 ;
   else if( rvs2mdu_itf.req && rvs2mdu_itf.rdy )
      opc_r <= rvs2mdu_itf.opc ;
end

always_comb
begin
   unique case( opc_r )
   mdu_op_mul : mdu2cdb_itf.wdata = mul_res_r[31:0] ;
   mdu_op_mulh ,
   mdu_op_mulhsu,
   mdu_op_mulhu: mdu2cdb_itf.wdata = mul_res_r[63:32] ;
   mdu_op_div  ,
   mdu_op_divu : mdu2cdb_itf.wdata = div_quotient[31:0] ;
   mdu_op_rem  ,
   mdu_op_remu : mdu2cdb_itf.wdata = div_remainder[31:0] ;
   default     : mdu2cdb_itf.wdata = '0 ;
   endcase
end

endmodule


