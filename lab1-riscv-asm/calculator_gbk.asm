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
    li s0, 0xa00983 # [-3]��
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
    li t0, 0 # t0: ѭ������
    li t1, 8 # t1: ѭ������
    li t2, 0 # t1: ���

    DISPLAY_BINARY_LOOP:
    beq t0, t1, DISPLAY_BINARY_END

    srl t3, a0, t0
    andi t3, t3, 0x1

    slli t4, t0, 2 # t4: 4*t0, ���ƴ���
    sll t3, t3, t4
    or t2, t2, t3

    addi t0, t0, 1
    j DISPLAY_BINARY_LOOP

    DISPLAY_BINARY_END:
    sw t2, 0x00(s1)
    
    j END

DISPLAY_SIGNED:
    andi t6, a0, 0x80 # t6: a0�ķ���λ
    andi a0, a0, 0x7f # a0: a0�ľ���ֵ

    sw a0, 0x00(s1)

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
    sll a0, a1, a2
    j DISPLAY_SIGNED

RSHIFT:
    sra a0, a1, a2
    j DISPLAY_SIGNED

TENARY:
    # (A==0) ? B : B����
    or a0, a2, zero # a0 = B
    beq a1, zero, DISPLAY_BINARY

    # ԭ��ת����
    andi t6, a0, 0x80 # t6: ����λ
    beq t6, zero, DISPLAY_BINARY # B>=0, ����=ԭ��

    andi a0, a0, 0x7f # ȥ������λ
    not a0, a0 # ȡ��
    addi a0, a0, 1 # ��1
    j DISPLAY_BINARY

DIV:
    # �Ӽ����淨
    ori a0, zero, 0 # a0: ���
    beq a2, zero, DISPLAY_SIGNED # ����Ϊ0

    xor t6, a1, a2 # t6: ����λ
    andi t6, t6, 0x80

    andi t1, a1, 0x7f # A����ֵ, t1: ����
    andi t2, a2, 0x7f # B����ֵ
    not t3, t2 # t3: [-B]��
    addi t3, t3, 1

    li t0, 0 # t4: ѭ������
    li t4, 6 # t4: ѭ������

    # ������
    add t1, t1, t3
    andi t5, t1, 0x80 # t5: �����ķ���λ
    bne t5, zero, DISPLAY_SIGNED # A<B, ���Ϊ0

    DIV_LOOP:
    beq t0, t4, DIV_END

    # ��¼��ǰλ����
    andi t5, t1, 0x80 # t5: �����ķ���λ
    srli t5, t5, 7
    or a0, a0, t5

    slli t1, t1, 1 # ��������1λ
    slli a0, a0, 1 # ������1λ

    # ��������
    beq t5, zero, DIV_ADD_POS # ����Ϊ��
    add t1, t1, t2 # t1 <- 2*t1 + B
    j DIV_ADD_NXT
    DIV_ADD_POS:
    add t1, t1, t3 # t1 <- 2*t1 - B

    DIV_ADD_NXT:
    addi t0, t0, 1
    j DIV_LOOP

    DIV_END:
    # ��¼ĩλ��
    andi t5, t1, 0x80
    srli t5, t5, 7
    or a0, a0, t5

    # �̵ķ���λ
    or a0, a0, t6

    j DISPLAY_SIGNED

END:
    j MAIN