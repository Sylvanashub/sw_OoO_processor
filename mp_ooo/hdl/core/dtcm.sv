
module dtcm (

    input   logic    clk
   ,input   logic    rst

   ,dmem_itf.slv     slv_itf 
   ,dmem_itf.mst     mst_itf 
   
);

//localparam  MEM_START   = 32'HEFFF_FE00 ;
//localparam  MEM_END     = 32'HEFFF_FFFF ;
//localparam  MEM_SIZE    = 128 ;

localparam  MEM_START   = 32'H1ECF_1000 ;
localparam  MEM_END     = 32'H1ECF_2FFF ;
localparam  MEM_SIZE    = 2048 ;


localparam  ADDR_W      = $clog2(MEM_SIZE) ;


localparam IDLE   = 2'H0 ;
localparam SRAM   = 2'H1 ;
localparam RESP   = 2'H2 ;

logic [31:0] mem [MEM_SIZE] ;
logic [ADDR_W-1:0] mem_addr ;

logic [31:0] mem_dout ;
logic [1:0] state_r ;
logic [1:0] state_nxt ;

logic addr_match ;
logic wr_valid ;
logic rd_valid ;
logic rw_valid ;

//assign addr_match = slv_itf.addr[31:16] == 16'HEFFF && slv_itf.addr[15:9] == 7'H7F ;
assign addr_match = slv_itf.addr >= MEM_START && slv_itf.addr <= MEM_END ;

assign wr_valid = |slv_itf.wmask ;
assign rd_valid = |slv_itf.rmask ;
assign rw_valid = wr_valid | rd_valid ;

assign mem_addr = slv_itf.addr[2+:(ADDR_W-1)] ;

always_ff@(posedge clk)
begin
   if( rst )
      state_r <= IDLE ;
   else
      state_r <= state_nxt ;
end

always_comb
begin
   state_nxt = state_r ;
   case( state_r )
   IDLE : if( rw_valid ) state_nxt = addr_match ? SRAM : RESP ;
   SRAM : 
   if( rw_valid )
      state_nxt = addr_match ? SRAM : RESP ;
   else
      state_nxt = IDLE ;
   RESP : 
   if( mst_itf.resp )
   begin
      if( rw_valid )
         state_nxt = addr_match ? SRAM : RESP ;
      else
         state_nxt = IDLE ;
   end
   endcase
end

always@(posedge clk)
begin
   if( addr_match )
   begin
      if( slv_itf.wmask[0] ) mem[mem_addr][ 0+:8] <= slv_itf.wdata[ 0+:8] ;
      if( slv_itf.wmask[1] ) mem[mem_addr][ 8+:8] <= slv_itf.wdata[ 8+:8] ;
      if( slv_itf.wmask[2] ) mem[mem_addr][16+:8] <= slv_itf.wdata[16+:8] ;
      if( slv_itf.wmask[3] ) mem[mem_addr][24+:8] <= slv_itf.wdata[24+:8] ;
   end
   mem_dout <= mem[mem_addr] ;
end


assign slv_itf.rdata = state_r == SRAM ? mem_dout : mst_itf.rdata ;
assign slv_itf.resp  = state_r == SRAM ? '1 : mst_itf.resp ;

assign mst_itf.addr  = slv_itf.addr ;
assign mst_itf.wmask = addr_match ? '0 : slv_itf.wmask ;
assign mst_itf.rmask = addr_match ? '0 : slv_itf.rmask ;
assign mst_itf.wdata = slv_itf.wdata ;


endmodule
