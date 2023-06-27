import sys

A = int(sys.argv[1])
B = int(sys.argv[2])
op = int(sys.argv[3])

inst = (op << 21) | (A << 8) | B

print(hex(inst))
print(bin(inst))