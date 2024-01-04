import sys

import pdb;
import debugpy;
# debugpy.listen(8028)

# debugpy.wait_for_client()

input_file = snakemake.input[0]
output_file = snakemake.output[0]



with open(input_file, 'r') as file:
    numbers = [int(line.strip()) for line in file.readlines()]
total = sum(numbers)

# breakpoint()

debugpy.breakpoint()

with open(output_file, 'w') as file:
    file.write(str(total))
