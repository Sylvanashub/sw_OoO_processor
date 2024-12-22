
//module bht #(
//
//   parameter   BHT_SIZE = 16
//
//) (
//
//    input   logic          clk
//   ,input   logic          rst
//
//   ,input   logic [31:0]   pc
//   ,input   logic          update
//   ,input   logic          taken
//
//   ,output  logic          predict_valid
//   ,output  logic          predict_taken
//
//);
//
//typedef struct {
//   logic valid ;
//   logic taken ;
//} bht_entry_t ;
//
//bht_entry_t entries [BHT_SIZE] ;
//
//genvar i ;
//
//generate
//
//for(i=0;i<BHT_SIZE;i++)
//begin : bht_ent
//
//   always_ff@(posedge clk)
//   begin
//      if( rst )
//      begin
//         entries[i].pc     <= '0 ;
//         entries[i].taken  <= '0 ;
//         entries[i].valid  <= '0 ;
//      end
//      else if( update 
//
//
//endmodule
