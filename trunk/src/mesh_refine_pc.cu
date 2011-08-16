// Includes
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <math.h>
#include <limits.h>
#include <sys/time.h>
//#include <cutil_inline.h>
#include <main.h>


#define PC_E_P0(_i)		pc_edges.edge_point0[_i]
#define PC_E_P1(_i)		pc_edges.edge_point1[_i]
#define PC_E_MIDP(_i)		pc_edges.edge_mid_p[_i]
#define PC_E_MN(_i)		pc_edges.edge_mark_tree_next[_i]
#define PC_E_NE0(_i)		pc_edges.new_edge0[_i]
#define PC_E_NE1(_i)		pc_edges.new_edge1[_i]
#define PC_E_OE(_i)		pc_edges.orth_edge[_i]
#define PC_E_LEN(_i)		pc_edges.edge_len[_i]
#define PC_T_E0(_i)		pc_tris.tri_edge0[_i]
#define PC_T_E1(_i)		pc_tris.tri_edge1[_i]
#define PC_T_E2(_i)		pc_tris.tri_edge2[_i]
#define PC_T_LE(_i)		pc_tris.tri_longest_edge[_i]
#define PC_T_CNT(_i)		pc_tris.tri_counter[_i]
#define PC_T_CNT_SCAN(_i)	pc_tris.tri_counter_scan[_i]
#define PC_T_RCNT(_i)		pc_tris.tri_rev_counter[_i]
#define PC_T_RCNT_SCAN(_i)	pc_tris.tri_rev_counter_scan[_i]

#define PC_FOR_EACH_T	for (int i = 0; i < pc_tri_count; i++)
#define PC_FOR_EACH_E	for (int i = 1; i < pc_edge_count; i++)
#define PC_FOR_EACH_P	for (int i = 0; i < pc_point_count; i++)

#define PC_GET_E_MARK(_i)		__GET_E_MARK(PC_E_MN(i))
#define PC_GET_E_NEXT(_i)		__GET_E_NEXT(PC_E_MN(i))

#define PC_GET_T_CNT(_i)		__GET_T_CNT(PC_T_CNT(_i))
#define PC_GET_T_CNT_SCAN(_i)		__GET_T_CNT(PC_T_CNT_SCAN(_i))
#define PC_GET_T_RCNT(_i)		__GET_T_RCNT(PC_T_RCNT(_i))
#define PC_GET_T_RCNT_SCAN(_i)		__GET_T_RCNT(PC_T_RCNT_SCAN(_i))


edge_t pc_edges;
triangle_t pc_tris;

unsigned int pc_edge_count, pc_tri_count;
unsigned int pc_newelemcount, pc_newelemcount_rev, pc_new_edge_count, pc_new_tri_count;


