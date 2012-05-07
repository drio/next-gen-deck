#ifndef DBAMSTATS_H_
#define DBAMSTATS_H_


typedef struct {
	int64_t num_raw_paired_reads;
	int64_t num_raw_single_end_reads;
	// below are mapped
	int64_t num_paired_reads;
	int64_t num_unpaired_reads;
	int64_t num_single_end_reads;
	int64_t num_at_quality_score[256];
	int64_t num_single_end_reads_pcr_dup;
	int64_t num_unpaired_reads_pcr_dup;
	int64_t num_paired_reads_pcr_dup;
} bam_stats_t;

bam_stats_t *bam_stats_t_init();
void bam_stats_t_add(bam_stats_t*, bam1_t*);
void bam_stats_t_print(bam_stats_t*, char*);
void bam_stats_t_destroy(bam_stats_t*);

#endif
