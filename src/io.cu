
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <sys/time.h>

#include <main.h>

#define MAX_LINE_SIZE		1024

#define TOLERANCE			0.000001
#define COMPARE_FLOAT2(_f1, _f2)	(fabs(_f1 - _f2) > TOLERANCE)

typedef struct tri_point	tri_point_t;
typedef struct in_edge		in_edge_t;

struct tri_point {
	int point[3];
};

struct in_edge {
	int point_ix[2];
	int next;
};

tri_point_t *tri_point_arr;
in_edge_t *in_edge_arr;

unsigned int in_edge_count;


int get_rand_int(int min, int max)
{
	return min+(rand()%(max - min));
}

int copy_back_tris(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	gettimeofday(&start_time, NULL);

	cudaSafeCall(cudaMemcpy(tris.tri_edge0, d_tris->tri_edge0, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_edge1, d_tris->tri_edge1, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_edge2, d_tris->tri_edge2, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_longest_edge, d_tris->tri_longest_edge, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_counter, d_tris->tri_counter, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_counter_scan, d_tris->tri_counter_scan, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_rev_counter, d_tris->tri_rev_counter, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(tris.tri_rev_counter_scan, d_tris->tri_rev_counter_scan, sizeof(int)*tri_count, cudaMemcpyDeviceToHost));

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf("[%s] MEMCPY TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	return 0;
}

int copy_back_edges(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;

	gettimeofday(&start_time, NULL);

	cudaSafeCall(cudaMemcpy(edges.edge_point0, d_edges->edge_point0, sizeof(point_t)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.edge_point1, d_edges->edge_point1, sizeof(point_t)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.edge_mid_p, d_edges->edge_mid_p, sizeof(point_t)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.edge_len, d_edges->edge_len, sizeof(float)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.edge_mark_tree_next, d_edges->edge_mark_tree_next, sizeof(int)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.new_edge0, d_edges->new_edge0, sizeof(int)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.new_edge1, d_edges->new_edge1, sizeof(int)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.orth_edge, d_edges->orth_edge, sizeof(int)*edge_count, cudaMemcpyDeviceToHost));

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf("[%s] MEMCPY TIME ELAPSED = %lu usecs\n", __func__, time_elapsed);

	return 0;
}

int copy_back(void)
{
	copy_back_edges();
	copy_back_tris();

	return 0;
}

void device_cleanup(void)
{
	if (d_edges->edge_point0) {
		cudaSafeCall(cudaFree((void*)d_edges->edge_point0));
		cudaSafeCall(cudaFree((void*)d_edges->edge_point1));
		cudaSafeCall(cudaFree((void*)d_edges->edge_mid_p));
		cudaSafeCall(cudaFree((void*)d_edges->edge_len));
		cudaSafeCall(cudaFree((void*)d_edges->edge_mark_tree_next));
		cudaSafeCall(cudaFree((void*)d_edges->new_edge0));
		cudaSafeCall(cudaFree((void*)d_edges->new_edge1));
		cudaSafeCall(cudaFree((void*)d_edges->orth_edge));
		d_edges->edge_point0 = NULL;
	}

	if (d_tris->tri_edge0) {
		cudaSafeCall(cudaFree((void*)d_tris->tri_edge0));
		cudaSafeCall(cudaFree((void*)d_tris->tri_edge1));
		cudaSafeCall(cudaFree((void*)d_tris->tri_edge2));
		cudaSafeCall(cudaFree((void*)d_tris->tri_longest_edge));
		cudaSafeCall(cudaFree((void*)d_tris->tri_counter));
		cudaSafeCall(cudaFree((void*)d_tris->tri_counter_scan));
		cudaSafeCall(cudaFree((void*)d_tris->tri_rev_counter));
		cudaSafeCall(cudaFree((void*)d_tris->tri_rev_counter_scan));
		d_tris->tri_edge0 = NULL;
	}
}

int malloc_copy_input_to_device(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	unsigned int edge_size, tri_size, copy_edge_size, copy_tri_size;

	edge_size = 3*sizeof(point_t)*edge_count + sizeof(float)*edge_count + 4*sizeof(int)*edge_count;
	tri_size = 8*sizeof(int)*tri_count;
	copy_edge_size = 2*sizeof(point_t)*edge_count + 2*sizeof(int)*edge_count;
	copy_tri_size = 4*sizeof(int)*tri_count;

	printf("Total allocated memory = %u + %u bytes [%.1lf MB]\n", edge_size, tri_size, (double)(edge_size + tri_size)/(1024*1024));

	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_point0, sizeof(point_t)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_point1, sizeof(point_t)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_mid_p, sizeof(point_t)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_len, sizeof(float)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_mark_tree_next, sizeof(int)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->new_edge0, sizeof(int)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->new_edge1, sizeof(int)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->orth_edge, sizeof(int)*edge_count));

	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_edge0, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_edge1, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_edge2, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_longest_edge, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_counter, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_counter_scan, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_rev_counter, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_rev_counter_scan, sizeof(int)*tri_count));

	gettimeofday(&start_time, NULL);

	cudaSafeCall(cudaMemcpy(d_tris->tri_edge0, tris.tri_edge0, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_edge1, tris.tri_edge1, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_edge2, tris.tri_edge2, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_longest_edge, tris.tri_longest_edge, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_tris->tri_counter, tris.tri_counter, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_tris->tri_counter_scan, tris.tri_counter_scan, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_tris->tri_rev_counter, tris.tri_rev_counter, sizeof(int)*tri_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_tris->tri_rev_counter_scan, tris.tri_rev_counter_scan, sizeof(int)*tri_count, cudaMemcpyHostToDevice));

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf("[%s] TRIS MEMCPY TIME ELAPSED = %lu usecs [%f MB/s]\n", __func__, time_elapsed, (double)copy_tri_size / time_elapsed);

	gettimeofday(&start_time, NULL);

	cudaSafeCall(cudaMemcpy(d_edges->edge_point0, edges.edge_point0, sizeof(point_t)*edge_count, cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->edge_point1, edges.edge_point1, sizeof(point_t)*edge_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_edges->edge_mid_p, edges.edge_mid_p, sizeof(point_t)*edge_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_edges->edge_len, edges.edge_len, sizeof(float)*edge_count, cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->edge_mark_tree_next, edges.edge_mark_tree_next, sizeof(int)*edge_count, cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->new_edge0, edges.new_edge0, sizeof(int)*edge_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_edges->new_edge1, edges.new_edge1, sizeof(int)*edge_count, cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_edges->orth_edge, edges.orth_edge, sizeof(int)*edge_count, cudaMemcpyHostToDevice));

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf("[%s] EDGES MEMCPY TIME ELAPSED = %lu usecs [%lf MB/s]\n", __func__, time_elapsed, (double)copy_edge_size / time_elapsed);

	return 0;
}

