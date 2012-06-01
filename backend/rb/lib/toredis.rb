%w{find csv pp redis json ostruct}.each {|l| require l}

# Iterate over the csvs in the current dir and dump
# the data into redis so we can retrieve it from the
# client.
#
class ToRedis
  MAX_ISIZE = 1000 # see #reduce
  attr_reader :stats, :dists, :redis

  def initialize(r)
    @redis = r
    @stats = Hash.new {|h,k| h[k] = {}}
    @dists = Hash.new {|h,k| h[k] = {}}
    @pers  = { "n_duplicate_reads" => "per_dups",
               "n_reads_mapped"    => "per_mapped" }
    @seeds_to_dist_name = { "is-"    => "isize.dist",
                            "mq-r1-" => "r1.mapq.dist",
                            "mq-r2-" => "r2.mapq.dist",
                            "xcov-"  => "xcov.dist"}
  end

  # We may have very long tails in the isize distributions
  # cut that off so we can plot it nicely
  def reduce(dist_name)
    dist_name =~ /^is/ ?
    @dists[dist_name].select {|k,v| k.to_i < MAX_ISIZE && k.to_i > -1} :
    @dists[dist_name]
  end

  # p_dir: the name of the directory of the bam we are working on
  def set_in_redis(prev_dir)
    @seeds_to_dist_name.each do |seed, dist_name|
      r_key_name = seed + prev_dir
      @redis.set r_key_name, JSON({
          "type" => seed,
          "data" => reduce(dist_name)
        })
    end
  end

  # Traverses all the dirs recursively, find csvs, extract
  # the data and create key/values in redis
  #
  def run
    prev_dir = nil
    each do |dir, type, row|
       # We have processed a dir
      set_in_redis(prev_dir) if !prev_dir.nil? && dir != prev_dir
      prev_dir = dir
      process_row dir, type, row
    end
    # Set the data for the remaining bam
    set_in_redis(prev_dir)
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
        @dists["isize.dist"][row[0]] = row[1].to_i
      when /r[1|2]\.mapq/
        key = "rN.mapq.dist".gsub(/N/, type.match(/r([1|2])\.mapq/)[1])
        @dists[key][row[0]] = row[1].to_i
      when /xcov/
        @dists["xcov.dist"][row[0]] = row[1].to_i
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
