
#ifndef __MAIN_H__
#define __MAIN_H__

#define dprintf(args...)	do { if (debug) printf(args); } while (0)

#define cudaSafeCall(err)		if (cudaSuccess != err) { printf(RED"error in %s:%d\n"NORM, __func__, __LINE__); exit(1); }

#define E_P0(_i)	edges.edge_point0[_i]
#define E_P1(_i)	edges.edge_point1[_i]
#define E_MIDP(_i)	edges.edge_mid_p[_i]
#define E_MN(_i)	edges.edge_mark_tree_next[_i]
#define E_NE0(_i)	edges.new_edge0[_i]
#define E_NE1(_i)	edges.new_edge1[_i]
#define E_OE(_i)	edges.orth_edge[_i]
#define E_LEN(_i)	edges.edge_len[_i]
#define P(_i)		point_arr[_i]
#define T_E0(_i)	tris.tri_edge0[_i]
#define T_E1(_i)	tris.tri_edge1[_i]
#define T_E2(_i)	tris.tri_edge2[_i]
#define T_LE(_i)	tris.tri_longest_edge[_i]
#define T_CNT(_i)	tris.tri_counter[_i]
#define T_CNT_SCAN(_i)	tris.tri_counter_scan[_i]
#define T_RCNT(_i)	tris.tri_rev_counter[_i]
#define T_RCNT_SCAN(_i)	tris.tri_rev_counter_scan[_i]

#define FOR_EACH_T	for (int i = 0; i < tri_count; i++)
#define FOR_EACH_E	for (int i = 1; i < edge_count; i++)
#define FOR_EACH_P	for (int i = 0; i < point_count; i++)

#define __GET_E_MARK(_v)	((_v) & MARK_MASK)
#define GET_E_MARK(_i)		__GET_E_MARK(E_MN(i))
#define __GET_E_NEXT(_v)	(((_v) & LINK_MASK) >> LINK_SHIFT)
#define GET_E_NEXT(_i)		__GET_E_NEXT(E_MN(i))
#define CLEAR_NEXT(_v)		(_v &= ~LINK_MASK)
#define __SET_E_NEXT(_v, _val)	do { CLEAR_NEXT(_v); _v |= (((_val) << LINK_SHIFT) & LINK_MASK); } while (0)

#define __GET_T_CNT(_c)		(_c)
#define GET_T_CNT(_i)		__GET_T_CNT(T_CNT(_i))
#define GET_T_CNT_SCAN(_i)	__GET_T_CNT(T_CNT_SCAN(_i))
#define __GET_T_RCNT(_c)	(_c)
#define GET_T_RCNT(_i)		__GET_T_RCNT(T_RCNT(_i))
#define GET_T_RCNT_SCAN(_i)	__GET_T_RCNT(T_RCNT_SCAN(_i))


#define WHITE   "\033[37;1m"
#define BLUE    "\033[34;1m"
#define RED     "\033[31;1m"
#define GREEN   "\033[32;1m"
#define YELLOW  "\033[33;1m"
#define DGREEN  "\033[32;2m"
#define NORM    "\033[0m"

#define NO_LINK		1073741823u
#define LINK_MASK	0xFFFFFFFC
#define LINK_SHIFT	2
#define MARK_MASK	0x3


typedef struct point		point_t;
typedef struct edge		edge_t;
typedef struct triangle		triangle_t;

struct __align__(8) point {
	float x;
	float y;
};

struct edge {
	point_t *edge_point0;
	point_t *edge_point1;
	point_t *edge_mid_p;
	float *edge_len;
	unsigned int *edge_mark_tree_next;
	int *new_edge0;
	int *new_edge1;
	int *orth_edge;
};

struct triangle {
	int *tri_edge0;
	int *tri_edge1;
	int *tri_edge2;
	int *tri_longest_edge;
	unsigned int *tri_counter;
	unsigned int *tri_rev_counter;
	unsigned int *tri_counter_scan;
	unsigned int *tri_rev_counter_scan;
};

extern int debug;
extern int threadsPerBlock;
extern point_t *point_arr;
extern edge_t edges;
extern edge_t *d_edges;
extern triangle_t tris;
extern triangle_t *d_tris;

extern unsigned int point_count, edge_count, tri_count;
extern unsigned int newelemcount, newelemcount_rev, new_edge_count, new_tri_count;
extern int refine_count;

unsigned long get_time_diff_us(struct timeval *start, struct timeval *end);

// io.cu
int copy_back_edges(void);
int copy_back(void);
void device_cleanup(void);
int malloc_copy_input_to_device(void);
int malloc_copy_input_to_device2(void);
int validate_input(void);
void print_input(void);
int read_input_file(FILE *infile);
int write_output(FILE *outfile);
int read_node_file(FILE *infile);
int read_ele_file(FILE *infile);

// edge_ops.cu
void follow_links(void);
void establish_links(void);
void mark_longest_edges(void);
void calc_edge_lengths_mid_p(void);

// tri_ops.cu
void prefix_counters(void);
void get_counters(void);

// refine.cu
void refine(void);
void create_new_elem_arrs(void);

// mesh_refine_pc.cu
int mesh_refine_pc(int only_pc);
int compare_results(void);
int pc_alloc_copy_input(void);
void pc_copy_edges(void);
int pc_write_output(FILE *outfile);

#endif	//__MAIN_H__
