CC=gcc
CFLAGS=-g -Wall -O2
DFLAGS=-D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE
INCLUDES=-I$(SAMTOOLS) -I.
LIBPATH=-L$(SAMTOOLS) -lbam -lm -lz
TOOL=ngd-stats
WATCH_FILES=dump_stats.c flag_stat.c ngd-stats.c test-ngd-stats.c dump_stats.h flag_stat.h
OBJS=flag_stat.o dump_stats.o

all: ngd-stats

%.o: %.c
	$(CC) -c $(CFLAGS) $(INCLUDES) $< -o $@

ngd-stats: $(OBJS) ngd-stats.o
	$(CC) $(CFLAGS) $(INCLUDES) $+ $(LIBPATH) -o $@

utest: $(OBJS) test-ngd-stats.c
	$(CC) $(CFLAGS) $(INCLUDES) $+ $(LIBPATH) -o $@

watch:
	ruby ../rb/test/watcher.rb "make utest && ./utest" $(WATCH_FILES)

.PHONY: watch

clean:
	rm -f *.o ngd-stats
