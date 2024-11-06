
module rob 
import rv32i_types::* ;
#(

   parameter   TAG_W = 32'D4 ,
   parameter   DEPTH = 32'D16 ,
   parameter   PTR_W = $clog2(DEPTH)

) (

    input   logic    clk
   ,input   logic    rst

   ,dec2rob_itf.rob  dec2rob_itf

   ,cdb_itf.slv      cdb_itf

   ,rob2mon_itf      rob2mon_itf

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

genvar i ;
generate 
for(i=0;i<DEPTH;i++)
begin : entry
   always@(posedge clk)
   begin
      if( rst )
      begin
         rob_entries[i].tag      <= '0 ;
         rob_entries[i].rs1_tag  <= '0 ;
         rob_entries[i].rs2_tag  <= '0 ;
         rob_entries[i].valid    <= '0 ;
         rob_entries[i].ready    <= '0 ;
      end
      else if( dec2rob_itf.issue && wptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].inst     <= dec2rob_itf.inst     ;
         rob_entries[i].pc       <= dec2rob_itf.pc       ;
         rob_entries[i].tag      <= dec2rob_itf.tag      ;
         rob_entries[i].rs1_tag  <= dec2rob_itf.rs1_tag  ;
         rob_entries[i].rs2_tag  <= dec2rob_itf.rs2_tag  ;
         rob_entries[i].rs1_rdata<= dec2rob_itf.rs1_rdata;
         rob_entries[i].rs2_rdata<= dec2rob_itf.rs2_rdata;

         rob_entries[i].valid <= '1 ;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].tag )
      begin
         rob_entries[i].tag   <= '0 ;
         rob_entries[i].wdata <= cdb_itf.wdata ;
         rob_entries[i].ready <= '1 ;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].rs1_tag )
      begin
         rob_entries[i].rs1_tag   <= '0            ;
         rob_entries[i].rs1_rdata <= cdb_itf.wdata ;
      end
      else if( rob_entries[i].valid && cdb_itf.wr && cdb_itf.tag == rob_entries[i].rs2_tag )
      begin
         rob_entries[i].rs2_tag   <= '0            ;
         rob_entries[i].rs2_rdata <= cdb_itf.wdata ;
      end
      else if( rob_entries[i].valid && rob_entries[i].ready && rptr == i[PTR_W-1:0] )
      begin
         rob_entries[i].valid <= '0 ;
         rob_entries[i].ready <= '0 ;
      end
   end
end
endgenerate

always_ff@(posedge clk)
begin
   if( rst )
      wptr <= '0;
   else if( dec2rob_itf.issue )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rptr <= '0;
   else if( rob_entries[rptr].valid && rob_entries[rptr].ready )
      rptr <= rptr + 1'H1 ;
end

logic [63:0]   mon_order ;
always_ff@(posedge clk)
begin
   if( rst )
   begin
      mon_order <= '0 ;
   end
   else if( rob2mon_itf.valid )
   begin
      mon_order <= mon_order + 1;
   end
end

logic   [6:0]   opcode;
assign opcode = rob_entries[rptr].inst[6:0];

wire rs1_addr_vld =  opcode == op_b_jalr  || 
                     opcode == op_b_br    || 
                     opcode == op_b_load  || 
                     opcode == op_b_store || 
                     opcode == op_b_imm   ||
                     opcode == op_b_reg   
                     ;
wire rs2_addr_vld = opcode == op_b_br || opcode == op_b_store || opcode == op_b_reg ;


assign rob2mon_itf.valid      = rob_entries[rptr].valid && rob_entries[rptr].ready ;
assign rob2mon_itf.order      = mon_order ;
assign rob2mon_itf.inst       = rob_entries[rptr].inst ;
assign rob2mon_itf.rs1_addr   = rs1_addr_vld ? rob_entries[rptr].inst[19:15] : '0 ;
assign rob2mon_itf.rs2_addr   = rs2_addr_vld ? rob_entries[rptr].inst[24:20] : '0 ;
assign rob2mon_itf.rs1_rdata  = rob_entries[rptr].rs1_rdata ;
assign rob2mon_itf.rs2_rdata  = rob_entries[rptr].rs2_rdata ;
assign rob2mon_itf.rd_addr    = rob_entries[rptr].inst[11:7] ;
assign rob2mon_itf.rd_wdata   = rob_entries[rptr].wdata ;
assign rob2mon_itf.pc_rdata   = rob_entries[rptr].pc  ;
assign rob2mon_itf.pc_wdata   = rob_entries[rptr].pc + 4 ;
assign rob2mon_itf.mem_addr   = '0 ;
assign rob2mon_itf.mem_rmask  = '0 ;
assign rob2mon_itf.mem_wmask  = '0 ;
assign rob2mon_itf.mem_rdata  = '0 ;
assign rob2mon_itf.mem_wdata  = '0 ;

endmodule
