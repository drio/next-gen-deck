require 'simplecov'
SimpleCov.start
require 'autotest'
require 'test/unit'
require 'fileutils'

$: << File.join(File.dirname(File.dirname($0)), "lib")
require 'loading'
require 'toredis'

# Create some projects (Dirs) and some csvs on it
module FakeCSVS
  ROOT = "/tmp/fake.bams"
  def FakeCSVS.doit(seeds_csv, prjs)
    fu   = FileUtils
    fu.rm_rf ROOT
    fu.mkdir_p ROOT
    prjs.each do |pn| # create the prj_dirs
      new_dir = ROOT + "/" + pn
      fu.mkdir_p new_dir
      seeds_csv.each do |sc| # add some csvs
        File.open(new_dir + "/" + sc + ".csv", "w") do |f|
          f.puts "key, value"
          f.puts ("X, value_X_" + pn + "_" + sc + "_X").gsub(/X/, "1")
        end
      end
    end
  end
end

class TestToRedis < Test::Unit::TestCase
end

class TestMisc < Test::Unit::TestCase
  def setup
    @f         = FakeCSVS
    @prjs      = %w{prj1 prj2}
    @csv_seeds = %w{stats isize mapq_r1 mapq_r2}
    @f.doit(@csv_seeds, @prjs)
    @h = Hash.new {|h, k| h[k] = {}}
  end

  def test_it_loads_one_csvs
    csv = [@f::ROOT, @prjs[0], @csv_seeds[0] + ".csv"].join("/")
    @h  = Loading.one_csv(@h, csv)
    assert_equal 1, @h.size
  end

  def test_it_loads_csvs_from_dir
    Dir.chdir(@f::ROOT) do
      @h = Loading.all_csvs
      assert_equal 2, @h.size
      @prjs.each {|p| assert_equal 4, @h[p].size}
    end
  end
end
