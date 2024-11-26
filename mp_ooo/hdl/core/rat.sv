
module rat #(

    parameter  ROB_DEPTH   = 32'D16
   ,parameter  ROB_PTR_W   = $clog2(ROB_DEPTH)
   ,parameter  REG_NUM     = 32

) (

    input   logic                clk
   ,input   logic                rst

   ,dec2rat_itf.rat              dec2rat_itf
   ,rob2rat_itf.rat              rob2rat_itf

);

typedef struct {

   logic valid ;
   logic [ROB_PTR_W-1:0] rob_id ;

} entry_t ;

entry_t entries [REG_NUM] ;

genvar i ;

generate
for(i=0;i<REG_NUM;i++)
begin : entry
   always_ff@(posedge clk)
   begin
      if( rst )
      begin
         entries[i].valid  <= '1 ;
         entries[i].rob_id <= '0 ;
      end
      else if( dec2rat_itf.rd_wr && dec2rat_itf.rd_addr == i[4:0] )
      begin
         entries[i].valid  <= '0 ;
         entries[i].rob_id <= dec2rat_itf.rob_id ;
      end
      else if( rob2rat_itf.commit && rob2rat_itf.rd_addr == i[4:0] && rob2rat_itf.rob_id == entries[i].rob_id)
      begin
         entries[i].valid  <= '1 ;
      end
   end
end
endgenerate

always_comb
begin
   rob2rat_itf.rs1_valid   = (dec2rat_itf.rs1_addr == '0) || entries[dec2rat_itf.rs1_addr].valid  ;
   rob2rat_itf.rs1_rob_id  = entries[dec2rat_itf.rs1_addr].rob_id ;
   rob2rat_itf.rs2_valid   = (dec2rat_itf.rs2_addr == '0) || entries[dec2rat_itf.rs2_addr].valid  ;
   rob2rat_itf.rs2_rob_id  = entries[dec2rat_itf.rs2_addr].rob_id ;
end

endmodule
