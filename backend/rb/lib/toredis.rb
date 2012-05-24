%w{find csv pp redis json ostruct}.each {|l| require l}

# Iterate over the csvs in the current dir and dump
# the data into redis so we can retrieve it from the
# client.
#
class ToRedis
  attr_reader :stats, :dists, :redis

  def initialize(r)
    @redis = r
    @stats = Hash.new {|h,k| h[k] = {}}
    @dists = Hash.new {|h,k| h[k] = {}}
    @pers  = { "n_duplicate_reads" => "per_dups",
               "n_reads_mapped"    => "per_mapped" }
    @seeds_to_dist_name = { "is-"    => "isize.dist",
                            "mq-r1-" => "r1.mapq.dist",
                            "mq-r2-" => "r2.mapq.dist"}
  end

  # Traverses all the dirs recursively, find csvs, extract
  # the data and create key/values in redis
  #
  def run
    prev_dir = nil
    each do |dir, type, row|
      if !prev_dir.nil? && dir != prev_dir # We have processed a dir
        @seeds_to_dist_name.each {|k,v| @redis.set k + prev_dir, JSON(@dists[v]); }
      end
      prev_dir = dir
      process_row dir, type, row
    end
    # Set the data for the remaining bam
    @seeds_to_dist_name.each {|k,v| @redis.set k + prev_dir, JSON(@dists[v]) }
    # We are done processing everything, set ALL the stats in redis
    @redis.set "stats", JSON(@stats)
  end

  # Process 1 row from a csv. It will store the data in the row in
  # the appropiate hash to be sent to redis later
  #
  # bam : the ID or dirpath to the csv file being processed
  # type: the type of csv we are working on
  # row : an array of the row
  #
  def process_row(bam, type, row)
    case type
      when /stats/
        @stats[bam][row[0]] = row[1]
        @n_reads = row[1] if row[0] == "n_reads"
        # percentage
        if @pers.keys.include? row[0]
          @stats[bam][@pers[row[0]]] = per @n_reads, row[1]
        end
      when /isize/
        @dists["isize.dist"][row[0]] = row[1]
      when /r[1|2]\.mapq/
        key = "rN.mapq.dist".gsub(/N/, type.match(/r([1|2])\.mapq/)[1])
        @dists[key][row[0]] = row[1]
      else
        raise RuntimeError, "I don't understand type: [#{type}]"
    end
  end

  def per(total, n)
    ((100*n.to_f)/total.to_f).round(2)
  end

  # iterate over all the data
  def each
    Find.find(".") do |f|  # csv file
      next unless f =~ /\.csv$/
      level, type = to_id f
      first_line = true
      CSV.read(f).each do |a|
        # TODO: We are not using the header yet
        unless first_line || type =~ /header/
          yield level, type, a
        else
          first_line = false
        end
      end
    end
  end

  # fpath: full path to csv file
  #
  # returns the id of that file, which is the
  # dir in fpath but changing the '/' to other character
  def to_id(fpath)
   dir        = File.dirname  fpath
   f_name     = File.basename fpath
   _tmp       = fpath.split('/')[1..-1]; _tmp.pop
   level      = _tmp.join(">>")
   type       = f_name.gsub(/\.csv/, '')
   [level, type]
  end
end


=begin
module ToRedis
  REDIS = Redis.new

  def ToRedis.dump(hash_with_all_the_csvs)
    h    = hash_with_all_the_csvs
    @all = {}                               # stats for all the bams
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
=end
