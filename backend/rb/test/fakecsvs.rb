require 'fileutils'

# Fake some directory and its csvs
#
module FakeCSVS
  ROOT   = "/tmp/fake.bams"
  FU     = FileUtils

  def FakeCSVS.doit(seeds_csv, prjs_bams)
    FU.rm_rf   ROOT
    FU.mkdir_p ROOT

    prjs_bams.keys.each do |prj_name, bams| # create the prj_dirs
      new_dir = ROOT + "/" + prj_name
      FU.mkdir_p new_dir

      seeds_csv.each do |sc| # add some csvs
        File.open(new_dir + "/" + sc + ".csv", "w") do |f|
          f.puts header
          f.puts gen_rows(sc).join("\n")
        end
      end
    end
  end

  def FakeCSVS.header
    "key, value"
  end

  def FakeCSVS.gen_rows(sc)
    rows = []
    case sc
      when /r1/
        rows << "1, 100" << "2, 200"
      when /r2/
        rows << "3, 300" << "4, 200"
      when /stats/
        rows << "n_reads, 10" << "n_read1, 5" << "n_read2, 5"
      when /isize/
        rows << "300, 100" << "200, 50"
      else
        raise "We shouldn't get here, I don't understand the TYPE"
    end
    rows
  end
end

