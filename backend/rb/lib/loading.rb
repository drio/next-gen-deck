require 'csv'
require 'find'

#
# Finds csvs in current directory and
# loads them in memory
#
module Loading
  def Loading.one_csv(h, fpath)
    dir    = File.dirname  fpath
    f_name = File.basename fpath
    levels = fpath.split('/')
    levels.delete('.'); levels.pop
    h[levels.join(">>")][f_name.gsub(/\.csv/, '')] = CSV.read fpath
    h
  end

  def Loading.all_csvs
    csvs = Hash.new {|h, k| h[k] = {}}
    Find.find(".") {|f| csvs = one_csv csvs, f if f =~ /\.csv$/ }
    csvs
  end
end