int malloc_copy_input_to_device2(void)
{
	struct timeval start_time, end_time;
	unsigned long time_elapsed = 0;
	unsigned int edge_size, tri_size, copy_edge_size, copy_tri_size;

	edge_size = 3*sizeof(point_t)*edge_count + sizeof(float)*edge_count + 4*sizeof(int)*edge_count;
	tri_size = 8*sizeof(int)*tri_count;
	copy_edge_size = 3*sizeof(point_t)*(edge_count-new_edge_count) + 4*sizeof(int)*(edge_count-new_edge_count);
	copy_tri_size = 8*sizeof(int)*(tri_count-new_tri_count);

	printf("Total allocated memory = %u + %u bytes [%.1lf MB]\n", edge_size, tri_size, (double)(edge_size + tri_size)/(1024*1024));

	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_point0, sizeof(point_t)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_point1, sizeof(point_t)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_mid_p, sizeof(point_t)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_len, sizeof(float)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->edge_mark_tree_next, sizeof(int)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->new_edge0, sizeof(int)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->new_edge1, sizeof(int)*edge_count));
	cudaSafeCall(cudaMalloc((void**)&d_edges->orth_edge, sizeof(int)*edge_count));

	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_edge0, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_edge1, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_edge2, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_longest_edge, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_counter, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_counter_scan, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_rev_counter, sizeof(int)*tri_count));
	cudaSafeCall(cudaMalloc((void**)&d_tris->tri_rev_counter_scan, sizeof(int)*tri_count));

	gettimeofday(&start_time, NULL);

	cudaSafeCall(cudaMemcpy(d_tris->tri_edge0, tris.tri_edge0, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_edge1, tris.tri_edge1, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_edge2, tris.tri_edge2, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_longest_edge, tris.tri_longest_edge, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_counter, tris.tri_counter, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_counter_scan, tris.tri_counter_scan, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_rev_counter, tris.tri_rev_counter, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_tris->tri_rev_counter_scan, tris.tri_rev_counter_scan, sizeof(int)*(tri_count-new_tri_count), cudaMemcpyHostToDevice));

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf("[%s] TRIS MEMCPY TIME ELAPSED = %lu usecs [%f MB/s]\n", __func__, time_elapsed, (double)copy_tri_size / time_elapsed);

	gettimeofday(&start_time, NULL);

	cudaSafeCall(cudaMemcpy(d_edges->edge_point0, edges.edge_point0, sizeof(point_t)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->edge_point1, edges.edge_point1, sizeof(point_t)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->edge_mid_p, edges.edge_mid_p, sizeof(point_t)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	//cudaSafeCall(cudaMemcpy(d_edges->edge_len, edges.edge_len, sizeof(float)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->edge_mark_tree_next, edges.edge_mark_tree_next, sizeof(int)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->new_edge0, edges.new_edge0, sizeof(int)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->new_edge1, edges.new_edge1, sizeof(int)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));
	cudaSafeCall(cudaMemcpy(d_edges->orth_edge, edges.orth_edge, sizeof(int)*(edge_count-new_edge_count), cudaMemcpyHostToDevice));

	cudaSafeCall(cudaThreadSynchronize());

	gettimeofday(&end_time, NULL);
	time_elapsed = get_time_diff_us(&start_time, &end_time);

	printf("[%s] EDGES MEMCPY TIME ELAPSED = %lu usecs [%lf MB/s]\n", __func__, time_elapsed, (double)copy_edge_size / time_elapsed);

	return 0;
}

char *readline(char *string, FILE *infile)
{
	char *result = NULL;
	
	/* Search for something that looks like a number. */
	do
	{
		result = fgets(string, MAX_LINE_SIZE, infile);
		if (result == (char *) NULL)
		{
			printf("Error:  Unexpected end of file\n");
			return NULL;
		}

		/* Skip anything that doesn't look like a number, a comment, */
		/*   or the end of a line.                                   */
		while ((*result != '\0') && (*result != '#')
			&& (*result != '.') && (*result != '+') && (*result != '-')
			&& ((*result < '0') || (*result > '9')))
		{
			result++;
		}
		/* If it's a comment or end of line, read another line and try again. */
	} while ((*result == '#') || (*result == '\0'));

	return result;
}

char *findfield(char *string)
{
	char *result;
	
	result = string;
	/* Skip the current field.  Stop upon reaching whitespace. */
	while ((*result != '\0') && (*result != '#')
		&& (*result != ' ') && (*result != '\t'))
	{
		result++;
	}
	/* Now skip the whitespace and anything else that doesn't look like a */
	/*   number, a comment, or the end of a line.                         */
	while ((*result != '\0') && (*result != '#')
		&& (*result != '.') && (*result != '+') && (*result != '-')
		&& ((*result < '0') || (*result > '9')))
	{
		result++;
	}
	/* Check for a comment (prefixed with `#'). */
	if (*result == '#')
	{
		*result = '\0';
	}

	return result;
}

int validate_input(void)
{
	int *bitmap;

	printf("Validating input... ");
	fflush(stdout);

#if 0
	// each point should belong to at least two edges
	bitmap = (int *)calloc(point_count, sizeof(int));
	FOR_EACH_E {
		bitmap[edge_arr[i].pp.points[0]]++;
		bitmap[edge_arr[i].pp.points[1]]++;
	}
	FOR_EACH_P {
		if (bitmap[i] < 2) {
			printf("failed for point[%d]\n", i);
			return -1;
		}
	}
	free(bitmap);
#endif
	// each edge should belong to at least one (positive) and at most two triangles
	bitmap = (int *)calloc(edge_count, sizeof(int));
	FOR_EACH_T {
		bitmap[abs(T_E0(i))] += (T_E0(i) >= 0 ? 1 : -1);
		bitmap[abs(T_E1(i))] += (T_E1(i) >= 0 ? 1 : -1);
		bitmap[abs(T_E2(i))] += (T_E2(i) >= 0 ? 1 : -1);

		if (T_LE(i) == 1) {
			refine_count++;
		}
	}

	FOR_EACH_E {
		if ((bitmap[i] < 0) || (bitmap[i] > 1)) {
			printf("failed for edge[%d]\n", i);
			return -1;
		}
	}
	free(bitmap);

	// check for zero or micro length edges
	FOR_EACH_E {
		if ((!COMPARE_FLOAT2(E_P0(i).x, E_P1(i).x)) && (!COMPARE_FLOAT2(E_P0(i).y, E_P1(i).y))) {
			printf("zero length edge[%d] detected!!!  [%.17g = %.17g] [%.17g = %.17g]\n", i, E_P0(i).x, E_P1(i).x, E_P0(i).y, E_P1(i).y);
			return -1;
		}
	}

	if (refine_count == 0) {
		printf(RED"WARNING! None of the triangles are choosed to refine? "NORM);
	} else {
		printf(BLUE"%d triangles to refine "NORM, refine_count);
	}

#if 0
	if (refine_count > 65000) {
		printf(RED"TOO MUCH TRIANGLES TO REFINE!!\n"NORM);
		exit(1);
	}

	if (refine_count > 60000) {
		printf(RED"WARNING: THIS MAY FAIL! "NORM);
	}
#endif
	printf("DONE!\n");
	return 0;
}

void print_input(void)
{
	printf("Points:\n");
	FOR_EACH_P {
		printf("point[%d]= %f %f\n", i, P(i).x, P(i).y);
	}

	printf("Edges:\n");
	FOR_EACH_E {
		printf("edge[%d]=[%f,%f]\t[%f,%f]\tmid=[%f,%f]\tlen=%f\tmark=%d\tnext=%d\tnew_edges={%d, %d, orth=%d}\n", i, E_P0(i).x, E_P0(i).y, E_P1(i).x, E_P1(i).y, E_MIDP(i).x, E_MIDP(i).y,  E_LEN(i), GET_E_MARK(i), (GET_E_NEXT(i) != NO_LINK) ? (int)GET_E_NEXT(i) : -1, E_NE0(i), E_NE1(i), E_OE(i));
	}

	printf("Triangles:\n");
	FOR_EACH_T {
		printf("triangle[%d]=%d %d %d longest=%d\tcounter=%d rev_counter=%d\tcounter_scan=%d counter_scan_rev=%d\n", i, T_E0(i), T_E1(i), T_E2(i), T_LE(i), GET_T_CNT(i), GET_T_RCNT(i), GET_T_CNT_SCAN(i), GET_T_RCNT_SCAN(i));
	}

	return;
}

int host_alloc_tris(void)
{
	tris.tri_edge0 = (int *)calloc(tri_count, sizeof(int));
	if (tris.tri_edge0 == NULL) {
		printf("cannot alloc tris.tri_edge0!\n");
		return -1;
	}

	tris.tri_edge1 = (int *)calloc(tri_count, sizeof(int));
	if (tris.tri_edge1 == NULL) {
		printf("cannot alloc tris.tri_edge1!\n");
		return -1;
	}

	tris.tri_edge2 = (int *)calloc(tri_count, sizeof(int));
	if (tris.tri_edge2 == NULL) {
		printf("cannot alloc tris.tri_edge2!\n");
		return -1;
	}

	tris.tri_longest_edge = (int *)calloc(tri_count, sizeof(int));
	if (tris.tri_longest_edge == NULL) {
		printf("cannot alloc tris.tri_longest_edge!\n");
		return -1;
	}

	tris.tri_counter = (unsigned int *)calloc(tri_count, sizeof(int));
	if (tris.tri_counter == NULL) {
		printf("cannot alloc tris.tri_counter!\n");
		return -1;
	}

	tris.tri_counter_scan = (unsigned int *)calloc(tri_count, sizeof(int));
	if (tris.tri_counter_scan == NULL) {
		printf("cannot alloc tris.tri_counter_scan!\n");
		return -1;
	}

	tris.tri_rev_counter = (unsigned int *)calloc(tri_count, sizeof(int));
	if (tris.tri_rev_counter == NULL) {
		printf("cannot alloc tris.tri_rev_counter!\n");
		return -1;
	}

	tris.tri_rev_counter_scan = (unsigned int *)calloc(tri_count, sizeof(int));
	if (tris.tri_rev_counter_scan == NULL) {
		printf("cannot alloc tris.tri_rev_counter_scan!\n");
		return -1;
	}

	return 0;
}

int read_triangles(FILE *infile)
{
	int count;
	char *lineptr;
	char line[MAX_LINE_SIZE];

	if ((lineptr = readline(line, infile)) == NULL) {
		printf("error on reading line!\n");
		return -1;
	}

	// get the triangle count
	sscanf(lineptr, "%d", &count);
	printf("%d triangles, ", count);
	fflush(stdout);

	if (count <= 0) {
		printf("invalid # of triangle\n");
		return -1;
	}

	tri_count = count;

	if (host_alloc_tris() < 0) {
		printf("host alloc error\n");
		return -1;
	}

	for (int i = 0; i < count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		sscanf(lineptr, "%d %d %d %d", &T_E0(i), &T_E1(i), &T_E2(i), &T_LE(i));
	}

	return 0;
}

int host_alloc_edges(void)
{
	edges.edge_point0 = (point_t *)calloc(edge_count, sizeof(point_t));
	if (edges.edge_point0 == NULL) {
		printf("cannot alloc edge_point0 arr!\n");
		return -1;
	}

	edges.edge_point1 = (point_t *)calloc(edge_count, sizeof(point_t));
	if (edges.edge_point1 == NULL) {
		printf("cannot alloc edge_point1 arr!\n");
		return -1;
	}

	edges.edge_mid_p = (point_t *)calloc(edge_count, sizeof(point_t));
	if (edges.edge_mid_p == NULL) {
		printf("cannot alloc edge_mid_p arr!\n");
		return -1;
	}

	edges.edge_len = (float *)calloc(edge_count, sizeof(float));
	if (edges.edge_len == NULL) {
		printf("cannot alloc edge_len arr!\n");
		return -1;
	}

	edges.edge_mark_tree_next = (unsigned int *)calloc(edge_count, sizeof(int));
	if (edges.edge_mark_tree_next == NULL) {
		printf("cannot alloc edge_mark_tree_next arr!\n");
		return -1;
	}

	edges.new_edge0 = (int *)calloc(edge_count, sizeof(int));
	if (edges.new_edge0 == NULL) {
		printf("cannot alloc new_edge0 arr!\n");
		return -1;
	}

	edges.new_edge1 = (int *)calloc(edge_count, sizeof(int));
	if (edges.new_edge1 == NULL) {
		printf("cannot alloc new_edge1 arr!\n");
		return -1;
	}

	edges.orth_edge = (int *)calloc(edge_count, sizeof(int));
	if (edges.orth_edge == NULL) {
		printf("cannot alloc orth_edge arr!\n");
		return -1;
	}

	return 0;
}

int read_edges(FILE *infile)
{
	int count;
	char *lineptr;
	char line[MAX_LINE_SIZE];
	int p[2];

	if ((lineptr = readline(line, infile)) == NULL) {
		printf("error on reading line!\n");
		return -1;
	}

	// get the edge count
	sscanf(lineptr, "%d", &count);
	printf("%d edges, ", count);
	fflush(stdout);

	if (count <= 0) {
		printf("invalid # of edges\n");
		return -1;
	}

	edge_count = count + 1;	// 0th edge is invalid

	if (host_alloc_edges() < 0) {
		printf("host alloc error\n");
		return -1;
	}

	for (int i = 0; i < count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		sscanf(lineptr, "%d %d", &p[0], &p[1]);
		E_P0(i+1) = P(p[0]);
		E_P1(i+1) = P(p[1]);
	}

	return 0;
}

int read_points(FILE *infile)
{
	int count;
	point_t point = {0};
	char *lineptr;
	char line[MAX_LINE_SIZE];

	if ((lineptr = readline(line, infile)) == NULL) {
		printf("error on reading line!\n");
		return -1;
	}

	// get the point count
	sscanf(lineptr, "%d", &count);
	printf("%d points, ", count);
	fflush(stdout);

	if (count <= 0) {
		printf("invalid # of points\n");
		return -1;
	}

	point_arr = (point_t *)calloc(count, sizeof(point_t));
	if (point_arr == NULL) {
		printf("cannot alloc point_arr!\n");
		return -1;
	}

	for (int i = 0; i < count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		sscanf(lineptr, "%f %f", &point.x, &point.y);
		P(i) = point;
	}

	point_count = count;

	return 0;
}

int read_input_file(FILE *infile)
{
	printf("Reading input file... ");
	fflush(stdout);

	if (read_points(infile) < 0) {
		printf("error on reading points!\n");
		return -1;
	}

	if (read_edges(infile) < 0) {
		printf("error on reading edges!\n");
		return -1;
	}

	if (read_triangles(infile) < 0) {
		printf("error on reading triangles!\n");
		return -1;
	}

	printf("DONE!\n");
	return 0;
}

int write_edges(FILE *outfile)
{
	printf("Writing %d edges... ", edge_count - 1);
	fflush(stdout);

	fprintf(outfile, "#edges\n");
	fprintf(outfile, "%d\n", edge_count - 1);

	FOR_EACH_E {
		fprintf(outfile, "[%.17g %.17g] \t[%.17g %.17g]\n", E_P0(i).x, E_P0(i).y, E_P1(i).x, E_P1(i).y);
	}

	fprintf(outfile, "\n");

	printf("OK, ");
	return 0;
}

int write_triangles(FILE *outfile)
{
	printf("Writing %d triangles... ", tri_count);
	fflush(stdout);

	fprintf(outfile, "#triangles\n");
	fprintf(outfile, "%d\n", tri_count);

	FOR_EACH_T {
		// TODO: refine edilenleri bul
		fprintf(outfile, "%d \t%d \t%d \t%d\n", T_E0(i), T_E1(i), T_E2(i), 0);
	}

	fprintf(outfile, "\n");

	printf("OK, ");
	return 0;
}

int write_output(FILE *outfile)
{
	printf("Generating output file... ");
	fflush(stdout);

#if 0
	if (write_points(outfile) < 0) {
		printf("error on writing points!\n");
		return -1;
	}
#endif
	if (write_edges(outfile) < 0) {
		printf("error on writing edges!\n");
		return -1;
	}

	if (write_triangles(outfile) < 0) {
		printf("error on writing triangles!\n");
		return -1;
	}

	printf("DONE!\n");
	return 0;
}

int read_node_points(FILE *infile)
{
	int count;
	point_t point = {0};
	char *lineptr;
	char line[MAX_LINE_SIZE];

	if ((lineptr = readline(line, infile)) == NULL) {
		printf("error on reading line!\n");
		return -1;
	}

	// get the point count
	sscanf(lineptr, "%d", &count);
	printf("%d points, ", count);
	fflush(stdout);

	if (count <= 0) {
		printf("invalid # of points\n");
		return -1;
	}

	point_arr = (point_t *)calloc(count, sizeof(point_t));
	if (point_arr == NULL) {
		printf("cannot alloc point_arr!\n");
		return -1;
	}

	for (int i = 0; i < count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		strtol(lineptr, &lineptr, 0);
		lineptr = findfield(lineptr);
		point.x = strtof(lineptr, &lineptr);
		lineptr = findfield(lineptr);
		point.y = strtof(lineptr, &lineptr);

		P(i) = point;
	}

	point_count = count;

	return 0;
}

int read_node_file(FILE *infile)
{
	printf("Reading node file... ");
	fflush(stdout);

	if (read_node_points(infile) < 0) {
		printf("error on reading points!\n");
		return -1;
	}

	printf("DONE!\n");
	return 0;
}

#define HASH_TABLE_SIZE		(point_count+1)

int *hash_table;

int hash(int i)
{
	return i % HASH_TABLE_SIZE;
}

// check if two edges are equal and return 1 if they are equal. else, return 0.
int edge_equals(in_edge_t *e1, in_edge_t *e2)
{
	if ((e1->point_ix[0] == e2->point_ix[0]) && (e1->point_ix[1] == e2->point_ix[1])) {
		return 1;
	}

	return 0;
}

// return index if edge is found
// return 0 if edge is not found
int find_edge(int p1, int p2)
{
	in_edge_t e;
	int h = hash(p1);
	int index = hash_table[h];

	e.point_ix[0] = p1;
	e.point_ix[1] = p2;

	while (index != 0) {
		if (edge_equals(&e, &in_edge_arr[index])) {
			//printf("found edge [%d %d] in %d\n", p1, p2, index);
			break;
		}
		index = in_edge_arr[index].next;
	}

	return index;
}

int create_edge(int p1, int p2)
{
	in_edge_t e;
	int h;

	e.point_ix[0] = p1;
	e.point_ix[1] = p2;

	in_edge_count++;

	// add to hash table
	h = hash(p1);
	//printf("%d: creating [%d %d] hash=%d\n", in_edge_count, p1, p2, h);
	e.next = hash_table[h];
	hash_table[h] = in_edge_count;

	in_edge_arr[in_edge_count] = e;

	return in_edge_count;
}

int create_edges_and_triangles(void)
{
	//int r;

	printf("Creating edges... ");
	fflush(stdout);

	// alloc tri arr
	if (host_alloc_tris() < 0) {
		printf("host alloc error\n");
		return -1;
	}

	// alloc max # of possible edges, i.e. 3xtri_count
	in_edge_count = tri_count * 3;
	in_edge_arr = (in_edge_t *)calloc(in_edge_count, sizeof(in_edge_t));
	if (in_edge_arr == NULL) {
		printf("cannot alloc in_edge_arr!\n");
		return -1;
	}

	// alloc hash table
	hash_table = (int *)calloc(HASH_TABLE_SIZE, sizeof(int));
	if (hash_table == NULL) {
		printf("cannot alloc hash_table!\n");
		return -1;
	}

	in_edge_count = 0;

	//r = get_rand_int(0, tri_count);

	for (int i = 0; i < tri_count; i++) {
		for (int j = 0; j < 3; j++) {
			int p1 = tri_point_arr[i].point[j];
			int p2 = tri_point_arr[i].point[(j + 1) % 3];
			int index = -find_edge(p2, p1);	// search the reverse of the edge

			if (!index)
				index = create_edge(p1, p2);

			if (j == 0)
				T_E0(i) = index;
			else if (j == 1)
				T_E1(i) = index;
			else
				T_E2(i) = index;
		}

		//if (get_rand_int(0, tri_count) < (r/100 + 1))
		if (get_rand_int(0, 1000) < 1)
			T_LE(i) = 1;
	}

	printf("%d edges, ", in_edge_count);

	edge_count = in_edge_count + 1;

	if (host_alloc_edges() < 0) {
		printf("host alloc error\n");
		return -1;
	}

	for (int i = 1; i <= in_edge_count; i++) {
		int p[2];

		p[0] = in_edge_arr[i].point_ix[0];
		p[1] = in_edge_arr[i].point_ix[1];

		E_P0(i) = P(p[0]-1);
		E_P1(i) = P(p[1]-1);
	}

	return 0;
}

int read_tri_points(FILE *infile)
{
	int count;
	tri_point_t tp;
	char *lineptr;
	char line[MAX_LINE_SIZE];

	if ((lineptr = readline(line, infile)) == NULL) {
		printf("error on reading line!\n");
		return -1;
	}

	// get the tri count
	sscanf(lineptr, "%d", &count);
	printf("%d triangles, ", count);
	fflush(stdout);

	if (count <= 0) {
		printf("invalid # of triangles\n");
		return -1;
	}

	tri_point_arr = (tri_point_t *)calloc(count, sizeof(tri_point_t));
	if (tri_point_arr == NULL) {
		printf("cannot alloc tri_point_arr!\n");
		return -1;
	}

	for (int i = 0; i < count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		strtol(lineptr, &lineptr, 0);

		for (int j = 0; j < 3; j++) {
			lineptr = findfield(lineptr);
			tp.point[j] = (int)strtod(lineptr, &lineptr);
		}

		tri_point_arr[i] = tp;
	}

	tri_count = count;

	return 0;
}

int read_ele_file(FILE *infile)
{
	printf("Reading ele file... ");
	fflush(stdout);

	srand(time(NULL));

	if (read_tri_points(infile) < 0) {
		printf("error on reading tri_points!\n");
		return -1;
	}

	if (create_edges_and_triangles() < 0) {
		printf("error on create_edges_and_triangles!\n");
		return -1;
	}

	free(tri_point_arr);
	tri_point_arr = NULL;

	free(in_edge_arr);
	in_edge_arr = NULL;

	free(hash_table);
	hash_table = NULL;

	printf("DONE!\n");
	return 0;
}
