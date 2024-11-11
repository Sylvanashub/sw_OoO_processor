`ifndef DATA_HAZARD
`define DATA_HAZARD
`endif
module pipeline
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp
);

logic          idu_opcode_load;
logic          idu_opcode_store;
logic          exu_opcode_store;
logic          exu_opcode_load;
logic          lsu_opcode_load;
logic          lsu_opcode_store;
logic          ifu_valid   ;

logic [31:0]   idu_alu_opa  ;
logic [31:0]   idu_alu_opb  ;
logic [3:0]    idu_aluop    ;
logic [4:0]    idu_rs1_addr ;
logic [4:0]    idu_rs2_addr ;
logic [31:0]   idu_rs1_rdat ;
logic [31:0]   idu_rs2_rdat ;
logic [4:0]    idu_rd_addr  ;
logic          idu_rd_wr    ;
logic          idu_valid    ;

logic          exu_valid    ; 

logic [4:0]    exu_rd_addr  ; 
logic          exu_rd_wr    ; 
logic [31:0]   exu_rd_wdata ; 

logic [4:0]    lsu_rd_addr  ;  
logic          lsu_rd_wr    ;  
logic [31:0]   lsu_rd_wdata ;  
logic          lsu2idu_rd_wr    ;  
logic [31:0]   lsu2idu_rd_wdata ;  

//logic          lsu_valid ;

wire          idu_opcode_ls = idu_opcode_load | idu_opcode_store ;

//logic          load_resp ;

logic [2:0]    idu_funct3 ;
logic [2:0]    exu_funct3 ;
logic [31:0]   idu_dmem_wdata ;
logic          lsu_commit ;
logic [31:0]   idu_rs1_rdata;
logic [31:0]   idu_rs2_rdata;
logic [31:0]   idu_inst ;

logic [31:0]   exu_dmem_addr ;

logic          pc_update ;
logic [31:0]   pc_new ;
logic [31:0]   idu_pc ;

logic          lsu_dmem_resp ;

assign dmem_addr = {exu_dmem_addr[31:2],2'H0};

//ifu u_ifu (
//
//    .clk_i        (  clk         )  //i logic         
//   ,.rst_i        (  rst         )  //i logic         
//   ,.pc_update_i  ( pc_update    )  //i logic         
//   ,.pc_new_i     ( pc_new       )  //i logic [31:0]  
//   ,.imem_addr_o  ( imem_addr    )  //o logic [31:0]  
//   ,.imem_rmask_o ( imem_rmask   )  //o logic [3:0]   
//   ,.imem_resp_i  ( imem_resp    )  //i logic         
//   ,.opcode_ls_i  ( idu_opcode_ls)  //i logic         
//   //,.dmem_resp_i  ( dmem_resp    )  //i logic         
//   ,.dmem_resp_i  ( lsu_dmem_resp    )  //i logic         
//   ,.valid_o      ( ifu_valid    )  //o logic 
//);

wire  is_empty ;
wire  [31:0]   ifu_inst ;
wire  [31:0]   ifu_pc ;
wire [63:0]    dequeue_rdata ;
assign {ifu_pc,ifu_inst} = dequeue_rdata ;

always_ff@(posedge clk)
begin
   if( rst )
      ifu_valid <= '0 ;
   else
      ifu_valid <= ~is_empty ;
end

fetch u_fetch (

    .clk             ( clk )  //i logic         
   ,.rst             ( rst )  //i logic         
   ,.ufp_addr        ( imem_addr )  //o logic   [31:0]
   ,.ufp_rmask       ( imem_rmask )  //o logic   [3:0] 
   ,.ufp_wmask       ()  //o logic   [3:0] 
   ,.ufp_rdata       ( imem_rdata )  //i logic   [31:0]
   ,.ufp_wdata       ()  //o logic   [31:0]
   ,.ufp_resp        ( imem_resp )  //i logic         
   ,.dequeue         ( ~is_empty  )  //i logic         
   ,.is_empty        ( is_empty )  //o logic         
   ,.dequeue_rdata   ( dequeue_rdata )  //o logic   [63:0]

);


idu u_idu (

    .clk_i           ( clk          )  //i logic         
   ,.rst_i           ( rst          )  //i logic         
   ,.imem_addr_i     ( ifu_pc       )  //o logic [31:0]  
   ,.imem_rdata_i    ( ifu_inst     )  //i logic [31:0]  
   ,.imem_resp_i     ( ifu_valid    )  //i logic         
   //,.dmem_resp_i     ( dmem_resp    )  //i logic         
   ,.dmem_resp_i     ( lsu_dmem_resp    )  //i logic         
   ,.alu_opa_o       ( idu_alu_opa  )  //o logic [31:0]  
   ,.alu_opb_o       ( idu_alu_opb  )  //o logic [31:0]  
   ,.aluop_o         ( idu_aluop    )  //o logic [3:0]   
   ,.rs1_addr_o      ( idu_rs1_addr )  //o logic [4:0]   
   ,.rs2_addr_o      ( idu_rs2_addr )  //o logic [4:0]   
   ,.rs1_rdat_i      ( idu_rs1_rdat )  //i logic [31:0]  
   ,.rs2_rdat_i      ( idu_rs2_rdat )  //i logic [31:0]  
   ,.rd_addr_o       ( idu_rd_addr  )  //o logic [4:0]   
   ,.rd_wr_o         ( idu_rd_wr    )  //o logic         

   ,.funct3_o        ( idu_funct3      )
   ,.dmem_wdata_o    ( idu_dmem_wdata  )

   `ifdef DATA_HAZARD
   ,.exu_rd_wr_i     ( exu_rd_wr    )  //i logic         
   ,.exu_rd_addr_i   ( exu_rd_addr  )  //i logic [4:0]   
   ,.exu_rd_wdata_i  ( exu_rd_wdata )  //i logic [31:0]  

   //,.lsu_rd_wr_i     ( lsu_rd_wr    )  //i logic         
   ,.lsu_rd_addr_i   ( lsu_rd_addr  )  //i logic [4:0]   
   //,.lsu_rd_wdata_i  ( lsu_rd_wdata )  //i logic [31:0]
   ,.lsu_rd_wr_i     ( lsu2idu_rd_wr    )  //i logic         
   ,.lsu_rd_wdata_i  ( lsu2idu_rd_wdata )  //i logic [31:0]
   `endif

   ,.opcode_load_o   ( idu_opcode_load)  //o logic         
   ,.opcode_store_o  ( idu_opcode_store)  //o logic         

//   ,.load_resp_i     ( load_resp    )
   ,.valid_i         ( ifu_valid    )  //i logic         
   ,.valid_o         ( idu_valid    )  //o logic         

   ,.rs1_rdata_o     ( idu_rs1_rdata)
   ,.rs2_rdata_o     ( idu_rs2_rdata)
   ,.inst_o          ( idu_inst     )

   ,.pc_update_o     ( pc_update    )  //i logic         
   ,.pc_new_o        ( pc_new       )  //i logic [31:0]  
   ,.pc_o            ( idu_pc       )

);

exu u_exu (

    .clk_i           ( clk          )  //i logic         
   ,.rst_i           ( rst          )  //i logic         
//   ,.imem_resp_i     ( imem_resp    )  //i logic         
   ,.alu_opa_i       ( idu_alu_opa  )  //i logic [31:0]  
   ,.alu_opb_i       ( idu_alu_opb  )  //i logic [31:0]  
   ,.aluop_i         ( idu_aluop    )  //i logic [3:0]   
   ,.rd_addr_i       ( idu_rd_addr  )  //i logic [4:0]   
   ,.rd_wr_i         ( idu_rd_wr    )  //i logic         
   ,.rd_addr_o       ( exu_rd_addr  )  //o logic [4:0]   
   ,.rd_wr_o         ( exu_rd_wr    )  //o logic         
   ,.rd_wdata_o      ( exu_rd_wdata )  //o logic [31:0]  
   ,.funct3_i        ( idu_funct3   )
   ,.funct3_o        ( exu_funct3   )

   ,.dmem_wdata_i    ( idu_dmem_wdata           )  //i logic [31:0]  
   ,.dmem_addr_o     ( exu_dmem_addr    )  //o logic [31:0]  
   ,.dmem_wdata_o    ( dmem_wdata   )  //o logic [31:0]  
   ,.dmem_wmask_o    ( dmem_wmask   )  //o logic [3:0]   
   ,.dmem_rmask_o    ( dmem_rmask   )  //o logic [3:0]   

   ,.opcode_load_i   ( idu_opcode_load)  //o logic         
   ,.opcode_store_i  ( idu_opcode_store)  //o logic         
   ,.opcode_load_o   ( exu_opcode_load)  //o logic         
   ,.opcode_store_o  ( exu_opcode_store)  //o logic         



   ,.valid_i         ( idu_valid    )  //o logic         
   ,.valid_o         ( exu_valid    )  //o logic         

);


lsu u_lsu (

    .clk_i           ( clk          )  //i logic         
   ,.rst_i           ( rst          )  //i logic         
//   ,.load_en_i       ( 1'H0         )  //i logic
   ,.dmem_addr_i     ( exu_dmem_addr[1:0])
   ,.dmem_resp_i     ( dmem_resp    )  //i logic         
   ,.dmem_rdata_i    ( dmem_rdata   )  //i logic [31:0]
   ,.lsu_dmem_resp_o     ( lsu_dmem_resp    )  //i logic         
   ,.rd_addr_i       ( exu_rd_addr  )  //i logic [4:0]   
   ,.rd_wr_i         ( exu_rd_wr    )  //i logic         
   ,.rd_wdata_i      ( exu_rd_wdata )  //i logic [31:0]  
   ,.rd_addr_o       ( lsu_rd_addr  )  //o logic [4:0]   
   ,.rd_wr_o         ( lsu_rd_wr    )  //o logic         
   ,.rd_wdata_o      ( lsu_rd_wdata )  //o logic [31:0]  
   ,.lsu2idu_rd_wr_o         ( lsu2idu_rd_wr    )  //o logic         
   ,.lsu2idu_rd_wdata_o      ( lsu2idu_rd_wdata )  //o logic [31:0]  
   ,.funct3_i        ( exu_funct3   )
   ,.opcode_load_i   ( exu_opcode_load)  //o logic         
   ,.opcode_store_i  ( exu_opcode_store)  //o logic         

//   ,.load_resp_o     ( load_resp )

   ,.valid_i      ( exu_valid    )  //o logic         
//   ,.valid_o      ( lsu_valid    )  //o logic         
   ,.commit       ( lsu_commit   )
);

regfile u_regfile (

    .clk       ( clk          )  //i logic          
   ,.rst       ( rst          )  //i logic          
   ,.regf_we   ( lsu_rd_wr    )  //i logic          
   ,.rd_v      ( lsu_rd_wdata )  //i logic   [31:0] 
   ,.rd_s      ( lsu_rd_addr  )  //i logic   [4:0]  
   ,.rs1_s     ( idu_rs1_addr )  //i logic   [4:0]  
   ,.rs2_s     ( idu_rs2_addr )  //i logic   [4:0]  
   ,.rs1_v     ( idu_rs1_rdat )  //o logic   [31:0] 
   ,.rs2_v     ( idu_rs2_rdat )  //o logic   [31:0] 

);


//`ifdef SIM

