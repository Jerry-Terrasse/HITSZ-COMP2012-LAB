INIT:
	lui  s1, 0xFFFFF # I/O interface base address
    j MAIN

MAIN:
    jal INPUT

    jal DECODE

    j BRANCH_CALC_AND_DISPLAY

INPUT:
	lw   s0, 0x70(s1)		# read switch
    # li s0, 0x200903 # 9 | 3
    # li s0, 0x600903 # 9 << 3
    # li s0, 0x608103 # -1 << 3
    # li s0, 0xa00983 # [-3]补
    # li s0, 0xc00b03 # 11 / 3
    # li s0, 0xc01202 # 18 / 2
    # li s0, 0xc01206 # 18 / 6
    ret

DECODE:
    srli a3, s0, 21
    andi a3, a3, 0x7 # a3 is op

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
    andi t6, a0, 0x80 # t6: a0的符号位
    andi t0, a0, 0x7f # a0: a0的绝对值

    beq t6, zero, DISPLAY_SIGNED_END # a0为正数
    slli t6, t6, 4 # t6 <- 0x800
    or t0, t0, t6 # 添一位8表示负数

    DISPLAY_SIGNED_END:
    sw t0, 0x00(s1)

    j END

DISPLAY_QR: # Quotient and Remainder
    andi t6, a0, 0x80 # t6: a0的符号位
    andi t0, a0, 0x7f # a0: a0的绝对值

    beq t6, zero, DISPLAY_QR_END1 # a0为正数
    slli t6, t6, 4 # t6 <- 0x800
    or t0, t0, t6 # 添一位8表示负数

    DISPLAY_QR_END1:

    andi t6, a4, 0x80 # t6: a4的符号位
    andi t1, a4, 0x7f # a4: a4的绝对值
    slli t1, t1, 16

    beq t6, zero, DISPLAY_QR_END2 # a4为正数
    slli t6, t6, 20 # t6 <- 0x8000000
    or t1, t1, t6 # 添一位8表示负数

    DISPLAY_QR_END2:
    or t0, t0, t1 # 组合商和余数

    sw t0, 0x00(s1)

    j END

BRANCH_CALC_AND_DISPLAY:
    beq a3, zero, AND

    li t0, 1
    beq a3, t0, OR
    
    li t0, 2
    beq a3, t0, XOR

    li t0, 3
    beq a3, t0, LSHIFT

    li t0, 4
    beq a3, t0, RSHIFT

    li t0, 5
    beq a3, t0, TENARY

    li t0, 6
    beq a3, t0, DIV

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
    andi t6, a1, 0x80 # t6: a1的符号位
    andi a0, a1, 0x7f # a1: a1的绝对值
    sll a0, a0, a2
    or a0, a0, t6 # 恢复符号位
    j DISPLAY_SIGNED

RSHIFT:
    andi t6, a1, 0x80 # t6: a1的符号位
    andi a0, a1, 0x7f # a1: a1的绝对值
    sra a0, a0, a2
    or a0, a0, t6 # 恢复符号位
    j DISPLAY_SIGNED

TENARY:
    # (A==0) ? B : B补码
    or a0, a2, zero # a0 = B
    beq a1, zero, DISPLAY_BINARY

    # 原码转补码
    andi t6, a0, 0x80 # t6: 符号位
    beq t6, zero, DISPLAY_BINARY # B>=0, 补码=原码

    andi a0, a0, 0x7f # 去掉符号位
    not a0, a0 # 取反
    addi a0, a0, 1 # 加1
    j DISPLAY_BINARY

DIV:
    ori a0, zero, 0 # a0: 结果
    or a4, zero, a1 # a4: 余数
    beq a2, zero, DISPLAY_QR # 除数为0

    xor t6, a1, a2 # t6: 符号位
    andi t6, t6, 0x80
    andi t3, a1, 0x80 # t3: 被除数符号位

    andi t1, a1, 0x7f # A绝对值, t1: 余数
    andi t2, a2, 0x7f # B绝对值

    blt t1, t2, DISPLAY_QR # A<B, 结果为0

    li t5, 0x40 # t5: 0100 0000 用来判断最高位
    # 将被除数左移至最高位
    ori t4, zero, 0 # 保存左移次数，用于复原余数
    DIV_LOOP1:
    bge t1, t5, DIV_END1 # 被除数最高位为1
    slli t1, t1, 1
    slli t2, t2, 1 # 除数同步左移
    addi t4, t4, 1
    j DIV_LOOP1
    DIV_END1:

    # 将除数左移至最高位
    ori t0, zero, 0 # t0: 循环变量，记录左移次数，同时也是初次商的位置
    DIV_LOOP2:
    bge t2, t5, DIV_END2 # 除数最高位为1
    slli t2, t2, 1
    addi t0, t0, 1
    j DIV_LOOP2
    DIV_END2:

    # 进行除法
    DIV_LOOP3:
    blt t0, zero, DIV_LOOP3_END # 循环结束

    sub t1, t1, t2 # 余数减去除数
    slli a0, a0, 1 # 商左移1位
    blt t1, zero, DIV_GOT_0 # 余数小于0，商0，恢复余数

    # 余数大于等于0，商1
    ori a0, a0, 1 # 商1
    j DIV_LOOP3_NXT

    # 余数小于0，商0，恢复余数
    DIV_GOT_0:
    add t1, t1, t2
    
    DIV_LOOP3_NXT:
    srli t2, t2, 1 # 除数右移1位
    addi t0, t0, -1 # 循环变量减1
    j DIV_LOOP3

    DIV_LOOP3_END:
    # 商的符号位
    or a0, a0, t6
    srl a4, t1, t4 # a4: 余数，右移t4位，恢复余数
    or a4, a4, t3 # a4: 余数，恢复符号位

    j DISPLAY_QR

# DIV_BACKUP:
#     # 加减交替法
#     ori a0, zero, 0 # a0: 结果
#     beq a2, zero, DISPLAY_SIGNED # 除数为0

#     xor t6, a1, a2 # t6: 符号位
#     andi t6, t6, 0x80

#     andi t1, a1, 0x7f # A绝对值, t1: 余数
#     andi t2, a2, 0x7f # B绝对值
#     not t3, t2 # t3: [-B]补
#     addi t3, t3, 1

#     li t0, 0 # t4: 循环变量
#     li t4, 6 # t4: 循环结束

#     # 溢出检测
#     add t1, t1, t3
#     andi t5, t1, 0x80 # t5: 余数的符号位
#     bne t5, zero, DISPLAY_SIGNED # A<B, 结果为0

#     DIV_LOOP:
#     beq t0, t4, DIV_END

#     # 记录当前位的商
#     andi t5, t1, 0x80 # t5: 余数的符号位
#     srli t5, t5, 7
#     or a0, a0, t5

#     slli t1, t1, 1 # 余数左移1位
#     slli a0, a0, 1 # 商左移1位

#     # 余数递推
#     beq t5, zero, DIV_ADD_POS # 余数为正
#     add t1, t1, t2 # t1 <- 2*t1 + B
#     j DIV_ADD_NXT
#     DIV_ADD_POS:
#     add t1, t1, t3 # t1 <- 2*t1 - B

#     DIV_ADD_NXT:
#     addi t0, t0, 1
#     j DIV_LOOP

#     DIV_END:
#     # 记录末位商
#     andi t5, t1, 0x80
#     srli t5, t5, 7
#     or a0, a0, t5

#     # 商的符号位
#     or a0, a0, t6

#     j DISPLAY_SIGNED

END:
    j MAIN