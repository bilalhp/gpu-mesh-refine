# choose the correct configuration for you
CUDPP_DIR = ../cudpp/cudpp_src_1.1.1/
CUDA_INSTALL_PATH ?= /usr/local/cuda

# choose the correct library for your system (32 bit or 64 bit)

LIB_PATHS = -L${CUDA_INSTALL_PATH}/lib -L${CUDPP_DIR}/lib -lcudpp_i686 -lcutil
#LIB_PATHS = -L${CUDA_INSTALL_PATH}/lib64 -L${CUDPP_DIR}/lib -lcudpp_x86_64 -lcutil

# temporary input file will be generated under this directory (please specify a 
# full path, absolute path will fail)

INPUT_DIR ?= /tmp

POINT_COUNT ?= 200000
POINT_COORD_MAX ?= 1000000

################################################################################
# DO NOT TOUCH THE CODE BELOW UNLESS YOU KNOW WHAT YOU ARE DOING !!!

export INPUT_DIR

INCL_PATHS = -I. -I./include -I${CUDPP_DIR}/cudpp/include -I${CUDPP_DIR}/common/inc
OPTFLAGS = -O3 --ptxas-options=-v
CC = gcc
CPP = g++
NVCC = nvcc
OBJS = mesh_refine.o mesh_refine_pc.o io.o edge_ops.o tri_ops.o refine.o
CFLAGS = -Wall -Werror -use_fast_math


all: mesh_refine

mesh_refine: $(OBJS)
	$(CPP) -o $@ $^ $(LIB_PATHS) -lcudart -lm

%.o: %.cu
	$(NVCC) $(OPTFLAGS) $(INCL_PATHS) -c $< -o $@

%.o: %.cpp
	$(CPP) $(OPTFLAGS) $(CFLAGS) $(INCL_PATHS) -c $< -o $@

${INPUT_DIR}/input.txt:
	${MAKE} -C gen_input all INPUT_DIR=${INPUT_DIR} POINT_COUNT=${POINT_COUNT} POINT_COORD_MAX=${POINT_COORD_MAX}

${INPUT_DIR}/input.1.node:
	${MAKE} -C gen_input direct_all

test: mesh_refine ${INPUT_DIR}/input.txt
	./mesh_refine -f ${INPUT_DIR}/input.txt #-o output.txt

test_debug: mesh_refine ${INPUT_DIR}/input.txt
	./mesh_refine -f ${INPUT_DIR}/input.txt -o output.txt -d

test_pc: mesh_refine ${INPUT_DIR}/input.txt
	./mesh_refine -f ${INPUT_DIR}/input.txt -p -o output.txt -d

test_direct: mesh_refine ${INPUT_DIR}/input.1.node
	./mesh_refine -i ${INPUT_DIR}/input.1  #-o output.txt

test_clean:
	rm -f ${INPUT_DIR}/input.txt
	${MAKE} -C gen_input clean_input INPUT_DIR=${INPUT_DIR} 

autotest: mesh_refine
	time -p ./test.sh start

autotest_pc: mesh_refine
	time -p ./test.sh only_pc start

autotest_pc_retest: mesh_refine
	time -p ./test.sh only_pc retest start

autotest_retest: mesh_refine
	time -p ./test.sh retest start

show:
	${MAKE} -C gen_input show_result

clean: 
	rm -f mesh_refine
	rm -f *.o
	rm -f *.linkinfo
	${MAKE} -C gen_input clean INPUT_DIR=${INPUT_DIR} 

distclean: clean
	rm -f ${INPUT_DIR}/input.txt output.txt
	${MAKE} -C gen_input distclean INPUT_DIR=${INPUT_DIR} 
