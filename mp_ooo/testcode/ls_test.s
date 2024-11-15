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
li x8, 0x1234ABCD
li x9, 0x00010000
sw x8, -20(x9)
sw x8, -24(x9)
sb x8, -21(x9)
sh x8, -22(x9)
lw x7, -20(x9)
lb x7, -21(x9)
lbu x7, -21(x9)
lh x7, -22(x9)
lhu x7, -22(x9)

# these instructions should  resolve before the multiply
add x4, x5, x6
xor x7, x8, x9
sll x10, x11, x12
and x13, x14, x15

halt:
    slti x0, x0, -256
