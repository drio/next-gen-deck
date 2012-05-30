#ifndef DUMP_STATS_H
#define DUMP_STATS_H

#include "flag_stat.h"

void dump_stats(ngd_bam_flagstat_t *, char *);
void dump_is(ngd_bam_flagstat_t *, char *);
void dump_mapq(ngd_bam_flagstat_t *, char *);
void dump_header_data(char *, int nc, char *);
#endif
