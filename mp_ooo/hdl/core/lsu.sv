
module lsu 
import rv32i_types::*;
#(

    parameter  TAG_W       = 32'D4  

   ,parameter  ROB_DEPTH   = 32'D16
   ,parameter  ROB_PTR_W   = $clog2(ROB_DEPTH)

   ,parameter  DEPTH       = 4
   ,parameter  PTR_W       = $clog2(DEPTH)

) 
(

    input   logic    clk
   ,input   logic    rst

   ,rvs2exu_itf.exu  rvs2lsu_itf

   ,exu2cdb_itf.exu  lsu2cdb_itf

   ,rob2lsu_itf.lsu  rob2lsu_itf

   ,output  logic [31:0]   dmem_addr
   ,output  logic [3:0]    dmem_rmask
   ,output  logic [3:0]    dmem_wmask
   ,input   logic [31:0]   dmem_rdata
   ,output  logic [31:0]   dmem_wdata
   ,input   logic          dmem_resp 

);

localparam  IDLE  = 2'H0 ;
localparam  LOAD  = 2'H1 ;
localparam  STORE = 2'H2 ;

typedef struct {

   logic                   valid    ;
   logic [3:0]             opc      ;
   logic [TAG_W-1:0]       tag      ;
   logic [31:0]            addr     ;
   logic [31:0]            wdata    ;
   logic [ROB_PTR_W-1:0]   inst_id  ;

} lsq_type ;

lsq_type lsq_entries [DEPTH] ;
logic [PTR_W:0]   wptr     ;
logic [PTR_W:0]   rptr     ;
logic             is_full  ;
logic             is_empty ;
logic             lsq_wr   ;
logic             lsq_rd   ;

logic [1:0] state_r ;
logic [1:0] state_nxt ;

wire _x = lsu2cdb_itf.rdy | rvs2lsu_itf.predict_valid | rvs2lsu_itf.predict_taken ;
//logic       wr_vld ;
//logic       rd_vld ;
//
//assign wr_vld = rvs2lsu_itf.req && rvs2lsu_itf.rdy ;
//assign rd_vld = lsu2cdb_itf.req && lsu2cdb_itf.rdy ;

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
   unique case( state_r )
   IDLE : 
   begin
      if( lsq_rd )
         state_nxt = lsq_entries[rptr[PTR_W-1:0]].opc[3] ? STORE : LOAD ;
   end
   LOAD :
   begin
      if( dmem_resp )
         state_nxt = IDLE ;
   end
   STORE :
   begin
      if( dmem_resp )
         state_nxt = IDLE ;
   end
   default :
   begin
      state_nxt = state_r ;
   end
   endcase
end

logic [31:0] lsq_addr ;
assign lsq_addr = rvs2lsu_itf.src1 + {{20{rvs2lsu_itf.offset[11]}},rvs2lsu_itf.offset} ;

genvar i ;
generate
for(i=0;i<DEPTH;i++)
begin : item
   always_ff@(posedge clk)
   begin
      if( rst )
      begin
         lsq_entries[i].valid    <= '0 ;
         lsq_entries[i].opc      <= '0 ;
         lsq_entries[i].tag      <= '0 ;
         lsq_entries[i].addr     <= '0 ;
         lsq_entries[i].wdata    <= '0 ;
         lsq_entries[i].inst_id  <= '0 ;
      end
      else if( lsq_wr && wptr[PTR_W-1:0] == i[PTR_W-1:0] )
      begin
         lsq_entries[i].valid    <= '1 ;
         lsq_entries[i].opc      <= rvs2lsu_itf.opc      ;
         lsq_entries[i].tag      <= rvs2lsu_itf.tag      ;
         lsq_entries[i].addr     <= lsq_addr             ;
         lsq_entries[i].wdata    <= rvs2lsu_itf.src2     ;
         lsq_entries[i].inst_id  <= rvs2lsu_itf.inst_id  ;
      end
      else if( lsq_rd && rptr[PTR_W-1:0] == i[PTR_W-1:0] )
      begin
         lsq_entries[i].valid    <= '0 ;
      end
   end
end
endgenerate


assign lsq_wr = rvs2lsu_itf.req && rvs2lsu_itf.rdy ;
assign lsq_rd =  lsq_entries[rptr[PTR_W-1:0]].valid && state_r == IDLE &&
                  rob2lsu_itf.inst_id == lsq_entries[rptr[PTR_W-1:0]].inst_id ;

always_ff@(posedge clk)
begin
   if( rst )
      wptr <= '0 ;
   else if( lsq_wr && ~is_full )
      wptr <= wptr + 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rptr <= '0 ;
   else if( lsq_rd && ~is_empty )
      rptr <= rptr + 1'H1 ;
end

wire catch_up = wptr[PTR_W-1:0] == rptr[PTR_W-1:0] ;
wire extra_eq = wptr[PTR_W] == rptr[PTR_W] ;
assign is_full  = ~extra_eq && catch_up ;
assign is_empty = extra_eq && catch_up ;

assign rvs2lsu_itf.rdy = ~is_full ;


