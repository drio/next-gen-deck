#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>

#include "bam.h"
#include "dump_stats.h"
#include "flag_stat.h"

#define PRG_NAME "ngd-stats"

int main(int argc, char *argv[])
{
  bamFile fp;
  bam_header_t *header;
  ngd_bam_flagstat_t *s;

  if (argc != 3) {
    fprintf(stderr, "Usage: %s <output_seed> <in.bam>\n", PRG_NAME);
    return 1;
  }

  char seed_name[50] = {0};
  strcpy(seed_name, argv[1]);

  /* Iterate over the bam and gather the different metrics */
  fp = strcmp(argv[2], "-") ? bam_open(argv[2], "r") : bam_dopen(fileno(stdin), "r");
  assert(fp);
  header = bam_header_read(fp);
  s = ngd_bam_flagstat_core(fp);

  /* I have the data ready, let's print the results to the different csv files */
  dump_stats(s, seed_name);
  dump_is(s, seed_name);
  dump_mapq(s, seed_name);
  dump_header_data(header->text, header->l_text, seed_name);

  /* Clean up*/
  free(s);
  bam_header_destroy(header);
  bam_close(fp);
  return 0;
}
