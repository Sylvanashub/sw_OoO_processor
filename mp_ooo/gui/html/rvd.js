
function decodeRISCv32i(instruction) {
    
    let binary = instruction.toString(2).padStart(32, '0');
    
   
    const opcode = binary.slice(25); // opcode -
    const rd = parseInt(binary.slice(20, 25), 2); // rd -
    const funct3 = binary.slice(17, 20); // funct3 -
    const funct7 = binary.slice(0,7); // funct3 -
    const rs1 = parseInt(binary.slice(12, 17), 2); // rs1
    const rs2 = parseInt(binary.slice(7, 12), 2); // rs2
    const imm = parseInt(binary.slice(0, 12), 2); // immed

    let decoded = {
        opcode: opcode,
        rd: rd,
        rs1: rs1,
        rs2: rs2,
        imm: imm,
        funct3: funct3,
        funct7: funct7
    };

    //
    switch (opcode) {

	case '0110111':
	decoded.type = 'U-type' ;
	decoded.instruction = 'lui' ;
        decoded.instruction += " x"+rd+","
        decoded.instruction += " imm(pc)"

	break;
	case '0010111':
	decoded.type = 'U-type' ;
	decoded.instruction = 'auipc' ;
        decoded.instruction += " x"+rd+","
        decoded.instruction += " imm(pc)"
	break;
	case '1101111':
	decoded.type = 'J-type' ;
	decoded.instruction = 'jal' ;
        decoded.instruction += " x"+rd+","
        decoded.instruction += " imm(pc)"
	break;
	case '1100111':
	decoded.type = 'I-type' ;
	decoded.instruction = 'jalr' ;
        decoded.instruction += " x"+rd+","
        decoded.instruction += " imm(x"+rs1+")"
	break;

        case '0000011': //LOAD
            decoded.type = 'I-type';
            decoded.instruction = decodeIType(funct3);
            decoded.instruction += " x"+rd+","
            decoded.instruction += " @imm(x"+rs1+")"
            decoded.imm = imm;
            break;

        case '0100011': //Store
            decoded.type = 'S-type';
            decoded.instruction = decodeSType(funct3);
            decoded.instruction += " @imm(x"+rs1+"),"
            decoded.instruction += " x"+rs2+","
            decoded.imm = imm;
            break;
        case '1100011': //
            decoded.type = 'B-type';
            decoded.instruction = decodeBType(funct3);
            decoded.instruction += " x"+rs1+","
            decoded.instruction += " x"+rs2+","
            decoded.instruction += " imm(pc)"
            break;
        case '0010011': // IMM
            decoded.type = 'I-type';
            decoded.instruction = decode_imm(funct3,funct7);
            decoded.instruction += " x"+rd+","
            decoded.instruction += " x"+rs1+","
            decoded.instruction += " imm"
            break;
        case '0110011': // REG
            decoded.type = 'R-type';
            decoded.instruction = decodeRType(funct3,funct7);
            decoded.instruction += " x"+rd+","
            decoded.instruction += " x"+rs1+","
            decoded.instruction += " x"+rs2
            break;

        //
        default:
            decoded.type = 'Unknown';
            break;
    }

    return decoded;
}

//
function decodeRType(funct3,funct7) {
    switch (funct3) {
        case '000': return 'add';
        case '001': return 'sll';
        case '010': return 'slt';
        case '011': return 'sltu';
        case '100': return 'xor';
        case '101': 
	switch (funct7 ){
	case '0000000' : return 'srl';
	case '0100000' : return 'sra';
	default : return 'xxx' ;
	}
        case '110': return 'or';
        case '111': return 'and';
        default: return 'Unknown R-type';
    }
}

//
function decodeIType(funct3) {
    switch (funct3) {
        case '000': return 'lb';
        case '001': return 'lh';
        case '010': return 'lw';
        case '100': return 'lbu';
        case '101': return 'lhu';
        default: return 'Unknown I-type';
    }
}

function decodeSType(funct3) {
    switch (funct3) {
        case '000': return 'sb';
        case '001': return 'sh';
        case '010': return 'sw';
        default: return 'Unknown S-type';
    }
}

//
function decodeBType(funct3) {
    switch (funct3) {
        case '000': return 'beq';
        case '001': return 'bne';
        case '100': return 'blt';
        case '101': return 'bge';
        case '110': return 'bltu';
        case '111': return 'bgeu';
        default: return 'Unknown B-type';
    }
}

function decode_imm(funct3,funct7) {
    switch (funct3) {
        case '000': return 'addi';
        case '001': return 'slli';
        case '010': return 'slti';
        case '011': return 'sltiu';
        case '100': return 'xori';
        case '101': 
		switch(funct7) {
		case '0000000' : return 'srli';
		case '0100000' : return 'srai';
		default		: return 'xxx' ;
		}
        case '110': return 'ori';
        case '111': return 'andi';
        default: return 'Unknown B-type';
    }
}
