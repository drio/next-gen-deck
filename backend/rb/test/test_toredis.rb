require 'simplecov'
SimpleCov.start
#require 'autotest'
require 'test/unit'
require 'toredis'

require 'fakecsvs'
require 'monkey_patch'
require 'mock_redis'

require 'simu_data'
require 'test_simu_data'

class TestToRedis < Test::Unit::TestCase
  def setup
    @r         = MockRedis.new
    @f         = FakeCSVS
    @prjs      = [ "prj1/bam11", "prj1/bam12", "prj2/bam21", "prj2/bam22" ]
    @csv_seeds = %w{stats isize.dist r1.mapq.dist r2.mapq.dist header xcov.dist}
    @f.doit(@csv_seeds, @prjs)
    @h  = Hash.new {|h, k| h[k] = {}}
    @tr = ToRedis.new(@r)
    Dir.chdir(@f::ROOT)
  end

  must "properly generate the id from the full path to the csv file" do
    id, type = @tr.to_id("/prj/sub_prj/sample/isize.csv")
    assert_equal "prj>>sub_prj>>sample", id
    assert_equal "isize", type
  end

  must "properly iterate and yield the directory id" do
    @tr.each {|dir, csv_type, row| assert @prjs.include? dir.gsub(/>>/, "/")}
  end

  must "properly iterate and yield the types" do
    @tr.each {|dir, csv_type, row| assert @csv_seeds.include? csv_type}
  end

  must "It should not yield the csv headers" do
    @tr.each {|dir, csv_type, row| assert_no_match /^key/, row[0] }
  end

  must "correctly sets a NON_SPECIAL key/pair when working on stats for a bam" do
    p = "prj1"; t = "stats"; r = ["n_reads", 100]
    @tr.process_row p, t, r
    assert @tr.stats[p][r[0]] == r[1]

    p = "prj1"; t = "r1.mapq.dist"; r = ["255", 10]
    @tr.process_row p, t, r; assert @tr.dists[t][r[0]] == r[1]

    t = "r2.mapq.dist"
    @tr.process_row p, t, r; assert @tr.dists[t][r[0]] == r[1]

    t = "isize.dist"
    @tr.process_row p, t, r; assert @tr.dists[t][r[0]] == r[1]
  end

  must "correct through an exception when it doesn't understand the type" do
    p = "prj1"; t = "XXXXXX"; r = ["255", 10]
    assert_raises(RuntimeError) { @tr.process_row p, t, r }
  end

  must "we do not use the name of the file when accessing the dist hash" do
    p = "prj1"; t = "something.bla.isize.dist"; r = ["n_reads", 100]
    @tr.process_row p, t, r
    assert @tr.dists["isize.dist"][r[0]] == r[1]
  end

  must "correctly calculate percentages" do
    assert @tr.per(100,10) == 10
  end

  must "sets percentages correctly in stats" do
    p = "prj1"; t = "stats"; r = ["n_reads", 100]
    @tr.process_row p, t, r
    assert @tr.stats[p][r[0]] == r[1]

    r = ["n_duplicate_reads", 10]
    @tr.process_row p, t, r
    assert @tr.stats[p]["per_dups"] == r[1]

    r = ["n_reads_mapped", 20]
    @tr.process_row p, t, r
    assert @tr.stats[p]["per_mapped"] == r[1]
  end

  must "when processing the whole dir, it sets the stats key in redis" do
    @tr.run
    assert_not_nil @tr.redis["stats"]
  end

  must "set in redis the distributions per each bam" do
    @tr.run
    @prjs.each do |dir|
      id = dir.gsub(/\//, ">>")
      %w{is- mq-r1- mq-r2- xcov-}.each do |seed|
        h = @tr.redis[seed + id]
        assert_not_nil h
        assert h.has_key? "type"
        assert h.has_key? "data"
        # We trim out bins for very high insert size values
        assert h["data"].size == 2
        # let's make sue the values are numbers not strings
        h["data"].values.each {|v| assert v.class == Fixnum}
      end
    end
  end

  must "the values for the _STATS_ key are correctly set in redis" do
    @tr.run
    @prjs.each do |dir|
      h = @tr.redis["stats"][dir.gsub(/\//, ">>")]
      assert_not_nil h

      assert h["n_reads"]           == "10"
      assert h["n_duplicate_reads"] == "1"
      assert h["per_dups"].to_i     == 10
      assert h["n_reads_mapped"]    == "8"
      assert h["per_mapped"].to_i   == 80
    end
  end
end

