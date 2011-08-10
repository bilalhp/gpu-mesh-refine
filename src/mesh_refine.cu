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
#include  <signal.h>


// Variables
int debug = 0;

int threadsPerBlock = 128;
point_t *point_arr;
edge_t edges;
__device__ edge_t d_edges_s;
edge_t *d_edges = &d_edges_s;
triangle_t tris;
__device__ triangle_t d_tris_s;
triangle_t *d_tris = &d_tris_s;

unsigned int point_count, edge_count, tri_count;
unsigned int newelemcount, newelemcount_rev, new_edge_count, new_tri_count;
int refine_count;

// Host code
void usage(void)
{
	fprintf(stdout, "Usage: mesh_refine [-d] [-h] [-t <#>] [-f/i <input_file>] [-o <output_file>] [-p]\n");
	fprintf(stdout, "\t -h: print help (this output)\n");
	fprintf(stdout, "\t -d: enable debug output\n");
	fprintf(stdout, "\t -t: # of threads per block (default=256)\n");
	fprintf(stdout, "\t -f: input file\n");
	fprintf(stdout, "\t -i: input file prefix from triangle application output (input.1 for input.1.node and input.1.ele)\n");
	fprintf(stdout, "\t -p: process only on pc\n");

	exit(1);
}

unsigned long get_time_diff_us(struct timeval *start, struct timeval *end)
{
	return (end->tv_sec - start->tv_sec) * 1000000 + (end->tv_usec - start->tv_usec);
}

void sigterm(int sig)
{
	printf("Cleaning up...\n");

	device_cleanup();

	exit(0);
}

int main(int argc, char** argv)
{
	char c;
	char *input_filename = NULL;
	char *infileprefix = NULL;
	char nodefilename[128], elefilename[128];
	FILE *infile;
	char *output_filename = NULL;
	FILE *outfile;
	char output_filename_pc[1024] = {0};
	FILE *outfile_pc;
	int only_pc = 0;

	// parse arguments
	while ((c = getopt(argc, argv, "f:hdt:o:pi:")) != -1) {
		switch (c) {
		case 'h':
			usage();
		case 'd':
			debug = 1;
			break;
		case 'p':
			only_pc = 1;
			break;
		case 't':
			threadsPerBlock = atoi(optarg);
			break;
		case 'f':
			input_filename = optarg;
			break;
		case 'i':
			infileprefix = optarg;
			break;
		case 'o':
			output_filename = optarg;
			break;
		default:
			usage();
		}
	}

	dprintf("# of threads=%d infile=%s outfile=%s\n", threadsPerBlock, input_filename, output_filename);

	// input check
	if (threadsPerBlock <= 0 || (!input_filename && !infileprefix)) {
		printf("invalid arguments!\n");
		usage();
		return -1;
	}

	if (input_filename) {
		if ((infile = fopen(input_filename, "r")) == NULL)
		{
			printf("cannot open input file=%s\n", input_filename);
			return -1;
		}
	
		if (read_input_file(infile) < 0) {
			printf("error on parsing input file!\n");
			return -1;
		}
		fclose(infile);
	} else if (infileprefix) {
		sprintf(nodefilename, "%s.node", infileprefix);
		sprintf(elefilename, "%s.ele", infileprefix);

		if ((infile = fopen(nodefilename, "r")) == NULL)
		{
			printf("cannot open input file=%s\n", nodefilename);
			return -1;
		}
	
		if (read_node_file(infile) < 0) {
			printf("error on parsing node file!\n");
			return -1;
		}
		fclose(infile);

		if ((infile = fopen(elefilename, "r")) == NULL)
		{
			printf("cannot open input file=%s\n", elefilename);
			return -1;
		}
	
		if (read_ele_file(infile) < 0) {
			printf("error on parsing ele file!\n");
			return -1;
		}
		fclose(infile);
	} else {
		printf("invalid arguments ???\n");
		usage();
		return -1;
	}

	signal(SIGINT, sigterm);

	if (validate_input() < 0) {
		printf("input validation error!\n");
		return -1;
	}

#if 0
	if (debug)
		print_input();
#endif

	if (pc_alloc_copy_input()) {
		printf("cannot alloc pc input!\n");
		return -1;
	}

	if (only_pc) {
		goto process_pc;
	}

	printf("Starting process...\n");

	malloc_copy_input_to_device();

	// step 1: calculate edge lengths and mid points
	calc_edge_lengths_mid_p();

#if 1
	// bilal: workaround for floating point problem!
	cudaSafeCall(cudaMemcpy(edges.edge_mid_p, d_edges->edge_mid_p, sizeof(point_t)*edge_count, cudaMemcpyDeviceToHost));
	cudaSafeCall(cudaMemcpy(edges.edge_len, d_edges->edge_len, sizeof(float)*edge_count, cudaMemcpyDeviceToHost));
	pc_copy_edges();
#endif

	// step 2: mark longest edge of each triangle
	mark_longest_edges();

	// step 3: establish links
	establish_links();

	// step 4: follow links
	follow_links();

	// step 5: get the initial value of counters
	get_counters();

	// step 6: prefix the counters
	prefix_counters();

	create_new_elem_arrs();

	// step 7: refine the mesh: create new edges
	refine();

	// OKI DOKI! copy back the data to host
	copy_back();

#if 1
	if (debug) {
		copy_back();
		print_input();
	}
#endif

	// free the device stuff
	device_cleanup();

process_pc:

	if (mesh_refine_pc(only_pc)) {
		printf("MESH_REFINE_PC FAILED!\n");
	}

	if (!only_pc) {
		if (compare_results()) {
			printf(RED"VERIFICATION FAILED!\n"NORM);
		} else {
			printf("VERIFICATION COMPLETED SUCCESSFULLY!\n");
		}
	}

	if (output_filename) {
		if (!only_pc) {
			if ((outfile = fopen(output_filename, "w")) == NULL)
			{
				printf("cannot create output file=%s\n", output_filename);
				return -1;
			}
			write_output(outfile);

			fclose(outfile);
		}

		sprintf(output_filename_pc, "%s.pc", output_filename);
		if ((outfile_pc = fopen(output_filename_pc, "w")) == NULL)
		{
			printf("cannot create output file=%s\n", output_filename_pc);
			return -1;
		}

		pc_write_output(outfile_pc);

		fclose(outfile_pc);
	}

	return 0;
}