void refine_pass3(void)
{
	unsigned int *edge_mark_tree_next = pc_edges.edge_mark_tree_next;
	int *new_edge0 = pc_edges.new_edge0;
	int *new_edge1 = pc_edges.new_edge1;
	int *orth_edge = pc_edges.orth_edge;
	int *tri_edge0 = pc_tris.tri_edge0;
	int *tri_edge1 = pc_tris.tri_edge1;
	int *tri_edge2 = pc_tris.tri_edge2;
	int *tri_longest_edge = pc_tris.tri_longest_edge;
	unsigned int *tri_counter_scan = pc_tris.tri_counter_scan;
	unsigned int *tri_rev_counter_scan = pc_tris.tri_rev_counter_scan;

	PC_FOR_EACH_T {
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
		unsigned int tid = i;
		unsigned int mn;
		int LONGEST, RIGHT, LEFT;
		int e_ix0, e_ix1, e_ix2, LONGEST_ABS, RIGHT_ABS, LEFT_ABS, RIGHT_MARKED = 0, LEFT_MARKED = 0;
		int marked_count = 0;
		unsigned int created_tri_ix = tri_count - new_tri_count;
		unsigned int cnt, rcnt;

		if (tid >= (pc_tri_count - pc_new_tri_count))
			return;

		cnt = tri_counter_scan[tid];
		rcnt = tri_rev_counter_scan[tid];
		created_tri_ix += __GET_T_CNT(cnt) + __GET_T_RCNT(rcnt) - 1;

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

		mn = edge_mark_tree_next[RIGHT_ABS];
		if ((__GET_E_MARK(mn) & 2)) {
			marked_count++;
			RIGHT_MARKED = 1;
		}
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
		if (marked_count == 1) {
	/*Scenario #1*/	if (LONGEST > 0) {	// forward scenario
				dprintf("scenario 1\n");
				// left side
				tri_edge0[tid] = -LONGEST_SELF;
				tri_edge1[tid] = LEFT_SELF;
				tri_edge2[tid] = LONGEST_0;
				// right side
				tri_edge0[created_tri_ix] = LONGEST_SELF;
				tri_edge1[created_tri_ix] = LONGEST_1;
				tri_edge2[created_tri_ix] = RIGHT_SELF;
	/*Scenario #2*/	} else {	// backward scenario
				dprintf("scenario 2\n");
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
						dprintf("scenario 7\n");
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
						dprintf("scenario 9\n");
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
						dprintf("scenario 8\n");
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
						dprintf("scenario 10\n");
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
						dprintf("scenario 3\n");
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
						dprintf("scenario 5\n");
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
						dprintf("scenario 4\n");
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
						dprintf("scenario 6\n");
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
						dprintf("scenario 11\n");
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
						dprintf("scenario 12\n");
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
						dprintf("scenario 14\n");
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
						dprintf("scenario 13\n");
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
						dprintf("scenario 15\n");
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
						dprintf("scenario 16\n");
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
						dprintf("scenario 18\n");
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
						dprintf("scenario 17\n");
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
}

point_t get_opposite_point(int i, point_t *edge_point0, point_t *edge_point1, int *new_edge0, int *new_edge1)
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

void refine_pass2(void)
{
	unsigned int *edge_mark_tree_next = pc_edges.edge_mark_tree_next;
	point_t *edge_point0 = pc_edges.edge_point0;
	point_t *edge_point1 = pc_edges.edge_point1;
	point_t *edge_mid_p = pc_edges.edge_mid_p;
	int *new_edge0 = pc_edges.new_edge0;
	int *new_edge1 = pc_edges.new_edge1;

	PC_FOR_EACH_T {
		unsigned int tid = i;
		unsigned int mn;
		int LONGEST, RIGHT, LEFT;
		int e_ix0, e_ix1, e_ix2, LONGEST_ABS, RIGHT_ABS, LEFT_ABS;

		if (tid >= (pc_tri_count - pc_new_tri_count))
			return;

		e_ix0 = PC_T_E0(tid);
		e_ix1 = PC_T_E1(tid);
		e_ix2 = PC_T_E2(tid);
		LONGEST = PC_T_LE(tid);

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
		mn = edge_mark_tree_next[LONGEST_ABS];
		if ((__GET_E_MARK(mn) & 2)) {
			if (LONGEST > 0) {	// forward scenario
				edge_point0[LONGEST_ABS] = get_opposite_point(RIGHT, edge_point0, edge_point1, new_edge0, new_edge1);
				edge_point1[LONGEST_ABS] = edge_mid_p[LONGEST_ABS];
			}
		}

		// process right
		mn = edge_mark_tree_next[RIGHT_ABS];
		if ((__GET_E_MARK(mn) & 2)) {
			if (RIGHT > 0) {	// forward scenario
				edge_point0[RIGHT_ABS] = edge_mid_p[LONGEST_ABS];
				edge_point1[RIGHT_ABS] = edge_mid_p[RIGHT_ABS];
			}
		}

		// process left
		mn = edge_mark_tree_next[LEFT_ABS];
		if ((__GET_E_MARK(mn) & 2)) {
			if (LEFT > 0) {	// forward scenario
				edge_point0[LEFT_ABS] = edge_mid_p[LONGEST_ABS];
				edge_point1[LEFT_ABS] = edge_mid_p[LEFT_ABS];
			}
		}
	}
}

void refine_pass1(void)
{
	unsigned int *edge_mark_tree_next = pc_edges.edge_mark_tree_next;
	point_t *edge_point0 = pc_edges.edge_point0;
	point_t *edge_point1 = pc_edges.edge_point1;
	point_t *edge_mid_p = pc_edges.edge_mid_p;
	int *new_edge0 = pc_edges.new_edge0;
	int *new_edge1 = pc_edges.new_edge1;
	int *orth_edge = pc_edges.orth_edge;

	PC_FOR_EACH_T {
		unsigned int tid = i;
		unsigned int created_edge_ix = pc_edge_count - pc_new_edge_count;
		unsigned int mn;
		int LONGEST, RIGHT, LEFT;
		int e_ix0, e_ix1, e_ix2, LONGEST_ABS, RIGHT_ABS, LEFT_ABS;
		unsigned int cnt, rcnt;

		if (tid >= (pc_tri_count - pc_new_tri_count))
			return;

		cnt = PC_T_CNT_SCAN(tid);
		rcnt = PC_T_RCNT_SCAN(tid);
		created_edge_ix += 2*__GET_T_CNT(cnt) + __GET_T_RCNT(rcnt) - 1;
		e_ix0 = PC_T_E0(tid);
		e_ix1 = PC_T_E1(tid);
		e_ix2 = PC_T_E2(tid);
		LONGEST = PC_T_LE(tid);

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
}

void pc_refine(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	refine_pass1();

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);
	printf(DGREEN"[%s]"NORM" PASS1 TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	refine_pass2();

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);
	printf(DGREEN"[%s]"NORM" PASS2 TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	refine_pass3();

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);
	printf(DGREEN"[%s]"NORM" PASS3 TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);
}

int pc_realloc_tris(void)
{
	pc_tris.tri_edge0 = (int *)realloc(pc_tris.tri_edge0, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_edge0 == NULL) {
		printf("cannot realloc pc_tris.tri_edge0!\n");
		return -1;
	}

	pc_tris.tri_edge1 = (int *)realloc(pc_tris.tri_edge1, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_edge1 == NULL) {
		printf("cannot realloc pc_tris.tri_edge1!\n");
		return -1;
	}

	pc_tris.tri_edge2 = (int *)realloc(pc_tris.tri_edge2, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_edge2 == NULL) {
		printf("cannot realloc pc_tris.tri_edge2!\n");
		return -1;
	}

	pc_tris.tri_longest_edge = (int *)realloc(pc_tris.tri_longest_edge, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_longest_edge == NULL) {
		printf("cannot realloc pc_tris.tri_longest_edge!\n");
		return -1;
	}

	pc_tris.tri_counter = (unsigned int *)realloc(pc_tris.tri_counter, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_counter == NULL) {
		printf("cannot realloc pc_tris.tri_counter!\n");
		return -1;
	}

	pc_tris.tri_counter_scan = (unsigned int *)realloc(pc_tris.tri_counter_scan, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_counter_scan == NULL) {
		printf("cannot realloc pc_tris.tri_counter_scan!\n");
		return -1;
	}

	pc_tris.tri_rev_counter = (unsigned int *)realloc(pc_tris.tri_rev_counter, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_rev_counter == NULL) {
		printf("cannot realloc pc_tris.tri_rev_counter!\n");
		return -1;
	}

	pc_tris.tri_rev_counter_scan = (unsigned int *)realloc(pc_tris.tri_rev_counter_scan, (pc_tri_count + pc_new_tri_count)*sizeof(int));
	if (pc_tris.tri_rev_counter_scan == NULL) {
		printf("cannot realloc pc_tris.tri_rev_counter_scan!\n");
		return -1;
	}

	return 0;
}

int pc_realloc_edges(void)
{
	pc_edges.edge_point0 = (point_t *)realloc(pc_edges.edge_point0, (pc_edge_count + pc_new_edge_count)*sizeof(point_t));
	if (pc_edges.edge_point0 == NULL) {
		printf("cannot realloc edge_point0 arr!\n");
		return -1;
	}

	pc_edges.edge_point1 = (point_t *)realloc(pc_edges.edge_point1, (pc_edge_count + pc_new_edge_count)*sizeof(point_t));
	if (pc_edges.edge_point1 == NULL) {
		printf("cannot realloc edge_point1 arr!\n");
		return -1;
	}

	pc_edges.edge_mid_p = (point_t *)realloc(pc_edges.edge_mid_p, (pc_edge_count + pc_new_edge_count)*sizeof(point_t));
	if (pc_edges.edge_mid_p == NULL) {
		printf("cannot realloc edge_mid_p arr!\n");
		return -1;
	}

	pc_edges.edge_len = (float *)realloc(pc_edges.edge_len, (pc_edge_count + pc_new_edge_count)*sizeof(float));
	if (pc_edges.edge_len == NULL) {
		printf("cannot realloc edge_len arr!\n");
		return -1;
	}

	pc_edges.edge_mark_tree_next = (unsigned int *)realloc(pc_edges.edge_mark_tree_next, (pc_edge_count + pc_new_edge_count)*sizeof(int));
	if (pc_edges.edge_mark_tree_next == NULL) {
		printf("cannot realloc edge_mark_tree_next arr!\n");
		return -1;
	}

	pc_edges.new_edge0 = (int *)realloc(pc_edges.new_edge0, (pc_edge_count + pc_new_edge_count)*sizeof(int));
	if (pc_edges.new_edge0 == NULL) {
		printf("cannot realloc new_edge0 arr!\n");
		return -1;
	}

	pc_edges.new_edge1 = (int *)realloc(pc_edges.new_edge1, (pc_edge_count + pc_new_edge_count)*sizeof(int));
	if (pc_edges.new_edge1 == NULL) {
		printf("cannot realloc new_edge1 arr!\n");
		return -1;
	}

	pc_edges.orth_edge = (int *)realloc(pc_edges.orth_edge, (pc_edge_count + pc_new_edge_count)*sizeof(int));
	if (pc_edges.orth_edge == NULL) {
		printf("cannot realloc orth_edge arr!\n");
		return -1;
	}

	return 0;
}

void pc_create_new_elem_arrs(void)
{
	pc_new_edge_count = 2*__GET_T_CNT(pc_newelemcount) + __GET_T_RCNT(pc_newelemcount_rev);
	pc_new_tri_count = __GET_T_CNT(pc_newelemcount) + __GET_T_RCNT(pc_newelemcount_rev);

	printf("new_edge_count=%d new_tri_count=%d\n", pc_new_edge_count, pc_new_tri_count);

	if (pc_realloc_edges() < 0) {
		printf("host realloc error\n");
		exit(1);
	}

	if (pc_realloc_tris() < 0) {
		printf("host realloc error\n");
		exit(1);
	}

	pc_edge_count += pc_new_edge_count;
	pc_tri_count += pc_new_tri_count;
}

void pc_prefix_counters(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	PC_FOR_EACH_T {
		if (!i)
			continue;
	
		PC_T_CNT(i) += PC_T_CNT(i-1);
		PC_T_RCNT(i) += PC_T_RCNT(i-1);
	}

	pc_newelemcount = PC_T_CNT(pc_tri_count-1);
	pc_newelemcount_rev = PC_T_RCNT(pc_tri_count-1);

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	// bilal: workaround: since we cannot get the scan directly to tri_counter_scan
	memcpy(pc_tris.tri_counter_scan, pc_tris.tri_counter, pc_tri_count*sizeof(int));
	memcpy(pc_tris.tri_rev_counter_scan, pc_tris.tri_rev_counter, pc_tri_count*sizeof(int));
}

void pc_get_counters(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	PC_FOR_EACH_T {
		int p_counter = 0, p_rev_counter = 0, e_ix;
		unsigned int mn;

		e_ix = PC_T_E0(i);
		mn = PC_E_MN(abs(e_ix));
		if ((__GET_E_MARK(mn) & 2)) {
			if (e_ix >= 0)
				p_counter++;
			else
				p_rev_counter++;
		}

		e_ix = PC_T_E1(i);
		mn = PC_E_MN(abs(e_ix));
		if ((__GET_E_MARK(mn) & 2)) {
			if (e_ix >= 0)
				p_counter++;
			else
				p_rev_counter++;
		}

		e_ix = PC_T_E2(i);
		mn = PC_E_MN(abs(e_ix));
		if ((__GET_E_MARK(mn) & 2)) {
			if (e_ix >= 0)
				p_counter++;
			else
				p_rev_counter++;
		}

		PC_T_CNT(i) = p_counter;
		PC_T_RCNT(i) = p_rev_counter;
	}

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);
}

void pc_follow_links(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	unsigned int *edge_mark_tree_next = pc_edges.edge_mark_tree_next;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	PC_FOR_EACH_E {
		unsigned int mn, next_mn;
		int next_ix;
		int tid = i;

		mn = edge_mark_tree_next[tid];
		if (!(__GET_E_MARK(mn) & 2)) {	// not marked
			continue;
		}

		next_ix = __GET_E_NEXT(mn);
		if (!next_ix || (next_ix == NO_LINK)) {
			continue;
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

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);
}

void pc_correct_marks(void)
{
	PC_FOR_EACH_E {
		if (PC_E_LEN(i) < 0)
			PC_E_MN(i) |= 2;
	}
}

void pc_establish_links(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	PC_FOR_EACH_T {
		int edge, ledge;
		unsigned int mn;

		ledge = PC_T_LE(i);

		edge = abs(PC_T_E0(i));
		if (edge != ledge) {
			mn = PC_E_MN(edge);
			if (__GET_E_MARK(mn) & 1) {
				__SET_E_NEXT(mn, ledge);
				PC_E_MN(edge) = mn;
			}
		}

		edge = abs(PC_T_E1(i));
		if (edge != ledge) {
			mn = PC_E_MN(edge);
			if (__GET_E_MARK(mn) & 1) {
				__SET_E_NEXT(mn, ledge);
				PC_E_MN(edge) = mn;
			}
		}

		edge = abs(PC_T_E2(i));
		if (edge != ledge) {
			mn = PC_E_MN(edge);
			if (__GET_E_MARK(mn) & 1) {
				__SET_E_NEXT(mn, ledge);
				PC_E_MN(edge) = mn;
			}
		}
	}

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);
}

void pc_mark_longest_edges(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	PC_FOR_EACH_T {
		float llen = 0, clen;
		int ledge;
		int edge_ix;

		edge_ix = abs(PC_T_E0(i));
		clen = abs(PC_E_LEN(edge_ix));
		if (clen > llen) {
			llen = clen;
			ledge = edge_ix;
		}

		edge_ix = abs(PC_T_E1(i));
		clen = abs(PC_E_LEN(edge_ix));
		if (clen > llen) {
			llen = clen;
			ledge = edge_ix;
		}

		edge_ix = abs(PC_T_E2(i));
		clen = abs(PC_E_LEN(edge_ix));
		if (clen > llen) {
			llen = clen;
			ledge = edge_ix;
		}

		if (PC_T_LE(i) == 1) {
			PC_E_LEN(ledge) = -llen;	// negative edge len is blackmark
		}

		PC_E_MN(ledge) = 1;		// mark as longest edge
		PC_T_LE(i) = ledge;
	}

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);
}

static inline point_t calc_mid_point(point_t *p1, point_t *p2)
{
	point_t ret;

	ret.x = (p1->x + p2->x) / 2;
	ret.y = (p1->y + p2->y) / 2;

	return ret;
}

void pc_calc_edge_lengths_mid_p(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	printf(DGREEN"[%s]"NORM" WORK STARTED\n", __func__);
	fflush(stdout);
	usleep(100000);
	gettimeofday(&start_time, NULL);

	PC_FOR_EACH_E {
		point_t p0, p1, mid_p;
		float len;

		p0 = PC_E_P0(i);
		p1 = PC_E_P1(i);

		len = sqrtf(powf(fabs(p0.x - p1.x), 2) + powf(fabs(p0.y - p1.y), 2));
		mid_p = calc_mid_point(&p0, &p1);

		PC_E_LEN(i) = len;
		PC_E_MIDP(i) = mid_p;
	}

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf(DGREEN"[%s]"NORM" TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);
}

void pc_print_input(void)
{
	printf("Edges:\n");
	PC_FOR_EACH_E {
		printf("edge[%d]=[%f,%f]\t[%f,%f]\tmid=[%f,%f]\tlen=%f\tmark=%d\tnext=%d\tnew_edges={%d, %d, orth=%d}\n", i, PC_E_P0(i).x, PC_E_P0(i).y, PC_E_P1(i).x, PC_E_P1(i).y, PC_E_MIDP(i).x, PC_E_MIDP(i).y,  PC_E_LEN(i), PC_GET_E_MARK(i), (PC_GET_E_NEXT(i) != NO_LINK) ? (int)PC_GET_E_NEXT(i) : -1, PC_E_NE0(i), PC_E_NE1(i), PC_E_OE(i));
	}

	printf("Triangles:\n");
	PC_FOR_EACH_T {
		printf("triangle[%d]=%d %d %d longest=%d\tcounter=%d rev_counter=%d\tcounter_scan=%d counter_scan_rev=%d\n", i, PC_T_E0(i), PC_T_E1(i), PC_T_E2(i), PC_T_LE(i), PC_GET_T_CNT(i), PC_GET_T_RCNT(i), PC_GET_T_CNT_SCAN(i), PC_GET_T_RCNT_SCAN(i));
	}

	return;
}

int mesh_refine_pc(int only_pc)
{
	printf("PC Starting process...\n");

#if 1
	if (debug)
		pc_print_input();
#endif

	// bilal: workaround for floating point problem! skip step 1 if the code runs on device
	if (only_pc) {
		// step 1: calculate edge lengths and mid points
		pc_calc_edge_lengths_mid_p();
	}

	// step 2: mark longest edge of each triangle
	pc_mark_longest_edges();

	// step 3: establish links
	pc_establish_links();

	// step 4: follow links
	pc_correct_marks();
	pc_follow_links();

	// step 5: get the initial value of counters
	pc_get_counters();

	// step 6: prefix the counters
	pc_prefix_counters();

	pc_create_new_elem_arrs();

	// step 7: refine the mesh: create new edges
	pc_refine();

#if 1
	if (debug)
		pc_print_input();
#endif

	return 0;
}

int compare_results(void)
{
	int ret = 0;

	// sanity checks

	// check triangles having valid edge
	PC_FOR_EACH_T {
		if ((PC_T_E0(i) == 0) || (abs(PC_T_E0(i)) >= pc_edge_count) || (PC_T_E1(i) == 0) || (abs(PC_T_E1(i)) >= pc_edge_count) || (PC_T_E2(i) == 0) || (abs(PC_T_E2(i)) >= pc_edge_count)) {
			printf("PC sanity failed on triangle: %d\n", i);
			ret = -1;
		}
	}

	FOR_EACH_T {
		if ((T_E0(i) == 0) || (abs(T_E0(i)) >= edge_count) || (T_E1(i) == 0) || (abs(T_E1(i)) >= edge_count) || (T_E2(i) == 0) || (abs(T_E2(i)) >= edge_count)) {
			printf("sanity failed on triangle: %d\n", i);
			ret = -1;
		}
	}

	// check mark and next consistency
	FOR_EACH_E {
		if (i >= (edge_count - new_edge_count))
			break;
		if ((GET_E_MARK(i) == 3) && (GET_E_NEXT(i) != NO_LINK) && (GET_E_NEXT(i) != 0)) {
			printf("sanity failed on edge: %d mark=%d next=%d\n", i, GET_E_MARK(i), GET_E_NEXT(i));
		}
	}

	FOR_EACH_E {
		if (i >= (pc_edge_count - pc_new_edge_count))
			break;
		if ((PC_GET_E_MARK(i) == 3) && (PC_GET_E_NEXT(i) != NO_LINK) && (PC_GET_E_NEXT(i) != 0)) {
			printf("PC sanity failed on edge: %d mark=%d next=%d\n", i, PC_GET_E_MARK(i), PC_GET_E_NEXT(i));
		}
	}

	// check counter have a valid value
	FOR_EACH_T {
		if (!i)
			continue;
		if (i >= (pc_tri_count - pc_new_tri_count))
			break;
		if (((PC_T_CNT(i) + PC_T_RCNT(i)) - (PC_T_CNT(i-1) + PC_T_RCNT(i-1))) > 3) {
			printf("PC sanity failed on triangle: %d\n", i);
		}
	}

	FOR_EACH_T {
		if (i >= (tri_count - new_tri_count))
			break;
		if ((T_CNT(i) + T_RCNT(i)) > 3) {
			printf("sanity failed on triangle: %d\n", i);
		}
	}

	// comparisons

	if (pc_edge_count != edge_count) {
		printf("edge count mismatch: %d != %d\n", pc_edge_count, edge_count);
		return -1;
	}

	if (pc_tri_count != tri_count) {
		printf("tri count mismatch: %d != %d\n", pc_tri_count, tri_count);
		return -1;
	}

	if (pc_new_edge_count != new_edge_count) {
		printf("new edge count mismatch: %d != %d\n", pc_new_edge_count, new_edge_count);
		return -1;
	}

	if (pc_new_tri_count != new_tri_count) {
		printf("new tri count mismatch: %d != %d\n", pc_new_tri_count, new_tri_count);
		return -1;
	}

	FOR_EACH_E {
		if ((PC_E_P0(i).x != E_P0(i).x) || (PC_E_P0(i).y != E_P0(i).y) || (PC_E_P1(i).x != E_P1(i).x) || (PC_E_P1(i).y != E_P1(i).y)) {
			printf("edge mismatch on %d\n", i);
			ret = -1;
		}
	}

	FOR_EACH_T {
		if ((PC_T_E0(i) != T_E0(i)) || (PC_T_E1(i) != T_E1(i)) || (PC_T_E2(i) != T_E2(i)) /*|| (T(i).er.longest_edge_ix != CUDA_T(i).er.longest_edge_ix)*/) {
			printf("triangle mismatch on %d\n", i);
			ret = -1;
		}
	}

	return ret;
}

void pc_copy_tris(void)
{
	memcpy(pc_tris.tri_edge0, tris.tri_edge0, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_edge1, tris.tri_edge1, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_edge2, tris.tri_edge2, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_longest_edge, tris.tri_longest_edge, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_counter, tris.tri_counter, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_counter_scan, tris.tri_counter_scan, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_rev_counter, tris.tri_rev_counter, sizeof(int)*tri_count);
	memcpy(pc_tris.tri_rev_counter_scan, tris.tri_rev_counter_scan, sizeof(int)*tri_count);
}

int pc_alloc_tris(void)
{
	pc_tri_count = tri_count;

	pc_tris.tri_edge0 = (int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_edge0 == NULL) {
		printf("cannot alloc tris.tri_edge0!\n");
		return -1;
	}

	pc_tris.tri_edge1 = (int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_edge1 == NULL) {
		printf("cannot alloc tris.tri_edge1!\n");
		return -1;
	}

	pc_tris.tri_edge2 = (int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_edge2 == NULL) {
		printf("cannot alloc tris.tri_edge2!\n");
		return -1;
	}

	pc_tris.tri_longest_edge = (int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_longest_edge == NULL) {
		printf("cannot alloc tris.tri_longest_edge!\n");
		return -1;
	}

	pc_tris.tri_counter = (unsigned int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_counter == NULL) {
		printf("cannot alloc tris.tri_counter!\n");
		return -1;
	}

	pc_tris.tri_counter_scan = (unsigned int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_counter_scan == NULL) {
		printf("cannot alloc tris.tri_counter_scan!\n");
		return -1;
	}

	pc_tris.tri_rev_counter = (unsigned int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_rev_counter == NULL) {
		printf("cannot alloc tris.tri_rev_counter!\n");
		return -1;
	}

	pc_tris.tri_rev_counter_scan = (unsigned int *)calloc(pc_tri_count, sizeof(int));
	if (pc_tris.tri_rev_counter_scan == NULL) {
		printf("cannot alloc tris.tri_rev_counter_scan!\n");
		return -1;
	}

	return 0;
}

void pc_copy_edges(void)
{
	memcpy(pc_edges.edge_point0, edges.edge_point0, sizeof(point_t)*edge_count);
	memcpy(pc_edges.edge_point1, edges.edge_point1, sizeof(point_t)*edge_count);
	memcpy(pc_edges.edge_mid_p, edges.edge_mid_p, sizeof(point_t)*edge_count);
	memcpy(pc_edges.edge_len, edges.edge_len, sizeof(float)*edge_count);
	memcpy(pc_edges.edge_mark_tree_next, edges.edge_mark_tree_next, sizeof(int)*edge_count);
	memcpy(pc_edges.new_edge0, edges.new_edge0, sizeof(int)*edge_count);
	memcpy(pc_edges.new_edge1, edges.new_edge1, sizeof(int)*edge_count);
	memcpy(pc_edges.orth_edge, edges.orth_edge, sizeof(int)*edge_count);
}

int pc_alloc_edges(void)
{
	pc_edge_count = edge_count;

	pc_edges.edge_point0 = (point_t *)calloc(pc_edge_count, sizeof(point_t));
	if (pc_edges.edge_point0 == NULL) {
		printf("cannot alloc edge_point0 arr!\n");
		return -1;
	}

	pc_edges.edge_point1 = (point_t *)calloc(pc_edge_count, sizeof(point_t));
	if (pc_edges.edge_point1 == NULL) {
		printf("cannot alloc edge_point1 arr!\n");
		return -1;
	}

	pc_edges.edge_mid_p = (point_t *)calloc(pc_edge_count, sizeof(point_t));
	if (pc_edges.edge_mid_p == NULL) {
		printf("cannot alloc edge_mid_p arr!\n");
		return -1;
	}

	pc_edges.edge_len = (float *)calloc(pc_edge_count, sizeof(float));
	if (pc_edges.edge_len == NULL) {
		printf("cannot alloc edge_len arr!\n");
		return -1;
	}

	pc_edges.edge_mark_tree_next = (unsigned int *)calloc(pc_edge_count, sizeof(int));
	if (pc_edges.edge_mark_tree_next == NULL) {
		printf("cannot alloc edge_mark_tree_next arr!\n");
		return -1;
	}

	pc_edges.new_edge0 = (int *)calloc(pc_edge_count, sizeof(int));
	if (pc_edges.new_edge0 == NULL) {
		printf("cannot alloc new_edge0 arr!\n");
		return -1;
	}

	pc_edges.new_edge1 = (int *)calloc(pc_edge_count, sizeof(int));
	if (pc_edges.new_edge1 == NULL) {
		printf("cannot alloc new_edge1 arr!\n");
		return -1;
	}

	pc_edges.orth_edge = (int *)calloc(pc_edge_count, sizeof(int));
	if (pc_edges.orth_edge == NULL) {
		printf("cannot alloc orth_edge arr!\n");
		return -1;
	}

	return 0;
}

int pc_alloc_copy_input(void)
{
	if (pc_alloc_edges() < 0) {
		printf("pc alloc error\n");
		return -1;
	}

	pc_copy_edges();

	if (pc_alloc_tris() < 0) {
		printf("pc alloc error\n");
		return -1;
	}

	pc_copy_tris();

	return 0;
}

int pc_write_edges(FILE *outfile)
{
	printf("Writing %d edges... ", pc_edge_count - 1);
	fflush(stdout);

	fprintf(outfile, "#edges\n");
	fprintf(outfile, "%d\n", pc_edge_count - 1);

	PC_FOR_EACH_E {
		fprintf(outfile, "[%.17g %.17g] \t[%.17g %.17g]\n", PC_E_P0(i).x, PC_E_P0(i).y, PC_E_P1(i).x, PC_E_P1(i).y);
	}

	fprintf(outfile, "\n");

	printf("OK, ");
	return 0;
}

int pc_write_triangles(FILE *outfile)
{
	printf("Writing %d triangles... ", pc_tri_count);
	fflush(stdout);

	fprintf(outfile, "#triangles\n");
	fprintf(outfile, "%d\n", pc_tri_count);

	PC_FOR_EACH_T {
		// TODO: refine edilenleri bul
		fprintf(outfile, "%d \t%d \t%d \t%d\n", PC_T_E0(i), PC_T_E1(i), PC_T_E2(i), 0);
	}

	fprintf(outfile, "\n");

	printf("OK, ");
	return 0;
}

int pc_write_output(FILE *outfile)
{
	printf("Generating PC output file... ");
	fflush(stdout);

#if 0
	if (write_points(outfile) < 0) {
		printf("error on writing points!\n");
		return -1;
	}
#endif
	if (pc_write_edges(outfile) < 0) {
		printf("error on writing edges!\n");
		return -1;
	}

	if (pc_write_triangles(outfile) < 0) {
		printf("error on writing triangles!\n");
		return -1;
	}

	printf("DONE!\n");

	return 0;
}