logic [31:0]   InstAry [2] ;

logic [4:0]    rs1_addr_ary [2] ;
logic [4:0]    rs2_addr_ary [2] ;
logic [31:0]   rs1_rdata_ary [2] ;
logic [31:0]   rs2_rdata_ary [2] ;

logic          mon_valid ;
logic [31:0]   mon_inst ;
logic [63:0]   mon_order ;
logic [4:0]    mon_rs1_addr ;
logic [4:0]    mon_rs2_addr ;
logic [31:0]   mon_rs1_rdata ;
logic [31:0]   mon_rs2_rdata ;
logic [4:0]    mon_rd_addr ;
logic [31:0]   mon_rd_wdata;
logic [31:0]   mon_pc_rdata ;
logic [31:0]   mon_pc_wdata;
logic          mon_halt ;

logic [31:0]   mon_mem_addr  ;
logic [3:0]    mon_mem_rmask ;
logic [3:0]    mon_mem_wmask ;
logic [31:0]   mon_mem_wdata ;
logic [31:0]   mon_mem_rdata ;

assign mon_mem_rdata = dmem_rdata ;
always_ff@(posedge clk)
begin
   if( rst )
   begin
      mon_mem_addr  <= '0 ;
      mon_mem_rmask <= '0 ;
      mon_mem_wmask <= '0 ;
      mon_mem_wdata <= '0 ;
 //     mon_mem_rdata <= '0 ;
   end
   else if( exu_valid && ( exu_opcode_load || exu_opcode_store ) )
   begin
      mon_mem_addr  <= dmem_addr ;
      mon_mem_rmask <= dmem_rmask ;
      mon_mem_wmask <= dmem_wmask ;
      mon_mem_wdata <= dmem_wdata ;
   end
   else if( dmem_resp)
   begin
      mon_mem_addr  <= '0 ;
      mon_mem_rmask <= '0 ;
      mon_mem_wmask <= '0 ;
      mon_mem_wdata <= '0 ;

   end
