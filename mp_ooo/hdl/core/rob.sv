
module rob 
import rv32i_types::* ;
#(

   parameter   TAG_W = 32'D4 ,
   parameter   DEPTH = 16 ,
   parameter   PTR_W = $clog2(DEPTH)

) (

    input   logic    clk
   ,input   logic    rst

   ,dec2rob_itf.rob  dec2rob_itf

   ,rvs2rob_itf.rob  rvs2rob_itf
   
   ,cdb_itf.slv      cdb_itf

   ,rob2lsu_itf.rob  rob2lsu_itf

   ,rob2rat_itf.rob  rob2rat_itf

   ,rob2gpr_itf.rob  rob2gpr_itf

   ,rob2jmp_itf.rob  rob2jmp_itf

   ,input   logic          flush

);

typedef struct packed {

   logic [31:0]      inst  ;
   logic [31:0]      pc    ;
   logic [TAG_W-1:0] tag   ;
   logic [TAG_W-1:0] rs1_tag ;
   logic [TAG_W-1:0] rs2_tag ;
   logic [31:0]      rs1_rdata ;
   logic [31:0]      rs2_rdata ;
   logic [31:0]      wdata ;
   logic             valid ;
   logic             ready ;

} rob_entry_t ;

logic [PTR_W-1:0] wptr ;
logic [PTR_W-1:0] rptr ;

rob_entry_t rob_entries [DEPTH] ;

assign dec2rob_itf.inst_id = wptr ;

genvar i ;
generate 
for(i=0;i<DEPTH;i++)
begin : entry
   always@(posedge clk)
   begin
      if( rst|| flush )
      begin
         rob_entries[i].tag      <= '0 ;
         rob_entries[i].valid    <= '0 ;
         rob_entries[i].ready    <= '0 ;
         rob_entries[i].wdata    <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].inst     <= dec2rob_itf.inst     ;
         rob_entries[i].pc       <= dec2rob_itf.pc       ;
         rob_entries[i].tag      <= dec2rob_itf.tag      ;
         rob_entries[i].valid    <= '1 ;
         rob_entries[i].ready    <= '0 ;//dec2rob_itf.inst[6:0] == op_b_br ;

      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].tag && cdb_itf.inst_id == i[PTR_W-1:0] )
      begin
         rob_entries[i].tag      <= '0 ;
         rob_entries[i].wdata    <= cdb_itf.wdata ;
         rob_entries[i].ready    <= '1 ;
      end
      else if( rob_entries[i].valid && rob_entries[i].ready && rptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].valid    <= '0 ;
         rob_entries[i].ready    <= '0 ;
      end
   end

   always@(posedge clk)
   begin
      if( rst|| flush )
      begin
         rob_entries[i].rs1_tag  <= '0 ;
         rob_entries[i].rs1_rdata <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].rs1_tag  <= dec2rob_itf.rs1_tag  ;
         rob_entries[i].rs1_rdata<= dec2rob_itf.rs1_rdata;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].rs1_tag )
      begin
         rob_entries[i].rs1_tag   <= '0            ;
         rob_entries[i].rs1_rdata <= cdb_itf.wdata ;
      end
   end

   always@(posedge clk)
   begin
      if( rst|| flush )
      begin
         rob_entries[i].rs2_tag  <= '0 ;
         rob_entries[i].rs2_rdata <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].rs2_tag  <= dec2rob_itf.rs2_tag  ;
         rob_entries[i].rs2_rdata<= dec2rob_itf.rs2_rdata;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].rs2_tag )
      begin
         rob_entries[i].rs2_tag   <= '0            ;
         rob_entries[i].rs2_rdata <= cdb_itf.wdata ;
      end
   end


end
endgenerate
logic is_full ;
logic fifo_rd ;
assign fifo_rd = rob_entries[rptr].valid && rob_entries[rptr].ready ;

assign rvs2rob_itf.busy = is_full ;

assign rob2lsu_itf.inst_id = rptr ;

