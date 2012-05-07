#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <limits.h>
#include <pthread.h>
#include <zlib.h>

#include "BError.h"
#include "bam.h"
#include "sam.h"
#include "dbampairedenddist.h"

#define Name "dbampairedenddist"
#define ROTATE_NUM 100000

/* Prints the distribution of the distance between paired-end reads
 * using reads that have both ends matching only one location on
 * the same strand.
 * */

int main(int argc, char *argv[])
{
	samfile_t *fp_in = NULL;
	int32_t i;
	Bins bins;
	bam1_t *b=NULL;
	int64_t numFound = 0;

	if(5 <= argc) {
		bins.minDistance = atoi(argv[1]);
		bins.maxDistance = atoi(argv[2]);
		bins.binSize = atoi(argv[3]);

		assert(bins.minDistance <= bins.maxDistance);

		/* Allocate memory */
		bins.numCounts = (bins.maxDistance - bins.minDistance + 1) % bins.binSize;
		bins.numCounts += (int32_t)(bins.maxDistance - bins.minDistance + 1)/bins.binSize;
		bins.counts = calloc(bins.numCounts, sizeof(int32_t));
		if(NULL == bins.counts) {
			PrintError(Name,
					"bins.counts",
					"Could not allocate memory",
					Exit,
					MallocMemory);
		}

		for(i=4;i<argc;i++) {

			fprintf(stderr, "%s", BREAK_LINE);
			fprintf(stderr, "Reading in from %s.\n",
					argv[i]);
			fp_in = samopen(argv[i], "rb", 0);
			if(NULL == fp_in) {
				PrintError(Name,
						argv[i],
						"Could not open file for reading",
						Exit,
						OpenFileError);
			}

			b = bam_init1();
			int64_t b_ctr = 0;
			while(0 < samread(fp_in, b)) {
				b_ctr++;
				if(0 == (b_ctr % 100000)) {
					fprintf(stderr, "\r%lld",
							(long long int)b_ctr);
				}

				if(!(b->core.flag & BAM_FUNMAP) && // mapped
						(b->core.flag & BAM_FPAIRED) && // paired end
						!(b->core.flag & BAM_FMUNMAP) && // mate mapped
						(b->core.flag & BAM_FREAD1) && // first read
						(b->core.tid == b->core.mtid) && // same chromosome
						((b->core.flag & BAM_FREVERSE) == (b->core.flag & BAM_FMREVERSE))) { //same strand
					int64_t posOne, posTwo, difference;
					/* Simple way to avoid overflow */
					posOne = b->core.pos;
					posTwo = b->core.mpos;
					difference = posTwo - posOne;
					if(1==BinsInsert(&bins, difference)) {
						numFound++;
					}
				}

				// Destroy bam
				bam_destroy1(b);
				// Reinitialize
				b = bam_init1();
			}
			fprintf(stderr, "\r%lld\n",
					(long long int)b_ctr);
			// Free
			bam_destroy1(b);

			fprintf(stderr, "%s", BREAK_LINE);
			fprintf(stderr, "Found %lld.\n",
					(long long int)numFound);
			fprintf(stderr, "%s", BREAK_LINE);

			/* Close the file */
			samclose(fp_in);
		}

		/* Output */
		BinsPrint(&bins, stdout);

		/* Free memory */
		free(bins.counts);

		fprintf(stderr, "%s", BREAK_LINE);
		fprintf(stderr, "Terminating successfully!\n");
		fprintf(stderr, "%s", BREAK_LINE);
	}
	else {
		fprintf(stderr, "Usage: %s [OPTIONS]\n", Name);
		fprintf(stderr, "\t<minimum distance>\n");
		fprintf(stderr, "\t<maximum distance>\n");
		fprintf(stderr, "\t<bin size>\n");
		fprintf(stderr, "\t<bam file(s)>\n");
	}

	return 0;
}

int BinsInsert(Bins *b,
		int32_t difference)
{
	int32_t index;

	if(b->minDistance <= difference &&
			difference <= b->maxDistance) {
		index = (difference - b->minDistance);
		index -= (difference % b->binSize);
		index /= b->binSize;
		assert(0 <= index &&
				index < b->numCounts);
		b->counts[index]++;
		return 1;
	}
	return 0;
}

void BinsPrint(Bins *b,
		FILE *fpOut)
{
	int32_t i;

	for(i=0;i<b->numCounts;i++) {
		fprintf(fpOut, "%10d\t%10d\t%10d\n",
				b->minDistance + i*b->binSize,
				GETMIN(b->minDistance + (i+1)*b->binSize-1, b->maxDistance),
				b->counts[i]);
	}
}
