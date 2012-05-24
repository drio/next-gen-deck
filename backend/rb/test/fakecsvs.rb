require 'fileutils'

# Fake some directory and its csvs
#
module FakeCSVS
  ROOT   = "/tmp/fake.bams"
  FU     = FileUtils

  def FakeCSVS.doit(seeds_csv, prjs_bams)
    FU.rm_rf   ROOT; FU.mkdir ROOT

    prjs_bams.each do |id|
      new_dir = ROOT + "/" + id
      FU.mkdir_p new_dir
      seeds_csv.each do |sc| # add some csvs
        File.open(new_dir + "/" + sc + ".csv", "w") do |f|
          f.puts header(sc)
          f.puts gen_rows(sc).join("\n")
        end
      end
    end
  end

  def FakeCSVS.header(seed)
    seed == "header" ? "record,tag,value" : "key, value"
  end

  def FakeCSVS.gen_rows(sc)
    rows = []
    case sc
      when /r1/
        rows << "1,100" << "2,200"
      when /r2/
        rows << "3,300" << "4,200"
      when /stats/
        rows << "n_reads,10" << "n_read1,5" << "n_read2,5" <<
                "n_duplicate_reads,1" << "n_reads_mapped,8"
      when /isize/
        rows << "300,100" << "200,50"
      when /header/
        rows << "RG,ID,0," << "RG,PL,Illumina," << "PG,PN,bwa,"
      else
        raise "We shouldn't get here, I don't understand the TYPE"
    end
    rows
  end
end

