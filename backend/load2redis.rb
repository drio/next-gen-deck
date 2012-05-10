#!/usr/bin/env ruby
#
# load2redis.rb
#
# This tool will traverse the current directory looking for
# csv files. When found, it would update redis with the contents.
#
require 'find'
require 'csv'
require 'pp'
require 'redis'
require 'json'
require 'open-uri'

# Question that will be asked from the frontend
# 1. The [ %_mapped || %_dups ] for all the bams
#   redis: per_mapped[bam_full_path] = %_of_mapped
#   query: http://127.0.0.1:7379/HVALS/per_mapped
#
# 2. All the isizes/amount pairs for a particular bam
#   redis: stats[full_path] = val

def dump_in_redis(h)
  rhn   = "per_mapped" # redis hash name
  redis = Redis.new
  h.each do |levels, h_csvs|
    h_csvs.each do |csv, a_data|
      #puts "levels: #{levels}"; puts "file: #{csv}"; o = {:header => "", :data => ""}
      dist_is, dist_mq_r1, dist_mq_r2 = [{}, {}, {}]
      a_data.each_with_index do |line, i|
        #o[:header] = line if i == 0
        #o[:data]   = " " + line.to_s if i != 0
        if csv =~ /dist\.stats/ && line[0] == "n_reads_mapped"
          redis.hset(rhn, levels, line[1])
        end
        dist_is[line[0].to_i] = line[1].to_i if csv =~ /isize/ && i != 0
        dist_mq_r1[line[0].to_i] = line[1].to_i if csv =~ /r1\.mapq/  && i != 0
        dist_mq_r2[line[0].to_i] = line[1].to_i if csv =~ /r2\.mapq/  && i != 0
      end
      redis.set "is-" + levels.gsub(/\s/, '-'), dist_is.to_json unless dist_is.empty?
      redis.set "mq-r1-" + levels.gsub(/\s/, '-'), dist_mq_r1.to_json unless dist_mq_r1.empty?
      redis.set "mq-r2-" + levels.gsub(/\s/, '-'), dist_mq_r2.to_json unless dist_mq_r2.empty?
      #puts "header: #{o[:header]}"; puts "data: #{o[:data]}"
    end
  end
end

def load_data(h, fpath)
  dir    = File.dirname  fpath
  f_name = File.basename fpath
  levels = fpath.split('/')
  levels.delete('.'); levels.pop
  h[levels.join(" ")][f_name.gsub(/\.csv/, '')] = CSV.read fpath
  return h
end

$stderr.puts ">> Loading csvs ..."
csvs = Hash.new {|h, k| h[k] = {}}
Find.find(".") do |f|
  next unless f =~ /\.csv$/
  csvs = load_data csvs, f
end
$stderr.puts ">> Dumping into redis ..."
dump_in_redis csvs


=begin
redis = Redis.new

foo = { 1 => 1234234, 2 => 234535, 3 => 566666 }

# q1
redis.hset("bar", "1", "XXXXXXX")
redis.hset("bar", "2", "YYYYYYY")
pp redis.hvals("bar")

# q2
redis.set "q2", foo.to_json
puts JSON.parse(redis.get("q2"))
=end
