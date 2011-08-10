********************************************************************************
*****************            MESH REFINE USING CUDA            *****************
********************************************************************************
*
* Author: Bilal Hatipoglu
* Date: April, 2011
*
***********************
About
***********************



***********************
Compile
***********************

CUDA toolkit 3.2 (or above) si required to compile and run the program.

Also make sure the environment is set accordingly to access CUDA binaries 
(nvcc) and libraries (libcudart.so).

Before compiling, you may need to set the correct configuration which is at the
first lines of the Makefile. Please have a look at the Makefile.

You need to have cudpp library. If you have a fresh compiled one, select the 
appropriate path from the Makefile. Else, use the one came with this source in 
the cudpp directory.

To compile cudpp, cd to cuddp/ directory and issue:
make all

After the cudpp successfully compiled, you may proceed with the main 
application.

To compile the code, cd to src/ directory and just issue:
make all

After successful compilation, binary file called "mesh_refine" will be 
generated.


********************
Test
********************

To run a sungle test, issue the command:

make test

This will generate a random input file having 400k triangles by default and try 
to refine the mesh. 

You can run the same test again with the same input many times. To clean the 
input and force generating new input, you should issue:

make test_clean

To change the test parameters, use the POINT_COUNT and POINT_COORD MAX values:

make test POINT_COUNT=100000 POINT_COORD_MAX=500000

The number of generated triangles will be roughly 2 times the point count. 
POINT_COORD_MAX is recommended to set minimum 5 times the point count, to give 
enough space and help the triangle-generating app. Else, some points will be 
duplicate and ignored, or the triangle application will fail to generate the 
input.

********************************************************************************
