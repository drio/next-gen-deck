#include <assert.h>
#include "dump_stats.h"

static void open_for_output(FILE **fp, char *fname, char *seed, char *rest)
{
  strcpy(fname, seed);
  strcat(fname, rest);
  *fp = fopen(fname, "w");
  assert(*fp);
}

void dump_stats(ngd_bam_flagstat_t *s, char *seed)
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

void dump_is(ngd_bam_flagstat_t *s, char *seed)
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

void dump_mapq(ngd_bam_flagstat_t *s, char *seed)
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
static int header_records(char *rt, char *t, int p, char *t_text, int *i)
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
  fprintf(fp, "record,tag,value,\n"); // header

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

  fprintf(fp, "%s", t_text);
  fclose(fp);
}

