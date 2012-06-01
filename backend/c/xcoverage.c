#include <stdio.h>
#include "xcoverage.h"

/* callback for bam_plbuf_init()
 *
 * tid : chromosome ID as is defined in the header
 * pos : start coordinate of the alignment, 0-based
 * n   : number of elements in pl array (alignments at that locus)
 * pl  : array of alignments
 * data: user provided data
 *
 */
static int pileup_func(uint32_t tid, uint32_t pos, int n, const bam_pileup1_t *pl, void *data)
{
  tmpstruct_t *tmp = (tmpstruct_t*)data;
  int ia; // Index of alignment (in pl array)
  int n_good_alignments = 0; // Count valid alignments for locus (mapq ok)
  if ((int)pos >= tmp->beg && (int)pos < tmp->end) { // coordinate reasonable
  /*
   * It seems that when working on pileup on a full bam (no regions) there
   * is no way to make samtools use a callback to filter alignments (mapq).
   * I will have to take care of that here.
   */
   //printf("%s\t%d\t%d\n", tmp->in->header->target_name[tid], pos + 1, n);
   for(ia=0; ia<n; ia++)
     if (pl[ia].b->core.qual >= MIN_MAP_QUAL) // MAPQ for alignment is "fine"
       n_good_alignments++;

    if (n_good_alignments < MAX_XCOV)
      tmp->a_cov[n_good_alignments]++;
    else
      tmp->a_cov[MAX_XCOV-1]++; // If crazy coverage, set it to MAX_XCOV-1
  }
  return 0;
}

/*
 * Only entry point for this module. We just need the name of the bam we
 * want to process (bam_fn) and we will return the data for the distrubution
 * of coverage
 */
int *gather_xcoverage(char *bam_fn)
{
  tmpstruct_t tmp; // TODO: change var name, band name

  tmp.a_cov = (int *) calloc(MAX_XCOV, sizeof(int));
  if (tmp.a_cov == NULL) {
    fprintf(stderr, "gather_xcoverage(): couldn't allocate mem for a_cov.\n");
    exit(1);
  }

  tmp.beg = 0; tmp.end = 0x7fffffff;
  tmp.in = samopen(bam_fn, "rb", 0);
  sampileup(tmp.in, -1, pileup_func, &tmp);
  samclose(tmp.in);

  return tmp.a_cov;
}
