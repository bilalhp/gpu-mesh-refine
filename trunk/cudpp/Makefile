CUDPP_DIR := cudpp_src_1.1.1

#export CUDA_INSTALL_PATH=/opt/nvidia/cuda

all: checkout
	${MAKE} -C ${CUDPP_DIR}/common
	${MAKE} -C ${CUDPP_DIR}/cudpp

checkout: clean
#	svn co http://cudpp.googlecode.com/svn/trunk/ cudpp_src
	tar -xvf cudpp_src_1.1.1.tbz2

clean:
	rm -rf ${CUDPP_DIR}
