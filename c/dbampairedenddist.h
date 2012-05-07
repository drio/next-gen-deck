#ifndef DBAMPAIREDENDDIST_H_
#define DBAMPAIREDENDDIST_H_

#include <zlib.h>
#include "RGIndex.h"
#include "RGBinary.h"
#include "RGMatch.h"

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
