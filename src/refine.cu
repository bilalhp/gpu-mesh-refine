
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/time.h>

#include <main.h>

__global__ void cu_refine_pass3(int *new_edge0, int *new_edge1, int *orth_edge, unsigned int *edge_mark_tree_next, int *tri_edge0, int *tri_edge1, int *tri_edge2, int *tri_longest_edge, unsigned int *tri_counter_scan, unsigned int *tri_rev_counter_scan, int tri_count, int new_tri_count)
{
#define LONGEST_SELF	LONGEST
#define LONGEST_0	new_edge0[LONGEST_ABS]
#define LONGEST_1	new_edge1[LONGEST_ABS]
#define LONGEST_ORTHO	orth_edge[LONGEST_ABS]
#define RIGHT_SELF	RIGHT
#define RIGHT_0		new_edge0[RIGHT_ABS]
#define RIGHT_1		new_edge1[RIGHT_ABS]
#define RIGHT_ORTHO	orth_edge[RIGHT_ABS]
#define LEFT_SELF	LEFT
#define LEFT_0		new_edge0[LEFT_ABS]
#define LEFT_1		new_edge1[LEFT_ABS]
#define LEFT_ORTHO	orth_edge[LEFT_ABS]
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int mn;
	int LONGEST, RIGHT, LEFT;
	int e_ix0, e_ix1, e_ix2, LONGEST_ABS, RIGHT_ABS, LEFT_ABS, RIGHT_MARKED = 0, LEFT_MARKED = 0;
	int marked_count = 0;
	unsigned int created_tri_ix = tri_count - new_tri_count;
	unsigned int cnt, rcnt;

	if (tid >= (tri_count - new_tri_count))
		return;

	__syncthreads();
	cnt = tri_counter_scan[tid];
	rcnt = tri_rev_counter_scan[tid];
	created_tri_ix += __GET_T_CNT(cnt) + __GET_T_RCNT(rcnt) - 1;

	__syncthreads();
	e_ix0 = tri_edge0[tid];
	e_ix1 = tri_edge1[tid];
	e_ix2 = tri_edge2[tid];
	LONGEST = tri_longest_edge[tid];

	if (LONGEST == abs(e_ix0)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix0;
		RIGHT_ABS = abs(e_ix1);
		RIGHT = e_ix1;
		LEFT_ABS = abs(e_ix2);
		LEFT = e_ix2;
	} else if (LONGEST == abs(e_ix1)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix1;
		RIGHT_ABS = abs(e_ix2);
		RIGHT = e_ix2;
		LEFT_ABS = abs(e_ix0);
		LEFT = e_ix0;
	} else if (LONGEST == abs(e_ix2)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix2;
		RIGHT_ABS = abs(e_ix0);
		RIGHT = e_ix0;
		LEFT_ABS = abs(e_ix1);
		LEFT = e_ix1;
	} else {
		return;
	}

	__syncthreads();
	mn = edge_mark_tree_next[RIGHT_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		marked_count++;
		RIGHT_MARKED = 1;
	}
	__syncthreads();
	mn = edge_mark_tree_next[LEFT_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		marked_count++;
		LEFT_MARKED = 1;
	}

	if (LEFT_MARKED || RIGHT_MARKED) {
		// means longest is also marked
		marked_count++;
	} else {
		mn = edge_mark_tree_next[LONGEST_ABS];
		if ((__GET_E_MARK(mn) & 2)) {
			marked_count++;
		}
	}

	// START
	__syncthreads();
	if (marked_count == 1) {
/*Scenario #1*/	if (LONGEST > 0) {	// forward scenario
			// left side
			tri_edge0[tid] = -LONGEST_SELF;
			tri_edge1[tid] = LEFT_SELF;
			tri_edge2[tid] = LONGEST_0;
			// right side
			tri_edge0[created_tri_ix] = LONGEST_SELF;
			tri_edge1[created_tri_ix] = LONGEST_1;
			tri_edge2[created_tri_ix] = RIGHT_SELF;
/*Scenario #2*/	} else {	// backward scenario
			// left side
			tri_edge0[tid] = -LONGEST_ORTHO;
			tri_edge1[tid] = LEFT_SELF;
			tri_edge2[tid] = -LONGEST_1;
			// right side
			tri_edge0[created_tri_ix] = LONGEST_ORTHO;
			tri_edge1[created_tri_ix] = -LONGEST_0;
			tri_edge2[created_tri_ix] = RIGHT_SELF;
		}
	} else if (marked_count == 2) {
		// check out the right side
		if (RIGHT_MARKED) {	// right side is marked
			if (LONGEST > 0) {	// forward scenario
				// first, set the self triangle to left side
				tri_edge0[tid] = -LONGEST_SELF;
				tri_edge1[tid] = LEFT_SELF;
				tri_edge2[tid] = LONGEST_0;
				// split the right side
/* Scenario #7 */		if (RIGHT > 0) {	// forward scenario
					// left side
					tri_edge0[created_tri_ix] = -RIGHT_SELF;
					tri_edge1[created_tri_ix] = LONGEST_1;
					tri_edge2[created_tri_ix] = RIGHT_0;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = RIGHT_SELF;
					tri_edge1[created_tri_ix] = RIGHT_1;
					tri_edge2[created_tri_ix] = LONGEST_SELF;
					created_tri_ix--;
/* Scenario #9 */		} else {	// backward scenario
					// left side
					tri_edge0[created_tri_ix] = -RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = LONGEST_1;
					tri_edge2[created_tri_ix] = -RIGHT_1;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = -RIGHT_0;
					tri_edge2[created_tri_ix] = LONGEST_SELF;
					created_tri_ix--;
				}
			} else {	// backward scenario
				// first, set the self triangle to left side
				tri_edge0[tid] = -LONGEST_ORTHO;
				tri_edge1[tid] = LEFT_SELF;
				tri_edge2[tid] = -LONGEST_1;
				// split the right side
/* Scenario #8 */		if (RIGHT > 0) {	// forward scenario
					// left side
					tri_edge0[created_tri_ix] = -RIGHT_SELF;
					tri_edge1[created_tri_ix] = -LONGEST_0;
					tri_edge2[created_tri_ix] = RIGHT_0;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = RIGHT_SELF;
					tri_edge1[created_tri_ix] = RIGHT_1;
					tri_edge2[created_tri_ix] = LONGEST_ORTHO;
					created_tri_ix--;
/* Scenario #10 */		} else {	// backward scenario
					// left side
					tri_edge0[created_tri_ix] = -RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = -LONGEST_0;
					tri_edge2[created_tri_ix] = -RIGHT_1;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = -RIGHT_0;
					tri_edge2[created_tri_ix] = LONGEST_ORTHO;
					created_tri_ix--;
				}
			}
		} else {
			if (LONGEST > 0) {	// forward scenario
				// first, set the self triangle to right side
				tri_edge0[tid] = LONGEST_SELF;
				tri_edge1[tid] = LONGEST_1;
				tri_edge2[tid] = RIGHT_SELF;
				// split the left side
/* Scenario #3 */		if (LEFT > 0) {	// forward scenario
					// left side
					tri_edge0[created_tri_ix] = -LEFT_SELF;
					tri_edge1[created_tri_ix] = -LONGEST_SELF;
					tri_edge2[created_tri_ix] = LEFT_0;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = LEFT_SELF;
					tri_edge1[created_tri_ix] = LEFT_1;
					tri_edge2[created_tri_ix] = LONGEST_0;
					created_tri_ix--;
/* Scenario #5 */		} else {	// backward scenario
					// left side
					tri_edge0[created_tri_ix] = -LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LONGEST_SELF;
					tri_edge2[created_tri_ix] = -LEFT_1;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LEFT_0;
					tri_edge2[created_tri_ix] = LONGEST_0;
					created_tri_ix--;
				}
			} else {	// backward scenario
				// first, set the self triangle to right side
				tri_edge0[tid] = LONGEST_ORTHO;
				tri_edge1[tid] = -LONGEST_0;
				tri_edge2[tid] = RIGHT_SELF;
				// split the left side
/* Scenario #4 */		if (LEFT > 0) {	// forward scenario
					// left side
					tri_edge0[created_tri_ix] = -LEFT_SELF;
					tri_edge1[created_tri_ix] = -LONGEST_ORTHO;
					tri_edge2[created_tri_ix] = LEFT_0;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = LEFT_SELF;
					tri_edge1[created_tri_ix] = LEFT_1;
					tri_edge2[created_tri_ix] = -LONGEST_1;
					created_tri_ix--;
/* Scenario #6 */		} else {	// backward scenario
					// left side
					tri_edge0[created_tri_ix] = -LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LONGEST_ORTHO;
					tri_edge2[created_tri_ix] = -LEFT_1;
					created_tri_ix--;
					// right side
					tri_edge0[created_tri_ix] = LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LEFT_0;
					tri_edge2[created_tri_ix] = -LONGEST_1;
					created_tri_ix--;
				}
			}
		}
	} else if (marked_count == 3) {
		if (LONGEST > 0) {	// longest forward scenario
			if (LEFT > 0) {	// left forward scenario
/* Scenario #11 */		if (RIGHT > 0) {	// right forward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_SELF;
					tri_edge1[tid] = LEFT_0;
					tri_edge2[tid] = -LEFT_SELF;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_SELF;
					tri_edge1[created_tri_ix] = LEFT_1;
					tri_edge2[created_tri_ix] = LONGEST_0;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_SELF;
					tri_edge1[created_tri_ix] = LONGEST_1;
					tri_edge2[created_tri_ix] = RIGHT_0;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_SELF;
					tri_edge1[created_tri_ix] = RIGHT_SELF;
					tri_edge2[created_tri_ix] = RIGHT_1;
					created_tri_ix--;
/* Scenario #12 */		} else {	// right backward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_SELF;
					tri_edge1[tid] = LEFT_0;
					tri_edge2[tid] = -LEFT_SELF;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_SELF;
					tri_edge1[created_tri_ix] = LEFT_1;
					tri_edge2[created_tri_ix] = LONGEST_0;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = LONGEST_1;
					tri_edge2[created_tri_ix] = -RIGHT_1;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_SELF;
					tri_edge1[created_tri_ix] = RIGHT_ORTHO;
					tri_edge2[created_tri_ix] = -RIGHT_0;
					created_tri_ix--;
				}
			} else {	// left backward scenario
/* Scenario #14 */		if (RIGHT > 0) {	// right forward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_SELF;
					tri_edge1[tid] = -LEFT_1;
					tri_edge2[tid] = -LEFT_ORTHO;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LEFT_0;
					tri_edge2[created_tri_ix] = LONGEST_0;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_SELF;
					tri_edge1[created_tri_ix] = LONGEST_1;
					tri_edge2[created_tri_ix] = RIGHT_0;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_SELF;
					tri_edge1[created_tri_ix] = RIGHT_SELF;
					tri_edge2[created_tri_ix] = RIGHT_1;
					created_tri_ix--;
/* Scenario #13 */		} else {	// right backward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_SELF;
					tri_edge1[tid] = -LEFT_1;
					tri_edge2[tid] = -LEFT_ORTHO;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LEFT_0;
					tri_edge2[created_tri_ix] = LONGEST_0;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = LONGEST_1;
					tri_edge2[created_tri_ix] = -RIGHT_1;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_SELF;
					tri_edge1[created_tri_ix] = RIGHT_ORTHO;
					tri_edge2[created_tri_ix] = -RIGHT_0;
					created_tri_ix--;
				}
			}
		} else {	// longest backward scenario
			if (LEFT > 0) {	// left forward scenario
/* Scenario #15 */		if (RIGHT > 0) {	// right forward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_ORTHO;
					tri_edge1[tid] = LEFT_0;
					tri_edge2[tid] = -LEFT_SELF;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_SELF;
					tri_edge1[created_tri_ix] = LEFT_1;
					tri_edge2[created_tri_ix] = -LONGEST_1;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_SELF;
					tri_edge1[created_tri_ix] = -LONGEST_0;
					tri_edge2[created_tri_ix] = RIGHT_0;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_ORTHO;
					tri_edge1[created_tri_ix] = RIGHT_SELF;
					tri_edge2[created_tri_ix] = RIGHT_1;
					created_tri_ix--;
/* Scenario #16 */		} else {	// right backward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_ORTHO;
					tri_edge1[tid] = LEFT_0;
					tri_edge2[tid] = -LEFT_SELF;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_SELF;
					tri_edge1[created_tri_ix] = LEFT_1;
					tri_edge2[created_tri_ix] = -LONGEST_1;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = -LONGEST_0;
					tri_edge2[created_tri_ix] = -RIGHT_1;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_ORTHO;
					tri_edge1[created_tri_ix] = RIGHT_ORTHO;
					tri_edge2[created_tri_ix] = -RIGHT_0;
					created_tri_ix--;
				}
			} else {	// left backward scenario
/* Scenario #18 */		if (RIGHT > 0) {	// right forward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_ORTHO;
					tri_edge1[tid] = -LEFT_1;
					tri_edge2[tid] = -LEFT_ORTHO;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LEFT_0;
					tri_edge2[created_tri_ix] = -LONGEST_1;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_SELF;
					tri_edge1[created_tri_ix] = -LONGEST_0;
					tri_edge2[created_tri_ix] = RIGHT_0;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_ORTHO;
					tri_edge1[created_tri_ix] = RIGHT_SELF;
					tri_edge2[created_tri_ix] = RIGHT_1;
					created_tri_ix--;
/* Scenario #17 */		} else {	// right backward scenario
					// first, set the self triangle to part 1
					tri_edge0[tid] = -LONGEST_ORTHO;
					tri_edge1[tid] = -LEFT_1;
					tri_edge2[tid] = -LEFT_ORTHO;
					// part 2
					tri_edge0[created_tri_ix] = LEFT_ORTHO;
					tri_edge1[created_tri_ix] = -LEFT_0;
					tri_edge2[created_tri_ix] = -LONGEST_1;
					created_tri_ix--;
					// part 3
					tri_edge0[created_tri_ix] = -RIGHT_ORTHO;
					tri_edge1[created_tri_ix] = -LONGEST_0;
					tri_edge2[created_tri_ix] = -RIGHT_1;
					created_tri_ix--;
					// part 4
					tri_edge0[created_tri_ix] = LONGEST_ORTHO;
					tri_edge1[created_tri_ix] = RIGHT_ORTHO;
					tri_edge2[created_tri_ix] = -RIGHT_0;
					created_tri_ix--;
				}
			}
		}
	}
}

