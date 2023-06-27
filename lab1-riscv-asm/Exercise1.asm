MAIN:
	lui  s1, 0xFFFFF
            
TEST:						# Test led and switch
	lw   s0, 0x70(s1)		# read switch
	sw   s0, 0x60(s1)		# write led	
    sw   s0, 0x00(s1)
	jal  TEST
