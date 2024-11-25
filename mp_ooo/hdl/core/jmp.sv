
module jmp
import rv32i_types::*;
#(

    parameter  TAG_W       = 32'D4  

   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  ROB_PTR_W   = $clog2(ROB_DEPTH)

   ,parameter  DEPTH       = 32'D4
   ,parameter  PTR_W       = $clog2(DEPTH)

) 
(

    input   logic          clk
   ,input   logic          rst

   ,rvs2exu_itf.exu        rvs2jmp_itf
   ,exu2cdb_itf.exu        jmp2cdb_itf

   ,rob2jmp_itf.jmp        rob2jmp_itf

   ,output  logic          flush
   ,output  logic [31:0]   pc_new

);

typedef struct {

   logic                   valid    ;
   logic [ROB_PTR_W-1:0]   rob_id   ;
   logic [31:0]            pc       ;
   logic                   is_jmp   ;

} entry_type ;

entry_type jmp_entries [DEPTH] ;

logic [PTR_W:0]   wptr     ;
logic [PTR_W:0]   rptr     ;

logic is_full  ;
logic fifo_full;
logic fifo_empty  ;
logic wr_vld   ;
logic rd_vld   ;
logic rd_wr ;
logic br_en;

logic signed   [31:0] as;
logic signed   [31:0] bs;
logic unsigned [31:0] au;
logic unsigned [31:0] bu;

assign as =   signed'(rvs2jmp_itf.src1);
assign bs =   signed'(rvs2jmp_itf.src2);
assign au = unsigned'(rvs2jmp_itf.src1);
assign bu = unsigned'(rvs2jmp_itf.src2);

always_comb begin
   unique case (rvs2jmp_itf.opc)
      jmp_op_beq  : br_en = (au == bu);
      jmp_op_bne  : br_en = (au != bu);
      jmp_op_blt  : br_en = (as <  bs);
      jmp_op_bge  : br_en = (as >=  bs);
      jmp_op_bltu : br_en = (au <  bu);
      jmp_op_bgeu : br_en = (au >=  bu);
      default     : br_en = 1'b1;
   endcase
end

assign wr_vld = rvs2jmp_itf.req && rvs2jmp_itf.rdy ;
assign rd_vld = jmp2cdb_itf.req && jmp2cdb_itf.rdy ;
logic jmp_commit ;
assign jmp_commit =  jmp_entries[rptr[PTR_W-1:0]].valid && 
                     rob2jmp_itf.rob_id == jmp_entries[rptr[PTR_W-1:0]].rob_id &&
                     rob2jmp_itf.ready
                     ;

wire [31:0] pc_tmp = au + bu ;
logic [31:0] pc_nxt ;

always_comb
begin
   unique case( rvs2jmp_itf.opc )
      jmp_op_jal  : pc_nxt = pc_tmp ;
      jmp_op_jalr : pc_nxt = {pc_tmp[31:1],1'H0} ;
      default     : pc_nxt = rob2jmp_itf.pc + {{19{rvs2jmp_itf.offset[11]}},rvs2jmp_itf.offset,1'H0} ;
   endcase
end


genvar i ;
generate
for(i=0;i<DEPTH;i++)
begin : item
   always_ff@(posedge clk)
   begin
      if( rst )
      begin
         jmp_entries[i].valid    <= '0 ;
         jmp_entries[i].rob_id   <= '0 ;
         jmp_entries[i].pc       <= '0 ;
         jmp_entries[i].is_jmp   <= '0 ;
      end
      else if( wr_vld && wptr[PTR_W-1:0] == i[PTR_W-1:0] )
      begin
         jmp_entries[i].valid    <= '1 ;
         jmp_entries[i].rob_id   <= rvs2jmp_itf.inst_id ;
         jmp_entries[i].pc       <= pc_nxt ;
         jmp_entries[i].is_jmp   <= br_en ;
      end
      else if( jmp_commit && rptr[PTR_W-1:0] == i[PTR_W-1:0] )
      begin
         jmp_entries[i].valid    <= '0 ;
      end
   end
end
endgenerate

always_ff@(posedge clk)
begin
   if( rst )
      wptr <= '0 ;
   else if( wr_vld && ~fifo_full )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rptr <= '0 ;
   else if( jmp_commit && ~fifo_empty )
      rptr <= rptr + 1'H1 ;
end

wire catch_up = wptr[PTR_W-1:0] == rptr[PTR_W-1:0] ;
wire extra_eq = wptr[PTR_W] == rptr[PTR_W] ;
assign fifo_full  = ~extra_eq && catch_up ;
assign fifo_empty = extra_eq && catch_up ;

assign rvs2jmp_itf.rdy = ~fifo_full ;

assign flush   = jmp_commit && jmp_entries[rptr[PTR_W-1:0]].is_jmp ;
assign pc_new  = jmp_entries[rptr[PTR_W-1:0]].pc ;

//------------------------------------------------------------------------------
// to CDB
//------------------------------------------------------------------------------

always_ff@(posedge clk)
begin
   if( rst )
      is_full <= '0 ;
   else if( wr_vld && ~rd_vld )
      is_full <= '1 ;
   else if( rd_vld && ~wr_vld )
      is_full <= '0 ;
end

assign rd_wr = rvs2jmp_itf.opc == jmp_op_jal || rvs2jmp_itf.opc == jmp_op_jalr ;

always_ff@(posedge clk)

begin
   if( rst )
   begin
      jmp2cdb_itf.req      <= '0 ;
      jmp2cdb_itf.tag      <= '0 ;
      jmp2cdb_itf.wdata    <= '0 ;
      jmp2cdb_itf.inst_id  <= '0 ;
   end
   //else if( wr_vld && rd_wr )
   else if( wr_vld )
   begin
      jmp2cdb_itf.req      <= '1 ;
      jmp2cdb_itf.tag      <= rvs2jmp_itf.tag ;
      jmp2cdb_itf.wdata    <= rob2jmp_itf.pc + 4 ;
      jmp2cdb_itf.inst_id  <= rvs2jmp_itf.inst_id ;
   end
   else if( rd_vld )
   begin
      jmp2cdb_itf.req      <= '0 ;
      jmp2cdb_itf.tag      <= '0 ;
   end
end


wire x = |rvs2jmp_itf.offset ;

assign rob2jmp_itf.pc_rob_id = rvs2jmp_itf.inst_id ;

endmodule


