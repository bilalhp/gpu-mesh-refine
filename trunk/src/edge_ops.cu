
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/time.h>

#include <main.h>

#if 0
static inline __device__ point_t calc_mid_point(point_t *p1, point_t *p2)
{
	point_t ret;

	ret.x = (p1->x + p2->x) / 2;
	ret.y = (p1->y + p2->y) / 2;

	return ret;
}
#endif

__global__ void cu_follow_links(unsigned int *edge_mark_tree_next, int edge_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int mn, next_mn;
	unsigned int next_ix;

	if ((tid == 0) || (tid >= edge_count))
		return;

	mn = edge_mark_tree_next[tid];
	if (!(__GET_E_MARK(mn) & 2)) {	// not marked
		return;
	}

	next_ix = __GET_E_NEXT(mn);
	if (!next_ix || (next_ix == NO_LINK)) {
		return;
	}

	while (next_ix && (next_ix != NO_LINK)) {
		next_mn = edge_mark_tree_next[next_ix];
		if (__GET_E_MARK(next_mn) & 2) {	// next is already marked
			break;
		}
		__SET_E_NEXT(mn, __GET_E_NEXT(next_mn));
		next_mn |= 2;
		__SET_E_NEXT(next_mn, NO_LINK);
		edge_mark_tree_next[next_ix] = next_mn;
		next_ix = __GET_E_NEXT(mn);
	}

	__SET_E_NEXT(mn, NO_LINK);
	edge_mark_tree_next[tid] = mn;
}

__global__ void cu_correct_marks(float *edge_len, unsigned int *edge_mark_tree_next, int edge_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;

	if ((tid == 0) || (tid >= edge_count))
		return;

	if (edge_len[tid] < 0) {
		edge_mark_tree_next[tid] |= 2;
	}
}

__global__ void cu_establish_links(int *tri_edge0, int *tri_edge1, int *tri_edge2, int *tri_longest_edge, unsigned int *edge_mark_tree_next, int tri_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	int edge, ledge;
	unsigned int mn;

	if (tid >= tri_count)
		return;

	__syncthreads();
	ledge = tri_longest_edge[tid];

	edge = abs(tri_edge0[tid]);
	if (edge != ledge) {
		mn = edge_mark_tree_next[edge];
		if (__GET_E_MARK(mn) & 1) {
			__SET_E_NEXT(mn, ledge);
			edge_mark_tree_next[edge] = mn;
		}
	}

	__syncthreads();
	edge = abs(tri_edge1[tid]);
	if (edge != ledge) {
		mn = edge_mark_tree_next[edge];
		if (__GET_E_MARK(mn) & 1) {
			__SET_E_NEXT(mn, ledge);
			edge_mark_tree_next[edge] = mn;
		}
	}

	__syncthreads();
	edge = abs(tri_edge2[tid]);
	if (edge != ledge) {
		mn = edge_mark_tree_next[edge];
		if (__GET_E_MARK(mn) & 1) {
			__SET_E_NEXT(mn, ledge);
			edge_mark_tree_next[edge] = mn;
		}
	}
}

__global__ void cu_mark_longest(int *tri_edge0, int *tri_edge1, int *tri_edge2, int *tri_longest_edge, float *edge_len, unsigned int *edge_mark_tree_next, int tri_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	float llen = 0, clen;
	int ledge;
	int edge_ix;

	if (tid >= tri_count)
		return;

	__syncthreads();
	edge_ix = abs(tri_edge0[tid]);
	clen = abs(edge_len[edge_ix]);
	if (clen > llen) {
		llen = clen;
		ledge = edge_ix;
	}

	__syncthreads();
	edge_ix = abs(tri_edge1[tid]);
	clen = abs(edge_len[edge_ix]);
	if (clen > llen) {
		llen = clen;
		ledge = edge_ix;
	}

	__syncthreads();
	edge_ix = abs(tri_edge2[tid]);
	clen = abs(edge_len[edge_ix]);
	if (clen > llen) {
		llen = clen;
		ledge = edge_ix;
	}

	if (tri_longest_edge[tid] == 1) {
		edge_len[ledge] = -llen;	// negative edge len is blackmark
	}

	edge_mark_tree_next[ledge] = 1;		// mark as longest edge
	__syncthreads();
	tri_longest_edge[tid] = ledge;
}

__global__ void cu_calc_edge_len_mid_p(point_t *edge_point0, point_t *edge_point1, point_t *edge_mid_p, float *edge_len, int edge_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	point_t p0, p1;

	if ((tid == 0) || (tid >= edge_count))
		return;

	//__syncthreads();
	p0 = edge_point0[tid];
	p1 = edge_point1[tid];

	//__syncthreads();
	edge_len[tid] = sqrtf(powf(fabs(p0.x - p1.x), 2) + powf(fabs(p0.y - p1.y), 2));
	//__syncthreads();
	edge_mid_p[tid].x = (p0.x + p1.x) / 2;
	edge_mid_p[tid].y = (p0.y + p1.y) / 2;
}

void follow_links(void)
{
	cudaError_t err;
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	int block_count = edge_count/threadsPerBlock + 1;
	dim3 dimGrid(65535, block_count/65535 + 1);

	printf(DGREEN"[%s]"NORM" WORK STARTED: #threads=%d #blocks=%d***\n", __func__, threadsPerBlock, block_count);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

#if (__CUDA_ARCH__ >= 200)
	cudaFuncSetCacheConfig(cu_correct_marks, cudaFuncCachePreferL1);
	cudaFuncSetCacheConfig(cu_follow_links, cudaFuncCachePreferL1);
#endif
	cu_correct_marks<<<dimGrid, threadsPerBlock>>>(d_edges->edge_len, d_edges->edge_mark_tree_next, edge_count);
	cu_follow_links<<<dimGrid, threadsPerBlock>>>(d_edges->edge_mark_tree_next, edge_count);

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

void establish_links(void)
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
	cudaFuncSetCacheConfig(cu_establish_links, cudaFuncCachePreferL1);
#endif
	cu_establish_links<<<dimGrid, threadsPerBlock>>>(d_tris->tri_edge0, d_tris->tri_edge1, d_tris->tri_edge2, d_tris->tri_longest_edge, d_edges->edge_mark_tree_next, tri_count);

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

void mark_longest_edges(void)
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
	//cudaFuncSetCacheConfig(cu_mark_longest, cudaFuncCachePreferL1);
#endif
	cu_mark_longest<<<dimGrid, threadsPerBlock>>>(d_tris->tri_edge0, d_tris->tri_edge1, d_tris->tri_edge2, d_tris->tri_longest_edge, d_edges->edge_len, d_edges->edge_mark_tree_next, tri_count);

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

void calc_edge_lengths_mid_p(void)
{
	cudaError_t err;
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	int block_count = edge_count/threadsPerBlock + 1;
	dim3 dimGrid(65535, block_count/65535 + 1);

	printf(DGREEN"[%s]"NORM" WORK STARTED: #threads=%d #blocks=%d***\n", __func__, threadsPerBlock, block_count);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

#if (__CUDA_ARCH__ >= 200)
	//cudaFuncSetCacheConfig(cu_calc_edge_len_mid_p, cudaFuncCachePreferL1);
#endif
	cu_calc_edge_len_mid_p<<<dimGrid, threadsPerBlock>>>(d_edges->edge_point0, d_edges->edge_point1, d_edges->edge_mid_p, d_edges->edge_len, edge_count);

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