//------------------------------------------------------------------------------
// cdb interface
//------------------------------------------------------------------------------
logic [31:0]            cdb_wdata   ;
logic [3:0]             cdb_opc     ;
//assign dmem_addr  = {lsq_entries[rptr[PTR_W-1:0]].addr[31:2],2'H0} ;
assign dmem_addr  = lsq_entries[rptr[PTR_W-1:0]].addr ;
logic [1:0] baddr  ;//= lsq_entries[rptr[PTR_W-1:0]].addr[1:0] ;
logic [1:0] baddr_nxt ;
assign baddr_nxt = lsq_entries[rptr[PTR_W-1:0]].addr[1:0] ;
always_ff@(posedge clk)
begin
   if( rst )
   begin
      cdb_opc              <= '0 ;
      lsu2cdb_itf.tag      <= '0 ;
      lsu2cdb_itf.inst_id  <= '0 ;
      baddr                <= '0 ;
   end
   else if( lsq_rd && ~is_empty )
   begin
      cdb_opc              <= lsq_entries[rptr[PTR_W-1:0]].opc ;
      lsu2cdb_itf.tag      <= lsq_entries[rptr[PTR_W-1:0]].tag ;
      lsu2cdb_itf.inst_id  <= lsq_entries[rptr[PTR_W-1:0]].inst_id ;
      baddr                <= lsq_entries[rptr[PTR_W-1:0]].addr[1:0] ;
   end
end

logic [31:0] cdb_wdata_r ;
always_ff@(posedge clk)
begin
   if( rst )
      cdb_wdata_r <= '0 ;
   else if( dmem_resp )
      cdb_wdata_r <= cdb_wdata ;
end



always_comb
begin
   unique case( cdb_opc )
      lsu_op_lb   : cdb_wdata = {{24{dmem_rdata[7 +8 *baddr[1:0]]}}, dmem_rdata[8 *baddr[1:0] +: 8 ]};
      lsu_op_lbu  : cdb_wdata = {{24{1'b0}}                          , dmem_rdata[8 *baddr[1:0] +: 8 ]};
      lsu_op_lh   : cdb_wdata = {{16{dmem_rdata[15+16*baddr[1]  ]}}, dmem_rdata[16*baddr[1]   +: 16]};
      lsu_op_lhu  : cdb_wdata = {{16{1'b0}}                          , dmem_rdata[16*baddr[1]   +: 16]};
      lsu_op_lw   : cdb_wdata = dmem_rdata;
      default     : cdb_wdata = '0;
   endcase
end

logic req_r ;
always_ff@(posedge clk)
begin
   if( rst )
      req_r <= '0 ;
   else 
      req_r <= lsu2cdb_itf.req && ~lsu2cdb_itf.rdy ;
end


//store also need cdb to write tag to flag that store instruction is done
//assign lsu2cdb_itf.req     = req_r || ((state_r == LOAD || state_r == STORE) && dmem_resp) ;
assign lsu2cdb_itf.req     = req_r || ((state_r == LOAD && dmem_resp) || state_r == STORE ) ;
//assign lsu2cdb_itf.tag     = lsq_entries[rptr[PTR_W-1:0]].tag ;
assign lsu2cdb_itf.wdata   = req_r ? cdb_wdata_r : cdb_wdata ;
//assign lsu2cdb_itf.inst_id = lsq_entries[rptr[PTR_W-1:0]].inst_id ;

//------------------------------------------------------------------------------
// dmem interface
//------------------------------------------------------------------------------


always_comb
begin
   dmem_wdata = '0 ;
   unique case ( lsq_entries[rptr[PTR_W-1:0]].opc )
      lsu_op_sb: dmem_wdata[8 *baddr_nxt[1:0] +: 8 ] = lsq_entries[rptr[PTR_W-1:0]].wdata[7 :0];
      lsu_op_sh: dmem_wdata[16*baddr_nxt[1]   +: 16] = lsq_entries[rptr[PTR_W-1:0]].wdata[15:0];
      lsu_op_sw: dmem_wdata = lsq_entries[rptr[PTR_W-1:0]].wdata;
      default  : dmem_wdata = '0;
   endcase
end

always_comb
begin
   if( lsq_rd && ~lsq_entries[rptr[PTR_W-1:0]].opc[3] )
   begin
      unique case( lsq_entries[rptr[PTR_W-1:0]].opc )
      lsu_op_lb   , 
      lsu_op_lbu  : dmem_rmask = 4'H1<<baddr_nxt[1:0] ;
      lsu_op_lh   ,
      lsu_op_lhu  : dmem_rmask = baddr_nxt[1] ? 4'B1100 : 4'B0011 ;
      lsu_op_lw   : dmem_rmask = '1 ;
      default     : dmem_rmask = '0 ;
      endcase
      //dmem_rmask = '1 ;
   end
   else
   begin
      dmem_rmask = '0 ;
   end
end

always_comb
begin
   if( lsq_rd )
   begin
      unique case( lsq_entries[rptr[PTR_W-1:0]].opc )
      lsu_op_sb   : dmem_wmask = 4'H1<<baddr_nxt[1:0] ;
      lsu_op_sh   : dmem_wmask = baddr_nxt[1] ? 4'B1100 : 4'B0011 ;
      lsu_op_sw   : dmem_wmask = '1 ;
      default     : dmem_wmask = '0 ;
      endcase
   end
   else
   begin
      dmem_wmask = '0 ;
   end
end

endmodule
