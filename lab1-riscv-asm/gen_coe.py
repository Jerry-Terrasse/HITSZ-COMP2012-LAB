with open('calculator.hex', 'r') as f:
    lines = f.readlines()

with open('calculator.coe', 'w') as f:
    f.write('memory_initialization_radix = 16;\n')
    f.write('memory_initialization_vector =\n')
    data = '{};\n'.format(',\n'.join(line.strip() for line in lines))
    f.write(data)