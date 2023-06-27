INIT:
	lui  s1, 0xFFFFF # I/O interface base address
    j MAIN

MAIN:
    jal INPUT

    jal DECODE

    j BRANCH_CALC_AND_DISPLAY

INPUT:
	# lw   s0, 0x70(s1)		# read switch
    li s0, 0x0101
    ret

DECODE:
    srli a3, s0, 21
    andi a3, a3, 0x3 # a3 is op

    srli a1, s0, 8
    andi a1, a1, 0xff # a1 is oprand A

    andi a2, s0, 0xff # a2 is oprand B

    ret

DISPLAY_BINARY:
    li t0, 0 # t0: 循环变量
    li t1, 8 # t1: 循环结束
    li t2, 0 # t1: 结果

    DISPLAY_BINARY_LOOP:
    beq t0, t1, DISPLAY_BINARY_END

    srl t3, a0, t0
    andi t3, t3, 0x1

    slli t4, t0, 2 # t4: 4*t0, 左移次数
    sll t3, t3, t4
    or t2, t2, t3

    addi t0, t0, 1
    j DISPLAY_BINARY_LOOP

    DISPLAY_BINARY_END:
    sw t2, 0x00(s1)
    
    j END

DISPLAY_SIGNED:
    # bge a0, zero, DISPLAY_SIGNED_POSITIVE
    sw zero, 0x00(s1)
    
    j END

BRANCH_CALC_AND_DISPLAY:
    beq a3, zero, AND

    li t0, 1
    beq a3, t1, OR
    
    li t0, 2
    beq a3, t1, XOR

    li t0, 3
    beq a3, t1, LSHIFT

    li t0, 4
    beq a3, t1, RSHIFT

    li t0, 5
    beq a3, t1, TENARY

    li t0, 6
    beq a3, t1, DIV

    j END # default

AND:
    and a0, a1, a2
    j DISPLAY_BINARY

OR:
    or a0, a1, a2
    j DISPLAY_BINARY

XOR:
    xor a0, a1, a2
    j DISPLAY_BINARY

LSHIFT:
    sll a0, a1, a2
    j DISPLAY_SIGNED

RSHIFT:
    srl a0, a1, a2
    j DISPLAY_SIGNED

TENARY:
    # (A==0) ? B : B补码
    j DISPLAY_BINARY

DIV:
    j DISPLAY_SIGNED

END:
    j MAIN