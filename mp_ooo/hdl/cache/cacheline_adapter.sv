
module cacheline_adapter (

    input   logic             clk
   ,input   logic             rst

   ,input   logic   [31:0]    dfp0_addr
   ,input   logic             dfp0_read
   ,input   logic             dfp0_write
   ,output  logic   [255:0]   dfp0_rdata
   ,input   logic   [255:0]   dfp0_wdata
   ,output  logic             dfp0_resp

   ,input   logic   [31:0]    dfp1_addr
   ,input   logic             dfp1_read
   ,input   logic             dfp1_write
   ,output  logic   [255:0]   dfp1_rdata
   ,input   logic   [255:0]   dfp1_wdata
   ,output  logic             dfp1_resp

   ,output  logic   [31:0]    bmem_addr
   ,output  logic             bmem_read
   ,output  logic             bmem_write
   ,output  logic   [63:0]    bmem_wdata
   ,input   logic             bmem_ready

   ,input   logic   [31:0]    bmem_raddr
   ,input   logic   [63:0]    bmem_rdata
   ,input   logic             bmem_rvalid

);

localparam  IDLE        = 5'H0 ;
localparam  R0_0        = 5'H1 ;
localparam  R0_1        = 5'H2 ;
localparam  R0_2        = 5'H3 ;
localparam  R0_3        = 5'H4 ;
localparam  W0_1        = 5'H5 ;
localparam  W0_2        = 5'H6 ;
localparam  W0_3        = 5'H7 ;
localparam  R1_0        = 5'H8 ;
localparam  R1_1        = 5'H9 ;
localparam  R1_2        = 5'HA ;
localparam  R1_3        = 5'HB ;
localparam  W1_1        = 5'HC ;
localparam  W1_2        = 5'HD ;
localparam  W1_3        = 5'HE ;
localparam  DFP1_R      = 5'HF ;
localparam  DFP1_W      = 5'H10 ;


logic [4:0] state_r ;
logic [4:0] state_nxt ;

logic [64*3-1:0]  bmem_rdata_r ;

logic read_valid0  ;
logic write_valid0 ;
logic read_valid1  ;
logic write_valid1 ;

assign read_valid0  = dfp0_read && bmem_ready ;
assign write_valid0 = dfp0_write && bmem_ready ;
assign read_valid1  = dfp1_read && bmem_ready ;
assign write_valid1 = dfp1_write && bmem_ready ;

wire _x = |bmem_raddr ;

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
      if( read_valid0 ) state_nxt = R0_0 ;
      else if( write_valid0 ) state_nxt = W0_1 ;
      else if( read_valid1 ) state_nxt = R1_0 ;
      else if( write_valid1 ) state_nxt = W1_1 ;
      else                    state_nxt = IDLE;
   end
   R0_0 : if( bmem_rvalid ) state_nxt = R0_1 ;
   R0_1 : if( bmem_rvalid ) state_nxt = R0_2 ;
   R0_2 : if( bmem_rvalid ) state_nxt = R0_3 ;
   R0_3 :
   begin
      if ( bmem_rvalid )
      begin
         if( dfp1_read )   state_nxt = DFP1_R;
         else if( dfp1_write ) state_nxt = DFP1_W;
         else state_nxt = IDLE ;
      end
   end
   W0_1 : if( bmem_ready ) state_nxt = W0_2 ;
   W0_2 : if( bmem_ready ) state_nxt = W0_3 ;
   W0_3 : 
   begin
      if ( bmem_ready )
      begin
         if( dfp1_read )   state_nxt = DFP1_R;
         else if( dfp1_write ) state_nxt = DFP1_W;
         else state_nxt = IDLE ;
      end
   end
   R1_0 : if( bmem_rvalid ) state_nxt = R1_1 ;
   R1_1 : if( bmem_rvalid ) state_nxt = R1_2 ;
   R1_2 : if( bmem_rvalid ) state_nxt = R1_3 ;
   R1_3 : if( bmem_rvalid ) state_nxt = IDLE ;
   W1_1 : if( bmem_ready ) state_nxt = W1_2 ;
   W1_2 : if( bmem_ready ) state_nxt = W1_3 ;
   W1_3 : if( bmem_ready ) state_nxt = IDLE ;
   DFP1_R:if( bmem_ready ) state_nxt = R1_0 ;
   DFP1_W:if( bmem_ready ) state_nxt = W1_1 ;
   default: state_nxt = IDLE;
   endcase
end

always_ff@(posedge clk)
begin
   if( rst )
      bmem_rdata_r <= {(64*3){1'H0}} ;
   else if( bmem_rvalid )
      case( state_r )
      R0_0,R1_0 : bmem_rdata_r[64*1-1:64*0] <= bmem_rdata ;
      R0_1,R1_1 : bmem_rdata_r[64*2-1:64*1] <= bmem_rdata ;
      R0_2,R1_2 : bmem_rdata_r[64*3-1:64*2] <= bmem_rdata ;
      default : bmem_rdata_r <= bmem_rdata_r ;
      endcase
end

assign dfp0_rdata = {bmem_rdata,bmem_rdata_r}  ;
assign dfp1_rdata = {bmem_rdata,bmem_rdata_r}  ;
assign dfp0_resp  = bmem_rvalid && state_r == R0_3 || bmem_ready && state_r == W0_3 ;
assign dfp1_resp  = bmem_rvalid && state_r == R1_3 || bmem_ready && state_r == W1_3 ;

assign bmem_addr  = ((state_r == IDLE && (dfp0_read||dfp0_write)) || (state_r == W0_1) || (state_r == W0_2) || (state_r == W0_3))?{dfp0_addr[31:5],5'b0}:{dfp1_addr[31:5],5'b0} ;
assign bmem_read  = ( state_r == IDLE ) && ( dfp0_read || dfp1_read && ~dfp0_write ) ||( state_r == DFP1_R )  ;
assign bmem_write = ( state_r == IDLE && (dfp0_write||dfp1_write&&~dfp0_read) ) ||  (state_r == W0_1) || (state_r == W0_2) || (state_r == W0_3) || (state_r == W1_1) || (state_r == W1_2) || (state_r == W1_3) || (state_r == DFP1_W);

always_comb
begin
   unique case( state_r )
   IDLE     : 
   begin
      if( dfp0_write )
         bmem_wdata = dfp0_wdata[64*1-1:64*0] ;
      else //if( dfp1_write )
         bmem_wdata = dfp1_wdata[64*1-1:64*0] ;
   end
   W0_1     : bmem_wdata = dfp0_wdata[64*2-1:64*1] ;
   W0_2     : bmem_wdata = dfp0_wdata[64*3-1:64*2] ;
   W0_3     : bmem_wdata = dfp0_wdata[64*4-1:64*3] ;
   W1_1     : bmem_wdata = dfp1_wdata[64*2-1:64*1] ;
   W1_2     : bmem_wdata = dfp1_wdata[64*3-1:64*2] ;
   W1_3     : bmem_wdata = dfp1_wdata[64*4-1:64*3] ;
   DFP1_W   : bmem_wdata = dfp1_wdata[64*1-1:64*0] ;
   default  : bmem_wdata = dfp0_wdata[64*1-1:64*0] ;
   endcase
end

endmodule