static __device__ point_t get_opposite_point(int i, point_t *edge_point0, point_t *edge_point1, int *new_edge0, int *new_edge1)
{
	int i_abs = abs(i);
	int ne0, ne1;

	ne0 = new_edge0[i_abs];
	if (ne0 > 0) {	// is it divided?
		if (i > 0) {	// forward
			ne1 = new_edge1[i_abs];
			return edge_point1[abs(ne1)];
		} else {
			return edge_point0[abs(ne0)];
		}
	} else {
		if (i > 0) {
			return edge_point1[i_abs];
		} else {
			return edge_point0[i_abs];
		}
	}
}

__global__ void cu_refine_pass2(point_t *edge_point0, point_t *edge_point1, int *new_edge0, int *new_edge1, point_t *edge_mid_p, unsigned int *edge_mark_tree_next, int *tri_edge0, int *tri_edge1, int *tri_edge2, int *tri_longest_edge, int tri_count, int new_tri_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int mn;
	int LONGEST, RIGHT, LEFT;
	int e_ix0, e_ix1, e_ix2, LONGEST_ABS, RIGHT_ABS, LEFT_ABS;

	if (tid >= (tri_count - new_tri_count))
		return;

	__syncthreads();
	e_ix0 = tri_edge0[tid];
	e_ix1 = tri_edge1[tid];
	e_ix2 = tri_edge2[tid];
	LONGEST = tri_longest_edge[tid];

	if (LONGEST == abs(e_ix0)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix0;
		RIGHT_ABS = abs(e_ix1);
		RIGHT = e_ix1;
		LEFT_ABS = abs(e_ix2);
		LEFT = e_ix2;
	} else if (LONGEST == abs(e_ix1)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix1;
		RIGHT_ABS = abs(e_ix2);
		RIGHT = e_ix2;
		LEFT_ABS = abs(e_ix0);
		LEFT = e_ix0;
	} else if (LONGEST == abs(e_ix2)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix2;
		RIGHT_ABS = abs(e_ix0);
		RIGHT = e_ix0;
		LEFT_ABS = abs(e_ix1);
		LEFT = e_ix1;
	}

	// process longest
	__syncthreads();
	mn = edge_mark_tree_next[LONGEST_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		if (LONGEST > 0) {	// forward scenario
			edge_point0[LONGEST_ABS] = get_opposite_point(RIGHT, edge_point0, edge_point1, new_edge0, new_edge1);
			edge_point1[LONGEST_ABS] = edge_mid_p[LONGEST_ABS];
		}
	}

	// process right
	__syncthreads();
	mn = edge_mark_tree_next[RIGHT_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		if (RIGHT > 0) {	// forward scenario
			edge_point0[RIGHT_ABS] = edge_mid_p[LONGEST_ABS];
			edge_point1[RIGHT_ABS] = edge_mid_p[RIGHT_ABS];
		}
	}

	// process left
	__syncthreads();
	mn = edge_mark_tree_next[LEFT_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		if (LEFT > 0) {	// forward scenario
			edge_point0[LEFT_ABS] = edge_mid_p[LONGEST_ABS];
			edge_point1[LEFT_ABS] = edge_mid_p[LEFT_ABS];
		}
	}
}

