CC=gcc
CFLAGS=-g -Wall -O2
DFLAGS=-D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE
INCLUDES=-I$(SAMTOOLS) -I.
LIBPATH=-L$(SAMTOOLS)
TOOL=ngd-stats
OBJS=ngd-stats.o

.c.o:
	$(CC) -c $(CFLAGS) $(DFLAGS) $(INCLUDES) $< -o $@

all: ngd-stats

ngd-stats.o: ngd-stats.c

ngd-stats: $(OBJS)
	$(CC) $(CFLAGS) $(DFLAGS) $(INCLUDES) $(LIBPATH) -lm -lz -lbam -o $@ $(OBJS)

clean:
	rm -f *.o ngd-stats
