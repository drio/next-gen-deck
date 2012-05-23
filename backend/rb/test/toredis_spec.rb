require 'simplecov'
SimpleCov.start

require 'autotest'
require 'rspec'

require 'fileutils'

require 'toredis'
require 'fakecsvs'

describe ToRedis do
  describe 'iterating over data' do
    before :each do
      @f         = FakeCSVS
      @prjs      = %w{prj1 prj2}
      @csv_seeds = %w{stats isize mapq_r1 mapq_r2}
      @f.doit(@csv_seeds, @prjs)
      @h = Hash.new {|h, k| h[k] = {}}
    end

    it 'should yield the csv line, dir/id and the type of csv' do
      Dir.chdir(@f::ROOT) do
        ToRedis.new.each do |dir, csv_type, row|
          assert @prjs.include? dir
          assert @csv_seeds.include? csv_type
          assert_no_match /^key/, row[0] # we skip the header
        end
      end
    end

  end
end


