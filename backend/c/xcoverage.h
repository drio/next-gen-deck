#ifndef XCOVERAGE_H
#define XCOVERAGE_H

#include "sam.h"

#define MIN_MAP_QUAL 1
#define MAX_XCOV 1000 // Maximum value for the distribution of coverage

typedef struct {
  int beg, end;
  samfile_t *in;
  int *a_cov; // Distribution of coverage data here
} tmpstruct_t;

int *gather_xcoverage(char *);

#endif
