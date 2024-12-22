
module pcsb 
#(

   parameter   DEPTH = 16 
   ,parameter  ENABLE = 1

)  (

    input   logic    clk
   ,input   logic    rst

   ,dmem_itf.slv     slv_itf
   ,dmem_itf.mst     mst_itf

);

generate
if( ENABLE == 1 )
begin : pcsb

localparam  PTR_W = $clog2(DEPTH) ;

localparam  IDLE  = 3'H0   ;
localparam  STORE = 3'H1   ;
localparam  WAIT  = 3'H2   ;
localparam  PEND  = 3'H3   ;

localparam  RD_IDLE  = 1'H0 ;
localparam  RD_RESP  = 1'H1 ;


logic [2:0] state_r  ;
logic [2:0] state_nxt ;
logic rd_state_r ;
logic rd_state_nxt ;

typedef struct {

   logic [31:0]   addr  ;
   logic [3:0]    wmask ;
   logic [3:0]    rmask ;
   logic [31:0]   wdata ;

} entry_t ;

entry_t  entries [DEPTH] ;

logic fifo_wr  ;
logic fifo_rd  ;
logic fifo_afull  ;
logic fifo_empty  ;

logic [PTR_W-1:0] wptr ;
logic [PTR_W-1:0] rptr ;
logic [PTR_W:0]   fifo_count ;

wire mem_wr_access = |slv_itf.wmask ;
wire mem_rd_access = |slv_itf.rmask ;
wire mem_access   = mem_wr_access | mem_rd_access ;

//------------------------------------------------------------------------------
// FIFO
//------------------------------------------------------------------------------

assign fifo_wr = state_r == STORE && mem_access ;
assign fifo_rd = ~fifo_empty && ((rd_state_r == RD_RESP && mst_itf.resp) || (rd_state_r == RD_IDLE )) ;

always_ff@(posedge clk)
begin
   if( rst )
      wptr <= '0 ;
   else if( fifo_wr )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rptr <= '0 ;
   else if( fifo_rd )
      rptr <= rptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      fifo_count <= '0 ;
   else if( fifo_wr && ~fifo_rd )
      fifo_count <= fifo_count + 1'H1 ;
   else if( ~fifo_wr && fifo_rd )
      fifo_count <= fifo_count - 1'H1 ;
end

assign fifo_afull = fifo_count >= {1'H0,{PTR_W{1'H1}}} ;
assign fifo_empty = fifo_count == '0 ;

always_ff@(posedge clk)
begin
   if( fifo_wr )
   begin
      entries[wptr].addr   <= slv_itf.addr    ;
      entries[wptr].wmask  <= slv_itf.wmask   ;
      entries[wptr].rmask  <= slv_itf.rmask   ;
      entries[wptr].wdata  <= slv_itf.wdata   ;
   end
end

//------------------------------------------------------------------------------
// State machine
//------------------------------------------------------------------------------
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
   IDLE :
   begin
      if( mem_wr_access )
         state_nxt = STORE ;
   end
   STORE :
   begin
      if( mem_wr_access && fifo_afull )
         state_nxt = WAIT ;
      else if( mem_rd_access )
         state_nxt = PEND ;
      else if( fifo_empty && mst_itf.resp && ~mem_wr_access )
         state_nxt = IDLE ;
   end
   WAIT :
   begin
      if( fifo_rd )
         state_nxt = STORE ;
   end
   PEND :
   begin
      if( fifo_count == {{PTR_W{1'H0}},1'H1} && fifo_rd )
         state_nxt = IDLE ;
   end
   endcase
end


always_ff@(posedge clk)
begin
   if( rst )
      rd_state_r <= RD_IDLE ;
   else
      rd_state_r <= rd_state_nxt ;
end

always_comb
begin
   rd_state_nxt = rd_state_r ;
   case( rd_state_r )
   RD_IDLE :
   begin
      if( 
         (state_r == IDLE && mem_access) || 
         ~fifo_empty
      )
         rd_state_nxt = RD_RESP ;
   end
   RD_RESP :
   begin
      if( mst_itf.resp && fifo_empty )
         rd_state_nxt = RD_IDLE ;
   end
   endcase
end

//------------------------------------------------------------------------------
// slv mem itf
//------------------------------------------------------------------------------

logic slv_resp_r ;
logic slv_resp_nxt ;

assign slv_resp_nxt =((state_r == IDLE || state_r == STORE) && mem_wr_access && ~fifo_afull) ||
                     ((state_r == WAIT) && fifo_rd ) ;

always_ff@(posedge clk)
begin
   if( rst )
      slv_resp_r <= '0 ;
   else 
      slv_resp_r <= slv_resp_nxt ;
end

assign slv_itf.resp = (state_r == IDLE) ? mst_itf.resp : slv_resp_r ;
assign slv_itf.rdata = mst_itf.rdata ;

//------------------------------------------------------------------------------
// mst mem itf
//------------------------------------------------------------------------------

always_comb
begin
   if( state_r == IDLE )
   begin
      mst_itf.addr  = slv_itf.addr  ;
      mst_itf.rmask = slv_itf.rmask ;
      mst_itf.wmask = slv_itf.wmask ;
      mst_itf.wdata = slv_itf.wdata ;
   end
   else if( fifo_rd )
   begin
      mst_itf.addr  = entries[rptr].addr ;
      mst_itf.rmask = entries[rptr].rmask ;
      mst_itf.wmask = entries[rptr].wmask ;
      mst_itf.wdata = entries[rptr].wdata ;
   end
   else
   begin
      mst_itf.addr  = '0 ;
      mst_itf.rmask = '0 ;
      mst_itf.wmask = '0 ;
      mst_itf.wdata = '0 ;
   end
end

end
else
begin

assign mst_itf.addr  = slv_itf.addr  ;
assign mst_itf.rmask = slv_itf.rmask ;
assign mst_itf.wmask = slv_itf.wmask ;
assign mst_itf.wdata = slv_itf.wdata ;

assign slv_itf.rdata = mst_itf.rdata ;
assign slv_itf.resp  = mst_itf.resp  ;

wire x = clk | rst ;

end
endgenerate

//------------------------------------------------------------------------------
// Store to load forwarding
//------------------------------------------------------------------------------

//logic load_match ;
//logic [DEPTH-1:0] addr_match ;
//logic [31:0] load_rdata ;
//assign load_match = |slv_itf.rmask && |addr_match ;
//
//always_comb
//begin
//   load_rdata = '0 ;
//   for(int i=0;i<DEPTH;i++)
//   begin
//      if( addr_match[i] )
//         load_rdata = entries[i].wdata ;
//   end
//end
//
//genvar i;
//generate
//for(i=0;i<DEPTH;i++)
//begin : am
//   assign addr_match[i] = (entries[wptr-i[PTR_W-1:0]].addr == slv_itf.addr) && (entries[wptr-i[PTR_W-1:0]].wmask == 4'HF);
//end
//endgenerate

endmodule
