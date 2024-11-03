
module decode (

    input   logic          clk
   ,input   logic          rst

   ,output  logic          dequeue
   ,input   logic [63:0]   dequeue_rdata
   ,input   logic          is_empty

);

logic [31:0] inst_r [8] ;
logic [31:0] pc_r [8] ;

assign dequeue = ~is_empty ;

always_ff@(posedge clk)
begin
   if( rst )
   begin
      for(int i=0;i<8;i++)
      begin
         inst_r[i] <= '0 ;
         pc_r[i] <= '0 ;
      end
   end
   else if( dequeue )
   begin
      inst_r[0] <= dequeue_rdata[31:0] ;
      pc_r[0]   <= dequeue_rdata[63:32] ;
      for(int i=1;i<8;i++)
      begin
         inst_r[i] <= inst_r[i-1] ;
         pc_r[i] <= pc_r[i-1] ;
      end
   end
end

endmodule
