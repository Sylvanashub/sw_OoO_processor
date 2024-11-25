
module gpr  (

    input   logic       clk
   ,input   logic       rst
   ,rob2gpr_itf.gpr     rob2gpr_itf         

);

logic [31:0] mem [1:31] ;

genvar i ;
generate
for(i=1;i<32;i++)
begin : rf
   always_ff@(posedge clk)
   begin
      if( rst )
      begin
         mem[i] <= '0 ;
      end
      else if( rob2gpr_itf.rd_wr && rob2gpr_itf.rd_addr == i[4:0] )
      begin
         mem[i] <= rob2gpr_itf.rd_wdata ;
      end
   end
end
endgenerate

assign rob2gpr_itf.rs1_rdata = ( rob2gpr_itf.rs1_addr == '0 ) ? '0 : mem[rob2gpr_itf.rs1_addr] ;
assign rob2gpr_itf.rs2_rdata = ( rob2gpr_itf.rs2_addr == '0 ) ? '0 : mem[rob2gpr_itf.rs2_addr] ;

endmodule
