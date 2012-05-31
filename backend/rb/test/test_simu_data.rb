class TestSimuData < Test::Unit::TestCase
  def setup
    n_of_bams              = 10
    n_of_pairs_to_generate = 100000
    @simu     = SimuData.new 10, "dummy.bam", n_of_pairs_to_generate
    @PRJS     = SimuData::PRJS_NAMES
    @SUB_PRJS = SimuData::SUB_PRJS
  end

  must "give me correctly a random project" do
    prj = @simu.rand_prj
    assert prj.class == String
    assert @PRJS.include? prj
  end

  must "give me correctly a sub project" do
    sp = @simu.rand_sub_prj
    assert sp.class == String
    assert @SUB_PRJS.include? sp
  end

  must "give mem a random sample id" do
    assert @simu.rand_sample_id.class == String
  end

  must "give me a dir path to a simulated bam and the filename" do
    dir, fn    = @simu.path
    back_slash = /\//
    assert dir.scan(back_slash).size == 2
    assert dir.size > 0
    assert fn.scan(back_slash).size == 0
    assert fn.size > 0
  end

  must "generate a non negative number to skip" do
    (1..100).each { assert @simu.n_to_skip.to_i >=0 }
  end

  must "give me a list of cmds to generate the random bams" do
    cmds = @simu.generate
    assert cmds.size == @simu.n_bams
  end

  must "I can run the bam generation in the background" do
    simu = SimuData.new 2, "xxx.bam", 10000, true
    simu.generate.each {|c| assert c =~ /&$/}
  end
end

