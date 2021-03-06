#ifndef DUMP_STATS_H
#define DUMP_STATS_H

#include "flag_stat.h"
#include "xcoverage.h"

void dump_stats(ngd_bam_flagstat_t *, char *);
void dump_is(ngd_bam_flagstat_t *, char *);
void dump_mapq(ngd_bam_flagstat_t *, char *);
int header_records(char *, char *, int, char *, int *);
void dump_header_data(char *, int nc, char *);
void dump_xcov(int *, char *);
#endif
