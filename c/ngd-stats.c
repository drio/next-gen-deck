#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <limits.h>
#include <pthread.h>
#include <zlib.h>

#include "BError.h"
#include "BLibDefinitions.h"
#include "bam.h"
#include "sam.h"
#include "ngd-stats.h"

#define Name "ngd-stats"
#define ROTATE_NUM 100000

int main(int argc, char *argv[])
{
  samfile_t *fp_in = NULL;
  int32_t i;
  bam1_t *b=NULL;
  bam_stats_t *stats=NULL;

  if(3 <= argc) {
    stats = bam_stats_t_init();

    for(i=2;i<argc;i++) {
      fprintf(stderr, "%s", BREAK_LINE);
      fprintf(stderr, "Reading in from %s.\n", argv[i]);
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
      while(0 < samread(fp_in, b)) { // Read one alignment
        b_ctr++;
        if(0 == (b_ctr % 100000)) fprintf(stderr, "\r%lld", (long long int)b_ctr);

        // Add
        bam_stats_t_add(stats, b);

        // Destroy bam
        bam_destroy1(b);
        // Reinitialize
        b = bam_init1();
      }

      fprintf(stderr, "\r%lld\n", (long long int)b_ctr);
      bam_destroy1(b);
      fprintf(stderr, "%s", BREAK_LINE);
      samclose(fp_in);
    }

    // Output
    char seed_name[100] = {0};
    strcpy(seed_name, argv[1]);
    for(i=1;i<argc;i++)
      fprintf(stdout, "%s.\n", argv[i]);
    bam_stats_t_print(stats, seed_name);

    bam_stats_t_destroy(stats);
    stats=NULL;

    fprintf(stderr, "%s", BREAK_LINE);
    fprintf(stderr, "Terminating successfully!\n");
    fprintf(stderr, "%s", BREAK_LINE);
  }
  else {
    fprintf(stderr, "Usage: %s [OPTIONS]\n", Name);
    fprintf(stderr, "\t<seed_output_name> <bam file(s)>\n");
  }

  return 0;
}

bam_stats_t *bam_stats_t_init()
{
  char *FnName="bam_stats_t_init";
  bam_stats_t *stats=NULL;
  int32_t i;

  stats=malloc(sizeof(bam_stats_t));
  if(NULL == stats)
    PrintError(FnName, "stats", "Could not allocate memory", Exit, MallocMemory);

  stats->num_raw_paired_reads = 0;
  stats->num_raw_single_end_reads = 0;
  stats->num_paired_reads = 0;
  stats->num_unpaired_reads = 0;
  stats->num_single_end_reads = 0;
  stats->num_paired_reads_pcr_dup = 0;
  stats->num_unpaired_reads_pcr_dup = 0;
  stats->num_single_end_reads_pcr_dup = 0;
  for(i=0;i<256;i++)
    stats->num_at_quality_score[i]=0;
  return stats;
}

void bam_stats_t_add(bam_stats_t *stats, bam1_t *b)
{
  if(b->core.flag & BAM_FPAIRED) { // paired end
    if(b->core.flag & BAM_FREAD1) { // first read
      stats->num_raw_paired_reads++;
      if(!(b->core.flag & BAM_FUNMAP) && !(b->core.flag & BAM_FMUNMAP)) {
        // both ends mapped
        stats->num_paired_reads++;
        if(b->core.flag & BAM_FDUP) stats->num_paired_reads_pcr_dup++;
      }
      else if(!(b->core.flag & BAM_FUNMAP) && (b->core.flag & BAM_FMUNMAP)) {
        // this end mapped, mate unmapped
        stats->num_unpaired_reads++;
        if(b->core.flag & BAM_FDUP) stats->num_unpaired_reads_pcr_dup++;
      }
      else if((b->core.flag & BAM_FUNMAP) && !(b->core.flag & BAM_FMUNMAP)) {
        // this end unmapped, mate mapped
        stats->num_unpaired_reads++;
        if(b->core.flag & BAM_FDUP) stats->num_unpaired_reads_pcr_dup++;
      }
    }
  }
  else { // single end
    stats->num_raw_single_end_reads++;
    if(!(b->core.flag & BAM_FUNMAP)) { // mapped
      stats->num_single_end_reads++;
      if(b->core.flag & BAM_FDUP) stats->num_single_end_reads_pcr_dup++;
    }
  }
  // Update mapq
  stats->num_at_quality_score[b->core.qual]++; // this exploits the fact that b->core.qual is an unsigned 8-bit integer.
}

void bam_stats_t_print(bam_stats_t *stats, char *seed)
{
  FILE *fp;
  char fn_stats[100] = {0};

  /* First, the basic key value pairs */
  strcpy(fn_stats, seed);
  strcat(fn_stats, ".stats.csv");
  if ((fp = fopen(fn_stats, "w")) == NULL) {
    fprintf(stderr, "Problems writing to file %s.", fn_stats);
    exit(1);
  }

  fprintf(fp, "key,value\n"); // CSV header
  fprintf(fp, "Number of raw paired reads,%lld\n",
      (long long int)stats->num_raw_paired_reads);
  fprintf(fp, "Number of raw single end reads,%lld\n",
      (long long int)stats->num_raw_single_end_reads);
  fprintf(fp, "Number of mapped paired reads,%lld\n",
      (long long int)stats->num_paired_reads);
  fprintf(fp, "Number of mapped unpaired reads,%lld\n",
      (long long int)stats->num_unpaired_reads);
  fprintf(fp, "Number of mapped single end reads,%lld\n",
      (long long int)stats->num_single_end_reads);
  fprintf(fp, "Number of mapped paired reads pcr duplicates,%lld\n",
      (long long int)stats->num_paired_reads_pcr_dup);
  fprintf(fp, "Number of mapped unpaired reads pcr duplicates,%lld\n",
      (long long int)stats->num_unpaired_reads_pcr_dup);
  fprintf(fp, "Number of mapped single end reads pcr duplicates,%lld\n",
      (long long int)stats->num_single_end_reads_pcr_dup);
  fclose(fp);

  /* Now the mapq distribution key value pairs. */
  int32_t i;
  char fn_mapq[100] = {0};

  /* First, the basic key value pairs */
  strcpy(fn_mapq, seed);
  strcat(fn_mapq, ".mapq.dist.csv");
  if ((fp = fopen(fn_mapq, "w")) == NULL) {
    fprintf(stderr, "Problems writing to file %s.", fn_mapq);
    exit(1);
  }

  fprintf(fp, "amount,mapping_quality\n");
  for(i=0;i<256;i++)
    fprintf(fp, "%lld,%d\n", (long long int)stats->num_at_quality_score[i], i);

  fclose(fp);
}

void bam_stats_t_destroy(bam_stats_t *s)
{
  free(s);
  s=NULL;
}
