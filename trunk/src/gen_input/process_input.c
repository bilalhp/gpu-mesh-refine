
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <math.h>

#define MAX_LINE_SIZE		1024
#define P(_i)		point_arr[_i]
#define TP(_i)		tri_point_arr[_i]
#define E(_i)		edge_arr[_i]
#define T(_i)		tri_arr[_i]

#ifndef __align__
#define __align__(x)
#endif

#define HASH_TABLE_SIZE		50000000

int hash_table[HASH_TABLE_SIZE];

// typedefs
typedef struct point		point_t;
typedef struct edge		edge_t;
typedef struct tri_point	tri_point_t;
typedef struct triangle		triangle_t;

//structures
struct __align__(8) point {
	float x;
	float y;
};

struct __align__(8) tri_point {
	int point[3];
};

struct __align__(8) edge {
	int point_ix[2];
	int next;
};

struct __align__(8) triangle {
	int edge_ix[3];
};

// global variables
point_t *point_arr = NULL;
tri_point_t *tri_point_arr = NULL;
edge_t *edge_arr = NULL;
triangle_t *tri_arr = NULL;

int point_count;
int edge_count;
int tri_count;


// START OF CODE

int hash(int i)
{
	return i % HASH_TABLE_SIZE;
}

void usage()
{
	fprintf(stderr, "Usage: process_input <input_file_prefix> <output_file>\n");
}

int get_rand_int(int min, int max)
{
	return min+(rand()%(max - min));
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

int tri_read_points(FILE *infile)
{
	int count;
	point_t point = {0};
	char *lineptr;
	char line[MAX_LINE_SIZE];
	int index;

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

	point_arr = (point_t *)calloc(count + 1, sizeof(point_t));
	if (point_arr == NULL) {
		printf("cannot alloc point_arr!\n");
		return -1;
	}

	for (int i = 1; i <= count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		index = (int)strtol(lineptr, &lineptr, 0);
		lineptr = findfield(lineptr);
		point.x = strtof(lineptr, &lineptr);
		lineptr = findfield(lineptr);
		point.y = strtof(lineptr, &lineptr);

		// round them
		//point.x = roundf(point.x*4) / 4;
		//point.y = roundf(point.y*4) / 4;

		P(i) = point;
	}

	point_count = count;

	return 0;
}

int tri_read_tri_points(FILE *infile)
{
	int count;
	tri_point_t tp;
	char *lineptr;
	char line[MAX_LINE_SIZE];
	int index;

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
		index = (int)strtol(lineptr, &lineptr, 0);

		for (int j = 0; j < 3; j++) {
			lineptr = findfield(lineptr);
			tp.point[j] = (int)strtod(lineptr, &lineptr);
		}

		TP(i) = tp;
	}

	tri_count = count;

	return 0;
}

int tri_read_ele(FILE *infile)
{
	printf("Reading ele file... ");
	fflush(stdout);

	if (tri_read_tri_points(infile) < 0) {
		printf("error on reading tri_points!\n");
		return -1;
	}

	printf("DONE!\n");
	return 0;
}

int tri_read_nodes(FILE *infile)
{
	printf("Reading node file... ");
	fflush(stdout);

	if (tri_read_points(infile) < 0) {
		printf("error on reading points!\n");
		return -1;
	}

	printf("DONE!\n");
	return 0;
}

int tri_write_points(FILE *outfile)
{
	printf("Writing points... ");
	fflush(stdout);

	fprintf(outfile, "#points\n");
	fprintf(outfile, "%d\n", point_count);

	for (int i = 1; i <= point_count; i++) {
		fprintf(outfile, "%.17g %.17g\n", P(i).x, P(i).y);
	}

	fprintf(outfile, "\n");

	printf("DONE!\n");
	return 0;
}

int tri_write_edges(FILE *outfile)
{
	printf("Writing edges... ");
	fflush(stdout);

	fprintf(outfile, "#edges\n");
	fprintf(outfile, "%d\n", edge_count);

	for (int i = 1; i <= edge_count; i++) {
		fprintf(outfile, "%d %d\n", E(i).point_ix[0] - 1, E(i).point_ix[1] - 1);
	}

	fprintf(outfile, "\n");

	printf("DONE!\n");
	return 0;
}

