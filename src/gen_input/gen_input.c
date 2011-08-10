
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <limits.h>
#include <math.h>

struct point
{
	float x;
	float y;
};

int elems;	// element count
int max_coord;

void get_random_point(struct point *point);
float get_rand_float(float min, float max);
int get_rand(int max);

void usage()
{
	fprintf(stderr, "Usage: gen_input <# of elements> <max coord> <output_file>\n");
}

int main(int argc, char *argv[])
{
	FILE *outfile;
	char *filename;
	int i;
	struct point mypoint;

	if (argc < 4)
	{
		printf("invalid arguments\n");
		usage();
		return -1;
	}

	elems = atoi(argv[1]);

	if (elems <= 0)
	{
		printf("bad argument! elems=%d\n", elems);
		usage();
		return -1;
	}

	max_coord = atoi(argv[2]);

	if (max_coord == 0) {
		printf("bad argument! max_coord=%d\n", max_coord);
		usage();
		return -1;
	}

	if (max_coord < 0) {
		max_coord = INT_MAX;
	}

	filename = argv[3];

	if (!filename || (strlen(filename) <= 0))
	{
		printf("bad argument! filename is NULL\n");
		usage();
		return -1;
	}

	// arguments verified, continue

	if (!(outfile = fopen(filename, "w")))
	{
		printf("cannot open outfile=%s\n", filename);
		return -1;
	}

	// start generating output
	fprintf(outfile, "%d 2 0\n", elems);

	srand(time(NULL));
	
	for (i = 1; i <= elems; i++)
	{
		get_random_point(&mypoint);
		fprintf(outfile, "%d %.17g %.17g\n", i, mypoint.x, mypoint.y);
	}

	fclose(outfile);

	return 0;
}

void get_random_point(struct point *mypoint)
{
	float frac;

	frac = 1 / get_rand_float(1, 50);
	mypoint->x = get_rand(max_coord) + frac;

	frac = 1 / get_rand_float(1, 40);
	mypoint->y = get_rand(max_coord) + frac;
}

int get_rand(int max)
{
	return random() % max;
}

float get_rand_float(float min, float max)
{
     return min + (max - min)*(rand() / (float)RAND_MAX);
}