__global__ void cu_refine_pass1(point_t *edge_point0, point_t *edge_point1, point_t *edge_mid_p, unsigned int *edge_mark_tree_next, int *new_edge0, int *new_edge1, int *orth_edge, int *tri_edge0, int *tri_edge1, int *tri_edge2, int *tri_longest_edge, unsigned int *tri_counter_scan, unsigned int *tri_rev_counter_scan, int edge_count, int tri_count, int new_edge_count, int new_tri_count)
{
	unsigned int tid = blockIdx.y * blockDim.x * gridDim.x + blockIdx.x * blockDim.x + threadIdx.x;
	unsigned int created_edge_ix = edge_count - new_edge_count;
	unsigned int mn;
	int LONGEST, RIGHT, LEFT;
	int e_ix0, e_ix1, e_ix2, LONGEST_ABS, RIGHT_ABS, LEFT_ABS;
	unsigned int cnt, rcnt;

	if (tid >= (tri_count - new_tri_count))
		return;

	__syncthreads();
	cnt = tri_counter_scan[tid];
	rcnt = tri_rev_counter_scan[tid];
	created_edge_ix += 2*__GET_T_CNT(cnt) + __GET_T_RCNT(rcnt) - 1;
	e_ix0 = tri_edge0[tid];
	e_ix1 = tri_edge1[tid];
	e_ix2 = tri_edge2[tid];
	LONGEST = tri_longest_edge[tid];

	if (LONGEST == abs(e_ix0)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix0;
		RIGHT_ABS = abs(e_ix1);
		RIGHT = e_ix1;
		LEFT_ABS = abs(e_ix2);
		LEFT = e_ix2;
	} else if (LONGEST == abs(e_ix1)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix1;
		RIGHT_ABS = abs(e_ix2);
		RIGHT = e_ix2;
		LEFT_ABS = abs(e_ix0);
		LEFT = e_ix0;
	} else if (LONGEST == abs(e_ix2)) {
		LONGEST_ABS = LONGEST;
		LONGEST = e_ix2;
		RIGHT_ABS = abs(e_ix0);
		RIGHT = e_ix0;
		LEFT_ABS = abs(e_ix1);
		LEFT = e_ix1;
	}

	// process longest
	__syncthreads();
	mn = edge_mark_tree_next[LONGEST_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		if (LONGEST > 0) {	// forward scenario
			edge_point0[created_edge_ix] = edge_point0[LONGEST_ABS];
			edge_point1[created_edge_ix] = edge_mid_p[LONGEST_ABS];
			new_edge0[LONGEST_ABS] = created_edge_ix;
			created_edge_ix--;
			edge_point0[created_edge_ix] = edge_mid_p[LONGEST_ABS];
			edge_point1[created_edge_ix] = edge_point1[LONGEST_ABS];
			new_edge1[LONGEST_ABS] = created_edge_ix;
			created_edge_ix--;
		} else {
			edge_point0[created_edge_ix] = (RIGHT > 0) ? edge_point1[RIGHT_ABS] : edge_point0[RIGHT_ABS];
			edge_point1[created_edge_ix] = edge_mid_p[LONGEST_ABS];
			orth_edge[LONGEST_ABS] = created_edge_ix;
			created_edge_ix--;
		}
	}

	// process right
	__syncthreads();
	mn = edge_mark_tree_next[RIGHT_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		if (RIGHT > 0) {	// forward scenario
			edge_point0[created_edge_ix] = edge_point0[RIGHT_ABS];
			edge_point1[created_edge_ix] = edge_mid_p[RIGHT_ABS];
			new_edge0[RIGHT_ABS] = created_edge_ix;
			created_edge_ix--;
			edge_point0[created_edge_ix] = edge_mid_p[RIGHT_ABS];
			edge_point1[created_edge_ix] = edge_point1[RIGHT_ABS];
			new_edge1[RIGHT_ABS] = created_edge_ix;
			created_edge_ix--;
		} else {
			edge_point0[created_edge_ix] = edge_mid_p[LONGEST_ABS];
			edge_point1[created_edge_ix] = edge_mid_p[RIGHT_ABS];
			orth_edge[RIGHT_ABS] = created_edge_ix;
			created_edge_ix--;
		}
	}

	// process left
	__syncthreads();
	mn = edge_mark_tree_next[LEFT_ABS];
	if ((__GET_E_MARK(mn) & 2)) {
		if (LEFT > 0) {	// forward scenario
			edge_point0[created_edge_ix] = edge_point0[LEFT_ABS];
			edge_point1[created_edge_ix] = edge_mid_p[LEFT_ABS];
			new_edge0[LEFT_ABS] = created_edge_ix;
			created_edge_ix--;
			edge_point0[created_edge_ix] = edge_mid_p[LEFT_ABS];
			edge_point1[created_edge_ix] = edge_point1[LEFT_ABS];
			new_edge1[LEFT_ABS] = created_edge_ix;
			created_edge_ix--;
		} else {
			edge_point0[created_edge_ix] = edge_mid_p[LONGEST_ABS];
			edge_point1[created_edge_ix] = edge_mid_p[LEFT_ABS];
			orth_edge[LEFT_ABS] = created_edge_ix;
			created_edge_ix--;
		}
	}
}

