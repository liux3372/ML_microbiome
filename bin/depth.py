#code to get the appropriate depth used in the single rarefaction
import math

text_file = open("ninja/otu_summary.txt", "r")

lines = text_file.read().splitlines()

num=int(lines[0][13:])

sub_num=int(math.ceil(num*0.1))

index=lines.index('Counts/sample detail:')

sub_lines=lines[index+1:]

key=sub_lines[sub_num]

key_index=sub_lines.index(key)

key_num=int(float(key.split(' ')[2]))

if key_num<500:
	depth=500 
	for i in sub_lines:
		if int(float(i.split(' ')[2]))>=500:
			depth=int(float(i.split(' ')[2]))
			break
else:
	depth=min(key_num,1000)
#choose the depth that has more samples


print depth

