module cdb
//#(
//
//   parameter   TAG_W    = 32'D4  
//
//)
(

    input   logic       clk
   ,input   logic       rst

   ,exu2cdb_itf.cdb     alu2cdb_itf
   ,exu2cdb_itf.cdb     mdu2cdb_itf
   ,exu2cdb_itf.cdb     lsu2cdb_itf
   ,exu2cdb_itf.cdb     jmp2cdb_itf

   ,cdb_itf.mst         cdb_itf

);

//assign alu2cdb_itf.rdy = alu2cdb_itf.req ;
//assign mdu2cdb_itf.rdy = mdu2cdb_itf.req && ~alu2cdb_itf.req ;
//assign lsu2cdb_itf.rdy = lsu2cdb_itf.req && ~mdu2cdb_itf.req && ~alu2cdb_itf.req ;


//// priority alu > mdu > lsu
//assign alu2cdb_itf.rdy = 1'H1 ; 
//assign mdu2cdb_itf.rdy = ~alu2cdb_itf.req ;
//assign lsu2cdb_itf.rdy = ~( mdu2cdb_itf.req | alu2cdb_itf.req ) ;

// priority mdu > lsu > alu
//assign mdu2cdb_itf.rdy = 1'H1 ; 
//assign lsu2cdb_itf.rdy = ~mdu2cdb_itf.req ;
//assign alu2cdb_itf.rdy = ~( mdu2cdb_itf.req | lsu2cdb_itf.req ) ;

// priority lsu > mdu > alu
assign jmp2cdb_itf.rdy = 1'H1 ; 
assign lsu2cdb_itf.rdy = ~jmp2cdb_itf.req ;
assign mdu2cdb_itf.rdy = ~( jmp2cdb_itf.req | lsu2cdb_itf.req ) ;
assign alu2cdb_itf.rdy = ~( jmp2cdb_itf.req | mdu2cdb_itf.req | lsu2cdb_itf.req ) ;

always_ff@(posedge clk)
begin
   if( rst )
   begin
      cdb_itf.wr     <= '0 ;
      //cdb_itf.addr   <= '0 ;
      cdb_itf.tag    <= '0 ;
      cdb_itf.wdata  <= '0 ;
      cdb_itf.inst_id   <= '0 ;
   end
   else if( jmp2cdb_itf.req && jmp2cdb_itf.rdy )
   begin
      cdb_itf.wr     <= '1 ;
      //cdb_itf.addr   <= '0 ;
      cdb_itf.tag    <= jmp2cdb_itf.tag   ;
      cdb_itf.wdata  <= jmp2cdb_itf.wdata ;
      cdb_itf.inst_id <= jmp2cdb_itf.inst_id ;
   end
   else if( alu2cdb_itf.req && alu2cdb_itf.rdy )
   begin
      cdb_itf.wr     <= '1 ;
      //cdb_itf.addr   <= '0 ;
      cdb_itf.tag    <= alu2cdb_itf.tag   ;
      cdb_itf.wdata  <= alu2cdb_itf.wdata ;
      cdb_itf.inst_id <= alu2cdb_itf.inst_id ;
   end
   else if( mdu2cdb_itf.req && mdu2cdb_itf.rdy )
   begin
      cdb_itf.wr     <= '1 ;
      //cdb_itf.addr   <= '0 ;
      cdb_itf.tag    <= mdu2cdb_itf.tag   ;
      cdb_itf.wdata  <= mdu2cdb_itf.wdata ;
      cdb_itf.inst_id <= mdu2cdb_itf.inst_id ;
   end
   else if( lsu2cdb_itf.req && lsu2cdb_itf.rdy )
   begin
      cdb_itf.wr     <= '1 ;
      //cdb_itf.addr   <= '0 ;
      cdb_itf.tag    <= lsu2cdb_itf.tag   ;
      cdb_itf.wdata  <= lsu2cdb_itf.wdata ;
      cdb_itf.inst_id <= lsu2cdb_itf.inst_id ;
   end
   else
   begin
      cdb_itf.wr     <= '0 ;
      //cdb_itf.addr   <= '0 ;
      //cdb_itf.tag    <= '0 ;
      //cdb_itf.wdata  <= '0 ;
   end
end

endmodule