void refine(void)
{
	cudaError_t err;
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	int block_count = (tri_count- new_tri_count)/threadsPerBlock + 1;
	dim3 dimGrid(65535, block_count/65535 + 1);

	printf(DGREEN"[%s]"NORM" WORK STARTED: #threads=%d #blocks=%d***\n", __func__, threadsPerBlock, block_count);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

#if (__CUDA_ARCH__ >= 200)
	cudaFuncSetCacheConfig(cu_refine_pass1, cudaFuncCachePreferL1);
	cudaFuncSetCacheConfig(cu_refine_pass2, cudaFuncCachePreferL1);
	cudaFuncSetCacheConfig(cu_refine_pass3, cudaFuncCachePreferL1);
#endif

	cu_refine_pass1<<<dimGrid, threadsPerBlock>>>(d_edges->edge_point0, d_edges->edge_point1, d_edges->edge_mid_p, d_edges->edge_mark_tree_next, d_edges->new_edge0, d_edges->new_edge1, d_edges->orth_edge, d_tris->tri_edge0, d_tris->tri_edge1, d_tris->tri_edge2, d_tris->tri_longest_edge, d_tris->tri_counter_scan, d_tris->tri_rev_counter_scan, edge_count, tri_count, new_edge_count, new_tri_count);

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" PASS1 TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	// check err
	err = cudaGetLastError();
	if (cudaSuccess != err) {
		printf("error!\n");
	}

	cu_refine_pass2<<<dimGrid, threadsPerBlock>>>(d_edges->edge_point0, d_edges->edge_point1, d_edges->new_edge0, d_edges->new_edge1, d_edges->edge_mid_p, d_edges->edge_mark_tree_next, d_tris->tri_edge0, d_tris->tri_edge1, d_tris->tri_edge2, d_tris->tri_longest_edge, tri_count, new_tri_count);

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" PASS2 TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	// check err
	err = cudaGetLastError();
	if (cudaSuccess != err) {       
		printf("error!\n");
	}

	cu_refine_pass3<<<dimGrid, threadsPerBlock>>>(d_edges->new_edge0, d_edges->new_edge1, d_edges->orth_edge, d_edges->edge_mark_tree_next, d_tris->tri_edge0, d_tris->tri_edge1, d_tris->tri_edge2, d_tris->tri_longest_edge, d_tris->tri_counter_scan, d_tris->tri_rev_counter_scan, tri_count, new_tri_count);

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" PASS3 TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	// check err
	err = cudaGetLastError();
	if (cudaSuccess != err) {
		printf("error!\n");
	}
}

