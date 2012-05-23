require 'simplecov'
SimpleCov.start
#require 'autotest'
require 'test/unit'
require 'toredis'

require 'fakecsvs'
require 'monkey_patch'
require 'mock_redis'

class TestToRedis < Test::Unit::TestCase
  def setup
    @r         = Redis.new
    @f         = FakeCSVS
    @prjs      = {
                   "prj1" => [ "bam11", "bam12" ],
                   "prj2" => [ "bam21", "bam22" ]
                 }
    @csv_seeds = %w{stats isize.dist r1.mapq.dist r2.mapq.dist}
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
    @tr.each {|dir, csv_type, row| assert @prjs.include? dir}
  end

  must "properly iterate and yield the types" do
    @tr.each {|dir, csv_type, row| assert @csv_seeds.include? csv_type}
  end

  must "It should not yield the csv headers" do
    @tr.each {|dir, csv_type, row| assert_no_match /^key/, row[0]}
  end

  must "correctly sets a NON_SPECIAL key/pair when working on stats for a bam" do
    p = "prj1"; t = "stats"; r = ["n_reads", 100]
    @tr.process_row p, t, r
    assert @tr.stats[p][r[0]] == r[1]

    p = "prj1"; t = "mapq.r1"; r = ["255", 10]
    @tr.process_row p, t, r; assert @tr.dists[t][r[0]] == r[1]
    t = "mapq.r2"
    @tr.process_row p, t, r; assert @tr.dists[t][r[0]] == r[1]

    t = "isize"
    @tr.process_row p, t, r; assert @tr.dists[t][r[0]] == r[1]
  end

  must "correct through an exception when it doesn't understand the type" do
    p = "prj1"; t = "XXXXXX"; r = ["255", 10]
    assert_raises(RuntimeError) { @tr.process_row p, t, r }
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
end

