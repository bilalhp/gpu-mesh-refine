
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#define MAX_LINE_SIZE		1024
#define P(_i)		point_arr[_i]
#define TP(_i)		tri_point_arr[_i]
#define E(_i)		edge_arr[_i]
#define T(_i)		tri_arr[_i]
#define FOR_EACH_P	for (int i = 0; i < point_count; i++)
#define FOR_EACH_E	for (int i = 1; i < edge_count; i++)
#define FOR_EACH_T	for (int i = 0; i < tri_count; i++)

#ifndef __align__
#define __align__(x)
#endif

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
	point_t p[2];
	int point_ix[2];
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
void usage()
{
	fprintf(stderr, "Usage: convert output <input_file> <output_file>\n");
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

	tri_arr = (triangle_t *)calloc(count, sizeof(triangle_t));
	if (tri_arr == NULL) {
		printf("cannot alloc tri_arr!\n");
		return -1;
	}

	for (int i = 0; i < count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		sscanf(lineptr, "%d %d %d", &tri_arr[i].edge_ix[0], &tri_arr[i].edge_ix[1], &tri_arr[i].edge_ix[2]);
		//printf("READ %d %d %d\n", tri_arr[i].edge_ix[0], tri_arr[i].edge_ix[1], tri_arr[i].edge_ix[2]);
	}

	tri_count = count;

	return 0;
}

int read_edges(FILE *infile)
{
	int count;
	char *lineptr;
	char line[MAX_LINE_SIZE];

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

	edge_arr = (edge_t *)calloc(count+1, sizeof(edge_t));
	if (edge_arr == NULL) {
		printf("cannot alloc edge_arr!\n");
		return -1;
	}

	for (int i = 1; i <= count; i++) {
		if ((lineptr = readline(line, infile)) == NULL) {
			printf("error on reading line!\n");
			return -1;
		}
		//lineptr = findfield(lineptr);
		edge_arr[i].p[0].x = strtof(lineptr, &lineptr);
		lineptr = findfield(lineptr);
		edge_arr[i].p[0].y = strtof(lineptr, &lineptr);
		lineptr = findfield(lineptr);
		edge_arr[i].p[1].x = strtof(lineptr, &lineptr);
		lineptr = findfield(lineptr);
		edge_arr[i].p[1].y = strtof(lineptr, &lineptr);

		//printf("READ %f %f    %f %f \n", edge_arr[i].p[0].x, edge_arr[i].p[0].y, edge_arr[i].p[1].x, edge_arr[i].p[1].y);
	}

	edge_count = count + 1;

	return 0;
}

int read_input_file(FILE *infile)
{
	printf("Reading input file... ");
	fflush(stdout);

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

int find_point(point_t p)
{
	int ix = -1;

	FOR_EACH_P {
		if ((P(i).x == p.x) && (P(i).y == p.y)) {
			ix = i;
			break;
		}
	}

	return ix;
}

int create_point(point_t p)
{
	P(point_count).x = p.x;
	P(point_count).y = p.y;

	return point_count++;
}

int find_create_point(point_t p)
{
	int ix = find_point(p);

	if (ix < 0)
		ix = create_point(p);

	return ix;
}

int generate_point_arr(void)
{
	// cowardly allocate max # of possible points, i.e. 2*edge_count
	point_arr = (point_t *)calloc(edge_count*2, sizeof(point_t));
	if (edge_arr == NULL) {
		printf("cannot alloc point_arr!\n");
		return -1;
	}

	FOR_EACH_E {
		for (int j = 0; j < 2; j++) {
			E(i).point_ix[j] = find_create_point(E(i).p[j]);
		}
	}

	printf("Got %d points\n", point_count);

	return 0;
}

int generate_tri_point_arr(void)
{
	tri_point_arr = (tri_point_t *)calloc(tri_count, sizeof(tri_point_t));
	if (tri_point_arr == NULL) {
		printf("cannot alloc tri_point_arr!\n");
		return -1;
	}

	FOR_EACH_T {
		for (int j = 0; j < 3; j++) {
			if (T(i).edge_ix[j] > 0) {
				TP(i).point[j] = E(T(i).edge_ix[j]).point_ix[0];
			} else {
				TP(i).point[j] = E(abs(T(i).edge_ix[j])).point_ix[1];
			}
		}
	}

	return 0;
}

int write_nodefile(FILE *outfile)
{
	fprintf(outfile, "%d 2 0 0\n", point_count);

	FOR_EACH_P {
		fprintf(outfile, "%d %.17g %.17g\n", i + 1, P(i).x, P(i).y);
	}

	return 0;
}

int write_elefile(FILE *outfile)
{
	fprintf(outfile, "%d 3 0\n", tri_count);

	FOR_EACH_T {
		fprintf(outfile, "%d %d %d %d\n", i + 1, TP(i).point[0] + 1, TP(i).point[1] + 1, TP(i).point[2] + 1);
	}

	return 0;
}

int main(int argc, char *argv[])
{
	FILE *infile = NULL, *nodefile = NULL, *elefile = NULL;
	char *outfileprefix, *infilename, nodefilename[128], elefilename[128];

	if (argc < 3)
	{
		printf("invalid arguments\n");
		usage();
		return -1;
	}

	infilename = argv[1];

	if (!infilename || (strlen(infilename) <= 0))
	{
		printf("bad argument! infilename is NULL\n");
		usage();
		return -1;
	}

	outfileprefix = argv[2];

	if (!outfileprefix || (strlen(outfileprefix) <= 0))
	{
		printf("bad argument! outfileprefix is NULL\n");
		usage();
		return -1;
	}

	printf("Starting process: infilename=%s outfileprefix=%s\n", infilename, outfileprefix);

	// arguments verified, continue

	if (!(infile = fopen(infilename, "r")))
	{
		printf("cannot open infile=%s\n", infilename);
		return -1;
	}

	sprintf(nodefilename, "%s.node", outfileprefix);
	sprintf(elefilename, "%s.ele", outfileprefix);

	if (!(nodefile = fopen(nodefilename, "w")))
	{
		printf("cannot open nodefilename=%s\n", nodefilename);
		return -1;
	}

	if (!(elefile = fopen(elefilename, "w")))
	{
		printf("cannot open elefilename=%s\n", elefilename);
		return -1;
	}

	if (read_input_file(infile) < 0) {
		printf("error on parsing input file!\n");
		return -1;
	}
	fclose(infile);

	generate_point_arr();
	generate_tri_point_arr();

	write_nodefile(nodefile);
	write_elefile(elefile);

	if (nodefile)
		fclose(nodefile);

	if (elefile)
		fclose(elefile);

	return 0;
}