int host_realloc_tris(void)
{
	tris.tri_edge0 = (int *)realloc(tris.tri_edge0, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_edge0 == NULL) {
		printf("cannot realloc tris.tri_edge0!\n");
		return -1;
	}

	tris.tri_edge1 = (int *)realloc(tris.tri_edge1, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_edge1 == NULL) {
		printf("cannot realloc tris.tri_edge1!\n");
		return -1;
	}

	tris.tri_edge2 = (int *)realloc(tris.tri_edge2, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_edge2 == NULL) {
		printf("cannot realloc tris.tri_edge2!\n");
		return -1;
	}

	tris.tri_longest_edge = (int *)realloc(tris.tri_longest_edge, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_longest_edge == NULL) {
		printf("cannot realloc tris.tri_longest_edge!\n");
		return -1;
	}

	tris.tri_counter = (unsigned int *)realloc(tris.tri_counter, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_counter == NULL) {
		printf("cannot realloc tris.tri_counter!\n");
		return -1;
	}

	tris.tri_counter_scan = (unsigned int *)realloc(tris.tri_counter_scan, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_counter_scan == NULL) {
		printf("cannot realloc tris.tri_counter_scan!\n");
		return -1;
	}

	tris.tri_rev_counter = (unsigned int *)realloc(tris.tri_rev_counter, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_rev_counter == NULL) {
		printf("cannot realloc tris.tri_rev_counter!\n");
		return -1;
	}

	tris.tri_rev_counter_scan = (unsigned int *)realloc(tris.tri_rev_counter_scan, (tri_count + new_tri_count)*sizeof(int));
	if (tris.tri_rev_counter_scan == NULL) {
		printf("cannot realloc tris.tri_rev_counter_scan!\n");
		return -1;
	}

	return 0;
}

