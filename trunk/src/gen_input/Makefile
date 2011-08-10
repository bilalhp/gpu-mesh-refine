
INPUT_DIR ?= /tmp

CFLAGS := -Wall -Werror -O3 -std=gnu99

all: gen_input ${INPUT_DIR}/input.txt

direct_all: gen_input ${INPUT_DIR}/input.1.node

gen_input: gen_input.o
	$(CC) ${CFLAGS} -o $@ $^

process_input: process_input.o
	$(CC) ${CFLAGS} -o $@ $^ -lm

convert_output: convert_output.o
	$(CC) ${CFLAGS} -o $@ $^

triangle/triangle:
	${MAKE} -C triangle all

triangle/showme:
	${MAKE} -C triangle showme

${INPUT_DIR}/input.node: gen_input
	./gen_input ${POINT_COUNT} ${POINT_COORD_MAX} ${INPUT_DIR}/input.node

${INPUT_DIR}/input.1.node: triangle/triangle ${INPUT_DIR}/input.node
	triangle/triangle ${INPUT_DIR}/input.node

showme: triangle/showme ${INPUT_DIR}/input.1.node
	-triangle/showme ${INPUT_DIR}/input.1

${INPUT_DIR}/input.txt: process_input ${INPUT_DIR}/input.1.node
	./process_input ${INPUT_DIR}/input.1 ${INPUT_DIR}/input.txt

show_result: convert_output triangle/showme
	./convert_output ../output.txt result
	-triangle/showme result

clean:
	rm -f *.o gen_input process_input convert_output result.*
	${MAKE} -C triangle distclean

clean_input:
	rm -rf ${INPUT_DIR}/input*

distclean: clean clean_input
