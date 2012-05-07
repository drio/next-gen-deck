#ifndef DBAMPAIREDENDDIST_H_
#define DBAMPAIREDENDDIST_H_

#include <zlib.h>
#include "../bfast/bfast/RGIndex.h"
#include "../bfast/bfast/RGBinary.h"
#include "../bfast/bfast/RGMatch.h"

typedef struct {
	int minDistance;
	int maxDistance;
	int binSize;
	int32_t *counts;
	int32_t numCounts;
} Bins;

int BinsInsert(Bins*, int32_t);
void BinsPrint(Bins*, FILE*);
#endif