end


always_ff@(posedge clk)
begin
   if( rst )
   begin
      for(int i=0;i<2;i++)
      begin
      rs1_addr_ary [i] <= '0 ;
      rs2_addr_ary [i] <= '0 ;
      rs1_rdata_ary[i] <= '0 ;
      rs2_rdata_ary[i] <= '0 ;
      end

   end
   //else if( idu_valid )
   //else if( ~(u_lsu.opc_load_r | u_lsu.opc_store_r) | dmem_resp )
   //begin
   //   rs1_addr_ary  <= {idu_rs1_addr,rs1_addr_ary[0]} ;
   //   rs2_addr_ary  <= {idu_rs2_addr,rs2_addr_ary[0]} ;
   //   rs1_rdata_ary <= {u_idu.rs1_rdata,rs1_rdata_ary[0]} ;
   //   rs2_rdata_ary <= {u_idu.rs2_rdata,rs2_rdata_ary[0]} ;
   //end
   else
   begin
      if( idu_valid )
      begin
      rs1_addr_ary [0] <= idu_rs1_addr ;
      rs2_addr_ary [0] <= idu_rs2_addr ;
      rs1_rdata_ary[0] <= idu_rs1_rdata;
      rs2_rdata_ary[0] <= idu_rs2_rdata;
      end
      if( exu_valid )
      begin
      rs1_addr_ary [1] <= rs1_addr_ary[0] ;
      rs2_addr_ary [1] <= rs2_addr_ary[0] ;
      rs1_rdata_ary[1] <= rs1_rdata_ary[0] ;
      rs2_rdata_ary[1] <= rs2_rdata_ary[0] ;
      end
   end
