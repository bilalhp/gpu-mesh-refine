
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/time.h>

#include <main.h>

#include <cutil.h>
#include <cudpp.h>

__global__ void cu_get_counters(int *tri_edge0, int *tri_edge1, int *tri_edge2, unsigned int *tri_counter, unsigned int *tri_rev_counter, unsigned int *edge_mark_tree_next, int tri_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int p_counter = 0, p_rev_counter = 0;
	int e_ix;
	unsigned int mn;

	if (tid >= tri_count)
		return;

	__syncthreads();
	e_ix = tri_edge0[tid];
	mn = edge_mark_tree_next[abs(e_ix)];
	if ((__GET_E_MARK(mn) & 2)) {
		if (e_ix >= 0)
			p_counter++;
		else
			p_rev_counter++;
	}

	__syncthreads();
	e_ix = tri_edge1[tid];
	mn = edge_mark_tree_next[abs(e_ix)];
	if ((__GET_E_MARK(mn) & 2)) {
		if (e_ix >= 0)
			p_counter++;
		else
			p_rev_counter++;
	}

	__syncthreads();
	e_ix = tri_edge2[tid];
	mn = edge_mark_tree_next[abs(e_ix)];
	if ((__GET_E_MARK(mn) & 2)) {
		if (e_ix >= 0)
			p_counter++;
		else
			p_rev_counter++;
	}

	__syncthreads();
	tri_counter[tid] = p_counter;
	tri_rev_counter[tid] = p_rev_counter;
}

void cudpp_scan(void)
{
	CUDPPConfiguration config;
	config.op = CUDPP_ADD;
	config.datatype = CUDPP_UINT;
	config.algorithm = CUDPP_SCAN;
	config.options = CUDPP_OPTION_FORWARD | CUDPP_OPTION_INCLUSIVE;
	
	CUDPPHandle scanplan = 0;
	CUDPPResult result = cudppPlan(&scanplan, config, tri_count, 1, 0);
	
	if (CUDPP_SUCCESS != result) {
		printf("Error creating CUDPPPlan\n");
		exit(-1);
	}

	// Run the scan
	cudppScan(scanplan, d_tris->tri_counter_scan, d_tris->tri_counter, tri_count);
	cudppScan(scanplan, d_tris->tri_rev_counter_scan, d_tris->tri_rev_counter, tri_count);

	result = cudppDestroyPlan(scanplan);
	if (CUDPP_SUCCESS != result) {
		printf("Error destroying CUDPPPlan\n");
		exit(-1);
	}
}

void prefix_counters(void)
{
	cudaError_t err;
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	int block_count = tri_count/threadsPerBlock + 1;
	dim3 dimGrid(65535, block_count/65535 + 1);

	printf(DGREEN"[%s]"NORM" WORK STARTED: #threads=%d #blocks=%d***\n", __func__, threadsPerBlock, block_count);
	fflush(stdout);
	usleep(100000);

	gettimeofday(&start_time, NULL);

	cudpp_scan();

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	cudaSafeCall(cudaMemcpy(&newelemcount, &d_tris->tri_counter_scan[tri_count-1], sizeof(int), cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(&newelemcount_rev, &d_tris->tri_rev_counter_scan[tri_count-1], sizeof(int), cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaThreadSynchronize());

	// check err
	err = cudaGetLastError();
	if (cudaSuccess != err) {
		printf("error!\n");
	}
}

void get_counters(void)
{
	cudaError_t err;
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	int block_count = tri_count/threadsPerBlock + 1;
	dim3 dimGrid(65535, block_count/65535 + 1);

	printf(DGREEN"[%s]"NORM" WORK STARTED: #threads=%d #blocks=%d***\n", __func__, threadsPerBlock, block_count);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

#if (__CUDA_ARCH__ >= 200)
	cudaFuncSetCacheConfig(cu_get_counters, cudaFuncCachePreferL1);
#endif

	cu_get_counters<<<dimGrid, threadsPerBlock>>>(d_tris->tri_edge0, d_tris->tri_edge1, d_tris->tri_edge2, d_tris->tri_counter, d_tris->tri_rev_counter, d_edges->edge_mark_tree_next, tri_count);

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	// check err
	err = cudaGetLastError();
	if (cudaSuccess != err) {
		printf("error!\n");
	}
}
