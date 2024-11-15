
module alu 
import rv32i_types::*;
//#(
//
////   parameter   TAG_W    = 32'D4  
//
//) 
(

    input   logic    clk
   ,input   logic    rst

   ,rvs2exu_itf.exu  rvs2alu_itf

   ,exu2cdb_itf.exu  alu2cdb_itf

);

logic is_full  ;
logic wr_vld   ;
logic rd_vld   ;

//logic [ROB_PTR_W-1:0]   inst_id_r ;

logic [31:0]   aluout ;
//logic [31:0]   aluout_r ;
logic signed   [31:0] as;
logic signed   [31:0] bs;
logic unsigned [31:0] au;
logic unsigned [31:0] bu;

assign as =   signed'(rvs2alu_itf.src1);
assign bs =   signed'(rvs2alu_itf.src2);
assign au = unsigned'(rvs2alu_itf.src1);
assign bu = unsigned'(rvs2alu_itf.src2);

always_comb begin
    unique case (rvs2alu_itf.opc)
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

//always_ff @(posedge clk) 
//begin
//   if (rst) 
//   begin
//      aluout_r    <= '0 ;
//      inst_id_r   <= '0 ;
//   end
//   else if( rvs2alu_itf.req && rvs2alu_itf.rdy )
//   begin
//      aluout_r    <= aluout ;
//      inst_id_r   <= rvs2alu_itf.inst_id ;
//   end
//end

assign wr_vld = rvs2alu_itf.req && rvs2alu_itf.rdy ;
assign rd_vld = alu2cdb_itf.req && alu2cdb_itf.rdy ;

always_ff@(posedge clk)
begin
   if( rst )
      is_full <= '0 ;
   else if( wr_vld && ~rd_vld )
      is_full <= '1 ;
   else if( rd_vld && ~wr_vld )
      is_full <= '0 ;
end

always_ff@(posedge clk)
begin
   if( rst )
   begin
      alu2cdb_itf.req      <= '0 ;
      alu2cdb_itf.tag      <= '0 ;
      alu2cdb_itf.wdata    <= '0 ;
      alu2cdb_itf.inst_id  <= '0 ;
      //alu2cdb_itf.addr <= '0 ;
   end
   //else if( alu2cdb_itf.rdy )
   //begin
   //   alu2cdb_itf.req  <= rvs2alu_itf.req && rvs2alu_itf.rdy ;
   //   alu2cdb_itf.tag  <= rvs2alu_itf.tag ;
   //end
   else if( wr_vld )
   begin
      alu2cdb_itf.req      <= '1 ;
      alu2cdb_itf.tag      <= rvs2alu_itf.tag ;
      alu2cdb_itf.wdata    <= aluout ;
      alu2cdb_itf.inst_id  <= rvs2alu_itf.inst_id ;
   end
   else if( rd_vld )
   begin
      alu2cdb_itf.req  <= '0 ;
      alu2cdb_itf.tag  <= '0 ;
   end
end

//assign alu2cdb_itf.wdata   = aluout_r ;
//assign alu2cdb_itf.inst_id = inst_id_r ;

assign rvs2alu_itf.rdy = ~is_full || rd_vld ; 

wire x = |rvs2alu_itf.offset ;

endmodule


