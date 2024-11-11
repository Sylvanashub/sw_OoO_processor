
module cacheline_adapter (

    input   logic             clk
   ,input   logic             rst

   ,input   logic   [31:0]    dfp_addr
   ,input   logic             dfp_read
   ,input   logic             dfp_write
   ,output  logic   [255:0]   dfp_rdata
   ,input   logic   [255:0]   dfp_wdata
   ,output  logic             dfp_resp

   ,output  logic   [31:0]    bmem_addr
   ,output  logic             bmem_read
   ,output  logic             bmem_write
   ,output  logic   [63:0]    bmem_wdata
   ,input   logic             bmem_ready

   ,input   logic   [31:0]    bmem_raddr
   ,input   logic   [63:0]    bmem_rdata
   ,input   logic             bmem_rvalid

);

localparam  IDLE        = 3'H0 ;
localparam  R0          = 3'H1 ;
localparam  R1          = 3'H2 ;
localparam  R2          = 3'H3 ;
localparam  R3          = 3'H4 ;
localparam  W1          = 3'H5 ;
localparam  W2          = 3'H6 ;
localparam  W3          = 3'H7 ;

logic [2:0] state_r ;
logic [2:0] state_nxt ;

logic [64*3-1:0]  bmem_rdata_r ;

logic read_valid  ;
logic write_valid ;

assign read_valid  = dfp_read && bmem_ready ;
assign write_valid = dfp_write && bmem_ready ;

// verilator lint_off UNUSEDSIGNAL
wire _x = |bmem_raddr ;
// verilator lint_on UNUSEDSIGNAL

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
      if( read_valid ) state_nxt = R0 ;
      else if( write_valid ) state_nxt = W1 ;
   end
   R0 : if( bmem_rvalid ) state_nxt = R1 ;
   R1 : if( bmem_rvalid ) state_nxt = R2 ;
   R2 : if( bmem_rvalid ) state_nxt = R3 ;
   R3 : if( bmem_ready ) state_nxt = IDLE ;
   W1 : if( bmem_ready ) state_nxt = W2 ;
   W2 : if( bmem_ready ) state_nxt = W3 ;
   W3 : if( bmem_ready ) state_nxt = IDLE ;
   endcase
end

always_ff@(posedge clk)
begin
   if( rst )
      bmem_rdata_r <= {(64*3){1'H0}} ;
   else if( bmem_rvalid )
      case( state_r )
      R0 : bmem_rdata_r[64*1-1:64*0] <= bmem_rdata ;
      R1 : bmem_rdata_r[64*2-1:64*1] <= bmem_rdata ;
      R2 : bmem_rdata_r[64*3-1:64*2] <= bmem_rdata ;
      default : bmem_rdata_r <= bmem_rdata_r ;
      endcase
end

assign dfp_rdata = {bmem_rdata,bmem_rdata_r} ;
assign dfp_resp  = bmem_ready && ((state_r == R3) || (state_r == W3)) ;

//assign bmem_addr  = {dfp_addr[31:5],5'H00} ;
assign bmem_addr  = dfp_addr & 32'HFFFF_FFE0 ;
assign bmem_read  = ( state_r == IDLE ) && dfp_read ;
assign bmem_write = ( state_r == IDLE ) && dfp_write || (state_r == W1) || (state_r == W2) || (state_r == W3) ;

always_comb
begin
   unique case( state_r )
   W1       : bmem_wdata = dfp_wdata[64*2-1:64*1] ;
   W2       : bmem_wdata = dfp_wdata[64*3-1:64*2] ;
   W3       : bmem_wdata = dfp_wdata[64*4-1:64*3] ;
   default  : bmem_wdata = dfp_wdata[64*1-1:64*0] ;
   endcase
end

endmodule
