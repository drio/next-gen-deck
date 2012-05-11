#!/usr/bin/env ruby
#
# load2redis.rb
#
# This tool will traverse the current directory looking for
# csv files. When found, it would update redis with the contents.
#
# All deps (except redis) come with ruby
#
require 'find'
require 'csv'
require 'pp'
require 'redis'
require 'json'

def per(total, n)
  ((n.to_f*100)/total.to_f).round(2)
end

# Dump into redis the data we just loaded, do it
# in such a way that later we can query redis
# via web and answer these type of questions:
#
# 1. The [ %_mapped || %_dups ] for all the bams
#   redis: per_mapped[bam_full_path] = %_of_mapped
#   query: http://127.0.0.1:7379/HVALS/per_mapped
#
# 2. All the isizes/amount pairs for a particular bam
#   redis: stats[full_path] = val
#
# TODO: This needs heavy refactoring ... looks uggly
def dump_in_redis(h)
  redis = Redis.new
  h.each do |levels, h_csvs|              # a directory
    h_csvs.each do |csv, a_data|          # csvs on that directory
      dist_is, dist_mq_r1, dist_mq_r2 = [{}, {}, {}]
      n_reads = nil
      a_data.each_with_index do |line, i| # a line from a csv
        # If we are processing a csv stats and we are in the metric we
        # are interested on, dump it to redis
        if csv =~ /stats/
          n_reads = line[1] if line[0] == "n_reads"
          if line[0] == "n_duplicate_reads"
            redis.hset("per_dups", levels, per(n_reads,line[1]))
          end
          if line[0] == "n_reads_mapped"
            redis.hset("per_mapped", levels, per(n_reads, line[1]))
          end
        end

        # Keep the dist values for the different distributions for later
        dist_is[line[0].to_i]    = line[1].to_i if csv =~ /isize/ && i != 0
        dist_mq_r1[line[0].to_i] = line[1].to_i if csv =~ /r1\.mapq/  && i != 0
        dist_mq_r2[line[0].to_i] = line[1].to_i if csv =~ /r2\.mapq/  && i != 0
      end

      # if we have distribution data, dump it in redis as a JSON object
      clean_level = levels.gsub(/\s/, '-')
      redis.set "is-"    + clean_level, dist_is.to_json    unless dist_is.empty?
      redis.set "mq-r1-" + clean_level, dist_mq_r1.to_json unless dist_mq_r1.empty?
      redis.set "mq-r2-" + clean_level, dist_mq_r2.to_json unless dist_mq_r2.empty?
    end
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
  h[levels.join(" ")][f_name.gsub(/\.csv/, '')] = CSV.read fpath
  return h
end

# MAIN
#
$stderr.puts ">> Loading csvs ..."
csvs = Hash.new {|h, k| h[k] = {}}
Find.find(".") do |f|
  next unless f =~ /\.csv$/
  csvs = load_data csvs, f
end
$stderr.puts ">> Dumping into redis ..."
dump_in_redis csvs
