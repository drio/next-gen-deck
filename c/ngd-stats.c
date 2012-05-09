#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include "bam.h"

#define PRG_NAME "ngd-stats"
#define MAX_ISIZE_VALUE 100000
#define MAX_MAPPING_QUAL 255

typedef struct {
  long long n_reads[2], n_mapped[2], n_pair_all[2], n_pair_map[2], n_pair_good[2];
  long long n_sgltn[2], n_read1[2], n_read2[2];
  long long n_dup[2];
  long long n_diffchr[2], n_diffhigh[2];
  long long is_dist[MAX_ISIZE_VALUE];
  long long mapq_dist_r1[MAX_MAPPING_QUAL];
  long long mapq_dist_r2[MAX_MAPPING_QUAL];
} bam_flagstat_t;

inline void flagstat_loop(bam_flagstat_t *s, bam1_core_t *c)
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

bam_flagstat_t *bam_flagstat_core(bamFile fp)
{
  bam_flagstat_t *s;
  bam1_t *b;
  bam1_core_t *c;
  int ret;
  s = (bam_flagstat_t*)calloc(1, sizeof(bam_flagstat_t));
  b = bam_init1();
  c = &b->core;
  while ((ret = bam_read1(fp, b)) >= 0)
    flagstat_loop(s, c);
  bam_destroy1(b);
  if (ret != -1)
    fprintf(stderr, "[bam_flagstat_core] Truncated file? Continue anyway.\n");
  return s;
}

void open_for_output(FILE **fp, char *fname, char *seed, char *rest)
{
  strcpy(fname, seed);
  strcat(fname, rest);
  *fp = fopen(fname, "w");
  assert(*fp);
}

void dump_stats(bam_flagstat_t *s, char *seed)
{
  FILE *fp;
  char fname[100];

  open_for_output(&fp, fname, seed, ".stats.csv");
  fprintf(fp, "key,value\n"); // header
  fprintf(fp, "n_reads,%lld\n", s->n_reads[0]);
  fprintf(fp, "n_failed_reads,%lld\n", s->n_reads[1]);
  fprintf(fp, "n_duplicate_reads,%lld\n", s->n_dup[0]);
  fprintf(fp, "n_reads_mapped,%lld\n", s->n_mapped[0]);
  fprintf(fp, "n_paired_reads,%lld\n", s->n_pair_all[0]);
  fprintf(fp, "n_read1,%lld\n", s->n_read1[0]);
  fprintf(fp, "n_read2,%lld\n", s->n_read2[0]);
  //printf("%lld + %lld properly paired (%.2f%%:%.2f%%)\n", s->n_pair_good[0], s->n_pair_good[1], (float)s->n_pair_good[0] / s->n_pair_all[0] * 100.0, (float)s->n_pair_good[1] / s->n_pair_all[1] * 100.0);
  fprintf(fp, "n_both_ends_mapped,%lld\n", s->n_pair_map[0]);
  fprintf(fp, "n_pairs_only_one_end_mapped,%lld\n", s->n_sgltn[0]);
  fprintf(fp, "n_pairs_with_mate_mapping_to_diff_chrms,%lld\n", s->n_diffchr[0]);
  //printf("%lld + %lld with mate mapped to a different chr (mapQ>=5)\n", s->n_diffhigh[0], s->n_diffhigh[1]);

  fclose(fp);
}

void dump_is(bam_flagstat_t *s, char *seed)
{
  FILE *fp;
  char fname[100];
  int i;

  open_for_output(&fp, fname, seed, ".isize.dist.csv");
  fprintf(fp, "isize,amount\n"); // header
  for (i=-1; i<MAX_ISIZE_VALUE; ++i)
    fprintf(fp, "%d,%lld\n", i, s->is_dist[i]);
  fclose(fp);
}