int host_realloc_edges(void)
{
	edges.edge_point0 = (point_t *)realloc(edges.edge_point0, (edge_count + new_edge_count)*sizeof(point_t));
	if (edges.edge_point0 == NULL) {
		printf("cannot realloc edge_point0 arr!\n");
		return -1;
	}

	edges.edge_point1 = (point_t *)realloc(edges.edge_point1, (edge_count + new_edge_count)*sizeof(point_t));
	if (edges.edge_point1 == NULL) {
		printf("cannot realloc edge_point1 arr!\n");
		return -1;
	}

	edges.edge_mid_p = (point_t *)realloc(edges.edge_mid_p, (edge_count + new_edge_count)*sizeof(point_t));
	if (edges.edge_mid_p == NULL) {
		printf("cannot realloc edge_mid_p arr!\n");
		return -1;
	}

	edges.edge_len = (float *)realloc(edges.edge_len, (edge_count + new_edge_count)*sizeof(float));
	if (edges.edge_len == NULL) {
		printf("cannot realloc edge_len arr!\n");
		return -1;
	}

	edges.edge_mark_tree_next = (unsigned int *)realloc(edges.edge_mark_tree_next, (edge_count + new_edge_count)*sizeof(int));
	if (edges.edge_mark_tree_next == NULL) {
		printf("cannot realloc edge_mark_tree_next arr!\n");
		return -1;
	}

	edges.new_edge0 = (int *)realloc(edges.new_edge0, (edge_count + new_edge_count)*sizeof(int));
	if (edges.new_edge0 == NULL) {
		printf("cannot realloc new_edge0 arr!\n");
		return -1;
	}

	edges.new_edge1 = (int *)realloc(edges.new_edge1, (edge_count + new_edge_count)*sizeof(int));
	if (edges.new_edge1 == NULL) {
		printf("cannot realloc new_edge1 arr!\n");
		return -1;
	}

	edges.orth_edge = (int *)realloc(edges.orth_edge, (edge_count + new_edge_count)*sizeof(int));
	if (edges.orth_edge == NULL) {
		printf("cannot realloc orth_edge arr!\n");
		return -1;
	}

	return 0;
}

void create_new_elem_arrs(void)
{
	new_edge_count = 2*__GET_T_CNT(newelemcount) + __GET_T_RCNT(newelemcount_rev);
	new_tri_count = __GET_T_CNT(newelemcount) + __GET_T_RCNT(newelemcount_rev);

	printf("new_edge_count=%d new_tri_count=%d\n", new_edge_count, new_tri_count);

#if 0
	if ((__GET_T_CNT(newelemcount) < refine_count) || (__GET_T_RCNT(newelemcount) < refine_count)) {
		printf(RED"FAILED!!\n"NORM);
		device_cleanup();
		exit(1);
	}
#endif
	// copy back the modified data from device
	copy_back();

	// free the old device stuff
	device_cleanup();

	if (host_realloc_edges() < 0) {
		printf("host realloc error\n");
		exit(1);
	}

	if (host_realloc_tris() < 0) {
		printf("host realloc error\n");
		exit(1);
	}

	edge_count += new_edge_count;
	tri_count += new_tri_count;

	// malloc and copy the new arrays
	malloc_copy_input_to_device2();
}
