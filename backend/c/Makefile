CC=gcc
CFLAGS=-g -Wall -O2
DFLAGS=-D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE
INCLUDES=-I$(SAMTOOLS) -I.
LIBPATH=-L$(SAMTOOLS) -lbam -lm -lz
TOOL=ngd-stats
OBJS=flag_stat.o dump_stats.o ngd-stats.o

all: ngd-stats

%.o: %.c
	$(CC) -c $(CFLAGS) $(INCLUDES) $< -o $@

ngd-stats: $(OBJS)
	$(CC) $(CFLAGS) $(INCLUDES) $+ $(LIBPATH) -o $@

clean:
	rm -f *.o ngd-stats