always_ff@(posedge clk)
begin
   if( rst|| flush )
      wptr <= '0;
   else if( dec2rob_itf.issue )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst|| flush )
      rptr <= '0;
   else if( rob_entries[rptr].valid && rob_entries[rptr].ready )
      rptr <= rptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst|| flush )
      is_full <= '0 ;
   else if( dec2rob_itf.issue && ~fifo_rd && ( wptr + 1'H1 == rptr ) )
      is_full <= '1 ;
   else if( is_full && ~dec2rob_itf.issue && fifo_rd )
      is_full <= '0 ;
end

logic   [6:0]   opcode;
assign opcode = rob_entries[rptr].inst[6:0];
wire  opcode_wo_rd = opcode == op_b_store || opcode == op_b_br ;

//------------------------------------------------------------------------------
// dec2rob
//------------------------------------------------------------------------------

always@(*)//_comb
begin

   dec2rob_itf.rs1_valid   = '1 ;
   dec2rob_itf.rs1_tag     = '0 ;
   dec2rob_itf.rs1_rdata   = '0 ;

   if( rob2rat_itf.rs1_valid )
   begin
      dec2rob_itf.rs1_rdata   = rob2gpr_itf.rs1_rdata ;
   end
   else if( rob_entries[rob2rat_itf.rs1_rob_id].valid )
   begin
      if( rob_entries[rob2rat_itf.rs1_rob_id].ready )
      begin
         dec2rob_itf.rs1_rdata = rob_entries[rob2rat_itf.rs1_rob_id].wdata ;
      end
      else if( cdb_itf.wr && cdb_itf.tag == rob_entries[rob2rat_itf.rs1_rob_id].tag )
      begin
         dec2rob_itf.rs1_rdata = cdb_itf.wdata ;
      end
      else
      begin
         dec2rob_itf.rs1_valid   = '0 ;
         dec2rob_itf.rs1_tag     = rob_entries[rob2rat_itf.rs1_rob_id].tag ;
      end
   end

end

always@(*)//_comb
begin

   dec2rob_itf.rs2_valid   = '1 ;
   dec2rob_itf.rs2_tag     = '0 ;
   dec2rob_itf.rs2_rdata   = '0 ;

   if( rob2rat_itf.rs2_valid )
   begin
      dec2rob_itf.rs2_rdata   = rob2gpr_itf.rs2_rdata ;
   end
   else if( rob_entries[rob2rat_itf.rs2_rob_id].valid )
   begin
      if( rob_entries[rob2rat_itf.rs2_rob_id].ready )
      begin
         dec2rob_itf.rs2_rdata = rob_entries[rob2rat_itf.rs2_rob_id].wdata ;
      end
      else if( cdb_itf.wr && cdb_itf.tag == rob_entries[rob2rat_itf.rs2_rob_id].tag )
      begin
         dec2rob_itf.rs2_rdata = cdb_itf.wdata ;
      end
      else
      begin
         dec2rob_itf.rs2_valid   = '0 ;
         dec2rob_itf.rs2_tag     = rob_entries[rob2rat_itf.rs2_rob_id].tag ;
      end
   end

end

//------------------------------------------------------------------------------
// rob2rat
//------------------------------------------------------------------------------

assign rob2rat_itf.commit     = rob2gpr_itf.rd_wr     ;
assign rob2rat_itf.rd_addr    = rob2gpr_itf.rd_addr   ;
assign rob2rat_itf.rob_id     = rptr ;

//------------------------------------------------------------------------------
// rob2gpr
//------------------------------------------------------------------------------

assign rob2gpr_itf.rs1_addr   = dec2rob_itf.inst[19:15];
assign rob2gpr_itf.rs2_addr   = dec2rob_itf.inst[24:20];

assign rob2gpr_itf.rd_wr      = rob_entries[rptr].valid && rob_entries[rptr].ready && ~opcode_wo_rd ;
assign rob2gpr_itf.rd_addr    = opcode_wo_rd ? '0 : rob_entries[rptr].inst[11:7] ;
assign rob2gpr_itf.rd_wdata   = rob_entries[rptr].wdata ;


//------------------------------------------------------------------------------
// rob2jmp
//------------------------------------------------------------------------------


assign rob2jmp_itf.pc      = rob_entries[rob2jmp_itf.pc_rob_id].pc ;
assign rob2jmp_itf.ready   = rob_entries[rptr].ready ;
assign rob2jmp_itf.rob_id  = rptr ;

endmodule
