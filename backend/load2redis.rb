#!/usr/bin/env ruby
#
# load2redis.rb
#
# This tool will traverse the current directory looking for
# csv files. When found, it would update redis with the contents.
#
# All deps (except redis) come with ruby
#
%w{find csv pp redis json ostruct}.each {|l| require l}

# Dump into redis the data we just loaded, do it
# in such a way that later we can query redis
# via web and answer these type of questions:
#
# 1. The [ %_mapped || %_dups ] for all the bams
# 2. All the isizes/amount pairs for a particular bam
#
# We will basically set key/vals where the vals are going to
# have json data
#
module ToRedis
  REDIS = Redis.new

  def ToRedis.dump(hash_with_all_the_csvs)
    h    = hash_with_all_the_csvs
    @all = {} # we'll keep here the stats for all the bams
    h.each do |levels, h_csvs|              # a directory
      h_csvs.each do |csv, a_data|          # csvs on that directory
        @dists = prepare_dist_struct        # hashes storing the dists per bam
        n_reads = nil                       # number of reads in a bam
        a_data.each_with_index do |line, i| # a line from a csv
          n_reads = line[1] if line[0] == "n_reads"
          process_line csv, line, i, n_reads
        end
        send_dists_to_redis levels
      end
    end
    # Dump all the events that we have and its stats
    REDIS.set "stats", @all.to_json
  end

  def ToRedis.process_line(csv, line, i, n_reads)
    d = @dists; l = line;
    if csv =~ /stats/
      if line[0] == "n_duplicate_reads" # Calculate %, and save it
        d.stats["per_dups"]   = per n_reads, l[1]
      elsif l[0] == "n_reads_mapped"    # Calculate %, and save it
        d.stats["per_mapped"] = per n_reads, l[1]
      else                              # Regular stat, save it
        d.stats[line[0]] = line[1]
      end
    end
    # Keep the dist values for the different distributions for later
    d.is[l[0].to_i]    = l[1].to_i if csv =~ /isize/     && i != 0
    d.mq_r1[l[0].to_i] = l[1].to_i if csv =~ /r1\.mapq/  && i != 0
    d.mq_r2[l[0].to_i] = l[1].to_i if csv =~ /r2\.mapq/  && i != 0
  end

  def ToRedis.per(total, n)
    ((n.to_f*100)/total.to_f).round(2)
  end

  def ToRedis.prepare_dist_struct
    os = OpenStruct.new
    os.is = {}; os.mq_r1 = {}; os.mq_r2 = {}; os.stats = {}
    os
  end

  def ToRedis.send_dists_to_redis(levels)
    r = REDIS; d = @dists
    # Save the stats so we can dump to redis later
    @all[levels] = d.stats unless d.stats.empty?

    # if we have distribution data, dump it in redis as a JSON object
    r.set "is-"    + levels, tj("isize", d.is)    unless d.is.empty?
    r.set "mq-r1-" + levels, tj("mq-r1", d.mq_r1) unless d.mq_r1.empty?
    r.set "mq-r2-" + levels, tj("mq-r2", d.mq_r2) unless d.mq_r2.empty?
  end

  # The value of the keys stored in redis have to have
  # to attributes, one is the type and the other the data (json data)
  # The type will be use in the client to determine what type
  # of data we have in the object
  def ToRedis.tj(type, data)
    if type == "isize"
      data[-1] = 0;
      reduced_data = {};
      data.each {|k,v| reduced_data[k] = v if k <= 1000}
      data = reduced_data
    end
    {"type" => type, "data" => data}.to_json
  end
end

#
# The data structure that holds the directory and csv data looks like:
# h[levels][csv] = [ [HEADER], [line1], [line2], .... [lineN]]
#
def load_data(h, fpath)
  dir    = File.dirname  fpath
  f_name = File.basename fpath
  levels = fpath.split('/')
  levels.delete('.'); levels.pop
  h[levels.join(">>")][f_name.gsub(/\.csv/, '')] = CSV.read fpath
  h
end

# MAIN
#
$stderr.puts ">> Loading csvs ..."
csvs = Hash.new {|h, k| h[k] = {}}
Find.find(".") {|f| csvs = load_data csvs, f if f =~ /\.csv$/ }
$stderr.puts ">> Dumping into redis ..."
#dump_in_redis csvs
ToRedis.dump csvs
