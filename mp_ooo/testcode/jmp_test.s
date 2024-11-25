ooo_test.s:
.align 4
.section .text
.globl _start
    # This program will provide a simple test for
    # demonstrating OOO-ness

    # This test is NOT exhaustive
_start:

# initialize
li x1, 10
li x2, 20
li x5, 50
li x6, 60
li x8, 21
li x9, 28
li x11, 8
li x12, 4
li x14, 3
li x15, 1

# this should take many cycles
# if this writes back to the ROB after the following instructions, you get credit for CP2

li x8, 0x10
bgt x8,x12, _start+0x58
#j _start+0x58
li x1, 0x00010001
li x2, 0x00010002
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15
li x3, 0x00010003
li x4, 0x00010004
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15
#jal _start+0xa0
li x5, 0x00010005
li x6, 0x00010006
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15
li x7, 0x00010007
li x8, 0x00010008
li x9, 0x00010009
li x9, 0x000100A0

# these instructions should  resolve before the multiply
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15

halt:
    slti x0, x0, -256