void dump_mapq(bam_flagstat_t *s, char *seed)
{
  FILE *fp_r1, *fp_r2;
  char fname[100];
  int i;

  open_for_output(&fp_r1, fname, seed, ".r1.mapq.dist.csv");
  open_for_output(&fp_r2, fname, seed, ".r2.mapq.dist.csv");
  fprintf(fp_r1, "mapq,amount\n"); // header
  fprintf(fp_r2, "mapq,amount\n"); // header
  for (i=0; i<MAX_MAPPING_QUAL; ++i) {
    fprintf(fp_r1, "%d,%lld\n", i, s->mapq_dist_r1[i]);
    fprintf(fp_r2, "%d,%lld\n", i, s->mapq_dist_r2[i]);
  }
  fclose(fp_r1);
  fclose(fp_r2);
}

/*
 * When called, things look like:
 *      p
 *      |
 * @RG\tID:0\tPL:Illumina\n
 *
 * rt    : type of record RG or PG
 * t     : header text
 * p     : pointer in t
 * t_text: csv version of the records (and its tags) we are interested on
 * i     : index in t_text
 *
 * returns: updated pointer to the header text
 *
 * Other RG/PG examples:
 * @RG     ID:0    PL:Illumina     PU:700821_20111116_D0GN3ACXX-5-ID09     LB:IWX_RMMYJR.18277-1_1pA       DT:2011-12-14T14:55:08-0600     SM:18277        CN:BCM
 * @PG     ID:bwa  PN:bwa  VN:0.5.9-r16*
 */
int header_records(char *rt, char *t, int p, char *t_text, int *i)
{
  int j;

  while (t[p] != '\n') { // while still on line
    // The first column on the csv has to be the record type
    t_text[*i] = rt[0]; t_text[(*i)+1] = rt[1]; t_text[(*i)+2] = ','; *i = (*i)+3;

    for (j=0; j<2; ++j, ++p, ++(*i)) // get the tag_name
      t_text[*i] = t[p];

    ++p; // skip ':' in header text and put the separator
    t_text[*i] = ','; (*i)++;

    while (t[p] != '\t' && t[p] != '\n') { // get the tag value
      t_text[*i] = t[p];
      ++(*i);
      ++p;
    }

    t_text[*i] = ',' ; (*i)++;
    t_text[*i] = '\n'; (*i)++;
    if (t[p] == '\t') ++p;
  }

  return p;
}

/*
 * text: header text
 * nc  : number of chrs in text
 * seed: seed name for the output file
 *
 * Finds the RG and PG tag lines, and calls another auxiliar function
 * that will extract all the records for those tags and set them in
 * csv format. Then the csv is saved to a file.
 */
void dump_header_data(char *text, int nc, char *seed)
{
  FILE *fp;
  char fname[100];
  int p, i, j; // pointer in text, index in s_tag, index in t_text;
  char s_tag[4];
  char t_text[100000]; // text of one tag TODO: dynamic!!

  open_for_output(&fp, fname, seed, ".header.csv");
  fprintf(fp, "key,value\n"); // header

  p = 0; s_tag[3] = '\0';
  i = j = 0;
  while (p < nc) {
    for (i=0; i<3; ++i) s_tag[i] = text[p+i];
    // notice how we set the pointer to the right place before the call +4
    if (strcmp(s_tag, "@RG") == 0)
      p = header_records("RG", text, p+4, t_text, &j);
    if (strcmp(s_tag, "@PG") == 0)
      p = header_records("PG", text, p+4, t_text, &j);
    ++p;
  }
  printf("-------------\n");
  printf("%s", t_text);
  printf("-------------\n");

  fclose(fp);
}

int main(int argc, char *argv[])
{
  bamFile fp;
  bam_header_t *header;
  bam_flagstat_t *s;

  if (argc != 3) {
    fprintf(stderr, "Usage: %s flagstat <output_seed> <in.bam>\n", PRG_NAME);
    return 1;
  }

  char seed_name[50] = {0};
  strcpy(seed_name, argv[1]);

  fp = strcmp(argv[2], "-") ? bam_open(argv[2], "r") : bam_dopen(fileno(stdin), "r");
  assert(fp);
  header = bam_header_read(fp);
  s = bam_flagstat_core(fp);
  dump_stats(s, seed_name);
  dump_is(s, seed_name);
  dump_mapq(s, seed_name);
  dump_header_data(header->text, header->l_text, seed_name);

  free(s);
  bam_header_destroy(header);
  bam_close(fp);
  return 0;
}
