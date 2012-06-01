#
# Help us generate random bams so we can have a
# dataset to use the nextgen deck with
#
class SimuData
  PRJS_NAMES = %w{TCGA sooty baboon cancer autism CRV twinning chimerism}
  SUB_PRJS   = %w{capture WGS}
  STRE_TOOL  = "ruby #{File.dirname $0}/stream_subset"
  TEMPLATE   = "mkdir -p DIR; samtools view -h INPUT_BAM | " +
               "#{STRE_TOOL} NUM SKIP | " +
               "java -Xmx1G -jar #{ENV['PICARD']}/SortSam.jar QUIET=true " +
               "SORT_ORDER=coordinate VALIDATION_STRINGENCY=STRICT INPUT=/dev/stdin OUTPUT=/dev/stdout |" +
               "samtools view -hb - > DIR/OBAM BACK"

  attr_reader :n_bams

  def initialize(n_bams, i_bam, n_pairs, background=false)
    @n_bams         = n_bams.to_i
    @i_bam          = i_bam
    @n_pairs        = n_pairs.to_s
    @run_background = background
  end

  def generate
    a = []; (1..@n_bams).each { a << inst_cmd }; a
  end

  def inst_cmd
    dir, fn = path
    TEMPLATE.gsub(/DIR/, dir)
            .gsub(/INPUT_BAM/, @i_bam)
            .gsub(/NUM/, @n_pairs)
            .gsub(/SKIP/, n_to_skip)
            .gsub(/OBAM/, fn)
            .gsub(/BACK/, @run_background ? "&" : "")
  end

  def n_to_skip
    r = rand(200000) - rand(200000)
    (r >= 0 ? r : r * -1).to_s
  end

  def path
    s_id = rand_sample_id
    [rand_prj + "/" + rand_sub_prj + "/" + s_id, s_id + ".bam"]
  end

  def rand_prj
    PRJS_NAMES[rand PRJS_NAMES.size]
  end

  def rand_sub_prj
    SUB_PRJS[rand SUB_PRJS.size]
  end

  def rand_sample_id
    (rand 1000000000).to_s
  end
end
