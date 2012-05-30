#include "flag_stat.h"

/* This function and the associated structs are stolen from samtools */
inline void ngd_flagstat_loop(ngd_bam_flagstat_t *s, bam1_core_t *c)
{
  int absolute, is_index;
  int w = (c->flag & BAM_FQCFAIL) ? 1 : 0;
  ++(s)->n_reads[w];

  if ((c)->flag & BAM_FPAIRED) {
    ++(s)->n_pair_all[w];
    if ((c)->flag & BAM_FPROPER_PAIR) ++(s)->n_pair_good[w];
    if ((c)->flag & BAM_FREAD1) ++(s)->n_read1[w];
    if ((c)->flag & BAM_FREAD2) ++(s)->n_read2[w];
    if (((c)->flag & BAM_FMUNMAP) && !((c)->flag & BAM_FUNMAP)) ++(s)->n_sgltn[w];
    if (!((c)->flag & BAM_FUNMAP) && !((c)->flag & BAM_FMUNMAP)) { // both ends map
      // For insert size distribution
      if (c->isize) { // 0 in isize means the isize calc is in the other mate, skip.
        absolute = (c->isize < 0) ? c->isize * -1 : c->isize;
        is_index = (absolute > MAX_ISIZE_VALUE) ? -1 : absolute;
        ++(s)->is_dist[is_index];
      }

      ++(s)->n_pair_map[w];
      if ((c)->mtid != (c)->tid) {
        ++(s)->n_diffchr[w];
        if ((c)->qual >= 5) ++(s)->n_diffhigh[w];
      }
    }
  }
  if (!((c)->flag & BAM_FUNMAP)) {
    ++(s)->n_mapped[w];
    if ((c)->flag & BAM_FREAD1)
      ++(s)->mapq_dist_r1[c->qual];
    else
      ++(s)->mapq_dist_r2[c->qual];
  }
  if ((c)->flag & BAM_FDUP) ++(s)->n_dup[w];
}

ngd_bam_flagstat_t *ngd_bam_flagstat_core(bamFile fp)
{
  ngd_bam_flagstat_t *s;
  bam1_t *b;
  bam1_core_t *c;
  int ret;
  s = (ngd_bam_flagstat_t*)calloc(1, sizeof(ngd_bam_flagstat_t));
  b = bam_init1();
  c = &b->core;
  while ((ret = bam_read1(fp, b)) >= 0)
    ngd_flagstat_loop(s, c);
  bam_destroy1(b);
  if (ret != -1)
    fprintf(stderr, "[bam_flagstat_core] Truncated file? Continue anyway.\n");
  return s;
}

