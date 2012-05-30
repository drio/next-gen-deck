#ifndef FLAG_STAT_H
#define FLAG_STAT_H

#include "bam.h"

#define MAX_ISIZE_VALUE 10000
#define MAX_MAPPING_QUAL 255

typedef struct {
  long long n_reads[2], n_mapped[2], n_pair_all[2], n_pair_map[2], n_pair_good[2];
  long long n_sgltn[2], n_read1[2], n_read2[2];
  long long n_dup[2];
  long long n_diffchr[2], n_diffhigh[2];
  long long is_dist[MAX_ISIZE_VALUE];
  long long mapq_dist_r1[MAX_MAPPING_QUAL];
  long long mapq_dist_r2[MAX_MAPPING_QUAL];
} ngd_bam_flagstat_t;

ngd_bam_flagstat_t *ngd_bam_flagstat_core(bamFile fp);
#endif
