const ALU_RVS_ENT_NUM	= 4
const MDU_RVS_ENT_NUM	= 4
const LSU_RVS_ENT_NUM	= 4
const JMP_RVS_ENT_NUM	= 4

const ALU_TAG_START	= 1
const MDU_TAG_START	= ALU_TAG_START + ALU_RVS_ENT_NUM
const LSU_TAG_START	= MDU_TAG_START + MDU_RVS_ENT_NUM
const JMP_TAG_START	= LSU_TAG_START + LSU_RVS_ENT_NUM
const INST_ORDER_MAX	= 100

function update_table_cell ( iTableID , iRow , iCol , strText ){

	$( '#'+iTableID+' tbody tr:eq('+iRow+') td:eq('+iCol+')').text( strText )

}

function reset_inst_buffer_tb () {

	for( let i =0;i<16;i++) {

		update_table_cell('inst_buffer_tb',i,0,i)
		update_table_cell('inst_buffer_tb',i,1,'-')
		update_table_cell('inst_buffer_tb',i,2,'-')

	}

}

function reset_rob_tb () {

	for( let i =0;i<16;i++) {

		update_table_cell('rob_tb',i,0,i)
		update_table_cell('rob_tb',i,1,'0x00000000')
		update_table_cell('rob_tb',i,2,'0x00000000')
		update_table_cell('rob_tb',i,3,'none')
		update_table_cell('rob_tb',i,4,'0')
		update_table_cell('rob_tb',i,5,'0')
		update_table_cell('rob_tb',i,6,'0')

	}

}

function reset_register_tb () {

	for( let i =0;i<32;i++) {

		update_table_cell('register_tb',i,0,i)
		update_table_cell('register_tb',i,1,'0x00000000')
		update_table_cell('register_tb',i,2,'1')
		update_table_cell('register_tb',i,3,'0')

	}

}

function reset_alu_rvs_tb () {

	for( let i =0;i<ALU_RVS_ENT_NUM;i++) {

		update_table_cell('alu_rs_tb',i,0,i+ALU_TAG_START)
		update_table_cell('alu_rs_tb',i,1,'0')
		update_table_cell('alu_rs_tb',i,2,'0x00000000')
		update_table_cell('alu_rs_tb',i,3,'0')
		update_table_cell('alu_rs_tb',i,4,'0x00000000')

	}

}

function reset_mdu_rvs_tb () {

	for( let i =0;i<MDU_RVS_ENT_NUM;i++) {

		update_table_cell('mdu_rs_tb',i,0,i+MDU_TAG_START)
		update_table_cell('mdu_rs_tb',i,1,'0')
		update_table_cell('mdu_rs_tb',i,2,'0x00000000')
		update_table_cell('mdu_rs_tb',i,3,'0')
		update_table_cell('mdu_rs_tb',i,4,'0x00000000')

	}

}

function reset_lsu_rvs_tb () {

	for( let i =0;i<LSU_RVS_ENT_NUM;i++) {

		update_table_cell('lsu_rs_tb',i,0,i+LSU_TAG_START)
		update_table_cell('lsu_rs_tb',i,1,'0')
		update_table_cell('lsu_rs_tb',i,2,'0x00000000')
		update_table_cell('lsu_rs_tb',i,3,'0')
		update_table_cell('lsu_rs_tb',i,4,'0x00000000')

	}

}

function reset_jmp_rvs_tb () {

	for( let i =0;i<JMP_RVS_ENT_NUM;i++) {

		update_table_cell('jmp_rs_tb',i,0,i+JMP_TAG_START)
		update_table_cell('jmp_rs_tb',i,1,'0')
		update_table_cell('jmp_rs_tb',i,2,'0x00000000')
		update_table_cell('jmp_rs_tb',i,3,'0')
		update_table_cell('jmp_rs_tb',i,4,'0x00000000')

	}

}

function reset_all_tb () {
	reset_inst_buffer_tb();

	reset_alu_rvs_tb();
	reset_mdu_rvs_tb();
	reset_lsu_rvs_tb();
	reset_jmp_rvs_tb();

	reset_rob_tb();
	reset_register_tb();
}

let giInstOrder = 0 ;


function update_inst_buffer_tb () {

	for( let i =0;i<16;i++) {

		update_table_cell('inst_buffer_tb',i,1,inst_buffer_ary[giInstOrder][i][0])
		update_table_cell('inst_buffer_tb',i,2,inst_buffer_ary[giInstOrder][i][1])
		update_table_cell('inst_buffer_tb',i,3,inst_buffer_ary[giInstOrder][i][2])

	}

}

function update_rob_buffer_tb () {

	for( let i =0;i<16;i++) {

		for( let j=0;j<7;j++) {
			update_table_cell('rob_tb',i,j+1,rob_ary[giInstOrder][i][j])
		}

	}

}

function update_register_tb () {

	for( let i =0;i<32;i++) {

		for( let j=0;j<3;j++) {
			update_table_cell('register_tb',i,j+1,gpr_ary[giInstOrder][i][j])
		}

	}

}

function update_rvs_tb () {

	for( let i =0;i<4;i++) {

		for( let j=0;j<5;j++) {

			update_table_cell('alu_rs_tb',i,j+1,alu_rvs_ary[giInstOrder][i][j])
			update_table_cell('mdu_rs_tb',i,j+1,mdu_rvs_ary[giInstOrder][i][j])
			update_table_cell('lsu_rs_tb',i,j+1,lsu_rvs_ary[giInstOrder][i][j])
			update_table_cell('jmp_rs_tb',i,j+1,jmp_rvs_ary[giInstOrder][i][j])
		}

	}

}

function update_dec_tb () {

	const inst = parseInt(dec_ary[giInstOrder][0],16);

	let decode = decodeRISCv32i(inst);
	let binary = inst.toString(2).padStart(32,'0');

	update_table_cell('dec_tb',0,1,decode.opcode.toString(16));
	update_table_cell('dec_tb',1,1,decode.rs1)   ;
	update_table_cell('dec_tb',2,1,decode.rs2)   ;
	update_table_cell('dec_tb',3,1,decode.rd)    ;
	update_table_cell('dec_tb',4,1,decode.funct3);
	update_table_cell('dec_tb',5,1,decode.funct7);
	update_table_cell('dec_tb',6,1,decode.imm)   ;

	update_table_cell('dec_tb',0,3,decode.instruction)			;
	update_table_cell('dec_tb',1,3,binary)                  ;
	update_table_cell('dec_tb',2,3,dec_ary[giInstOrder][0]) ;
	update_table_cell('dec_tb',3,3,decode.type)             ;
	update_table_cell('dec_tb',4,3,"")                      ;
	update_table_cell('dec_tb',5,3,"")                      ;
	update_table_cell('dec_tb',6,3,dec_ary[giInstOrder][1]) ;

}

function update_all_tb () {
	
	$('#inpInstOrder').val(giInstOrder) ;

	update_inst_buffer_tb();
	update_rob_buffer_tb();
	update_register_tb();
	update_rvs_tb();
	update_dec_tb ();
}

function step_forward() {

	if( giInstOrder < INST_ORDER_MAX ){
		giInstOrder++ ;
	}

	update_all_tb();


}

function step_backward() {


	if( giInstOrder > 0 ){
		giInstOrder-- ;
	}

	update_all_tb();


}

$(document).ready(function() {

	reset_all_tb();

});
	