end



always_ff@(posedge clk)
begin
   if( rst )
   begin
      mon_order <= '0 ;
   end
   else if( mon_valid )
   begin
      mon_order <= mon_order + 1;
   end
end

logic [31:0]   idu_pc_cur ;
logic [31:0]   idu_pc_nxt ;
logic [31:0]   exu_pc_cur ;
logic [31:0]   exu_pc_nxt ;

always@(posedge clk)
begin
   if( rst )
   begin
      InstAry[0] <= '0 ;
      InstAry[1] <= '0 ;
      idu_pc_cur <= 32'H1ECE_B000 ;
      exu_pc_cur <= '0 ;
   end
   else
   begin
      if( idu_valid ) 
      begin
         InstAry[0] <= idu_inst ;
         idu_pc_cur <= idu_pc ;
         idu_pc_nxt <= pc_update ? pc_new : (idu_pc + 4) ;
      end
      if( exu_valid ) 
      begin
         InstAry[1] <= InstAry[0] ;
         exu_pc_cur <= idu_pc_cur ;
         exu_pc_nxt <= idu_pc_nxt ;
      end
   end
end

assign mon_valid = lsu_commit ;
assign mon_inst  = InstAry[1] ;

assign mon_rs1_addr  = rs1_addr_ary [1] ;
assign mon_rs2_addr  = rs2_addr_ary [1] ;
assign mon_rs1_rdata = rs1_rdata_ary[1] ;
assign mon_rs2_rdata = rs2_rdata_ary[1] ;

assign mon_rd_addr = lsu_rd_addr ;
assign mon_rd_wdata= lsu_rd_wdata;
assign mon_pc_rdata= exu_pc_cur ;
assign mon_pc_wdata= exu_pc_nxt ;
assign mon_halt = mon_inst == 32'HF0002013 ;
//`endif

endmodule : pipeline