int tri_write_triangles(FILE *outfile)
{
	//int r;

	printf("Writing triangles... ");
	fflush(stdout);

	fprintf(outfile, "#triangles\n");
	fprintf(outfile, "%d\n", tri_count);

	//r = get_rand_int(0, tri_count);

	for (int i = 0; i < tri_count; i++) {
		fprintf(outfile, "%d %d %d %d\n", T(i).edge_ix[0], T(i).edge_ix[1], T(i).edge_ix[2], /*(get_rand_int(0, tri_count) < (r/100 + 1))*/get_rand_int(0, 1000)  < 1); //20 is fine
	}

	fprintf(outfile, "\n");

	printf("DONE!\n");
	return 0;
}

// check if two edges are equal and return 1 if they are equal. else, return 0.
int tri_edge_equals(edge_t *e1, edge_t *e2)
{
	if ((e1->point_ix[0] == e2->point_ix[0]) && (e1->point_ix[1] == e2->point_ix[1])) {
		return 1;
	}

	return 0;
}

// return index if edge is found
// return 0 if edge is not found
int tri_find_edge(int p1, int p2)
{
	edge_t e = {.point_ix[0] = p1, .point_ix[1] = p2};
	int h = hash(p1);
	int index = hash_table[h];

	while (index != 0) {
		if (tri_edge_equals(&e, &E(index))) {
			//printf("found edge [%d %d] in %d\n", p1, p2, index);
			break;
		}
		index = E(index).next;
	}

	return index;
}

int tri_create_edge(int p1, int p2)
{
	edge_t e;
	int h;

	e.point_ix[0] = p1;
	e.point_ix[1] = p2;

	edge_count++;

	// add to hash table
	h = hash(p1);
	//printf("%d: creating [%d %d] hash=%d\n", edge_count, p1, p2, h);
	e.next = hash_table[h];
	hash_table[h] = edge_count;

	E(edge_count) = e;

	return edge_count;
}

int tri_create_edges_and_triangles(void)
{
	printf("Creating edges and triangles... ");
	fflush(stdout);

	// alloc tri arr
	tri_arr = (triangle_t *)calloc(tri_count, sizeof(triangle_t));
	if (tri_arr == NULL) {
		printf("cannot alloc tri arr!\n");
		return -1;
	}

	// alloc max # of possible edges, i.e. 3xtri_count
	edge_arr = (edge_t *)calloc(tri_count*3 + 1, sizeof(edge_t));
	if (edge_arr == NULL) {
		printf("cannot alloc edge arr!\n");
		return -1;
	}

	edge_count = 0;

	for (int i = 0; i < tri_count; i++) {
		for (int j = 0; j < 3; j++) {
			int p1 = TP(i).point[j];
			int p2 = TP(i).point[(j + 1) % 3];
			int index = -tri_find_edge(p2, p1);	// search the reverse of the edge

			if (!index)
				index = tri_create_edge(p1, p2);

			T(i).edge_ix[j] = index;
		}
	}

	printf("%d edges, ", edge_count);

	printf("DONE!\n");
	return 0;
}

int main(int argc, char *argv[])
{
	FILE *outfile = NULL, *nodefile = NULL, *elefile = NULL;
	char *infileprefix, *outfilename, nodefilename[128], elefilename[128];

	srand(time(NULL));

	if (argc < 3)
	{
		printf("invalid arguments\n");
		usage();
		return -1;
	}

	infileprefix = argv[1];

	if (!infileprefix || (strlen(infileprefix) <= 0))
	{
		printf("bad argument! infileprefix is NULL\n");
		usage();
		return -1;
	}

	outfilename = argv[2];

	if (!outfilename || (strlen(outfilename) <= 0))
	{
		printf("bad argument! outfilename is NULL\n");
		usage();
		return -1;
	}

	printf("Starting process: infileprefix=%s outfilename=%s\n", infileprefix, outfilename);

	// arguments verified, continue

	if (!(outfile = fopen(outfilename, "w")))
	{
		printf("cannot open outfile=%s\n", outfilename);
		return -1;
	}

	sprintf(nodefilename, "%s.node", infileprefix);
	sprintf(elefilename, "%s.ele", infileprefix);

	if (!(nodefile = fopen(nodefilename, "r")))
	{
		printf("cannot open nodefilename=%s\n", nodefilename);
		return -1;
	}

	if (!(elefile = fopen(elefilename, "r")))
	{
		printf("cannot open elefilename=%s\n", elefilename);
		return -1;
	}

	tri_read_nodes(nodefile);
	tri_read_ele(elefile);
	tri_create_edges_and_triangles();
	tri_write_points(outfile);
	tri_write_edges(outfile);
	tri_write_triangles(outfile);

	fprintf(outfile, "#end\n");

	if (outfile)
		fclose(outfile);

	if (nodefile)
		fclose(nodefile);

	if (elefile)
		fclose(elefile);

	return 0;
}
