module Helpers
  # Dirty usage for CLI tools
  module Usage
    @usage_text = ""

    def self.set_text(ut)
      @usage_text = ut
    end

    def self.error(msg)
      $stderr.puts "ERROR: #{msg}"
      usage
      exit 1
    end

    def self.usage
      $stderr.puts @usage_text
    end
  end

  # Make sure the following tools (bins) are available in the system
  # bins   : bins to inspect
  # bins is a hash were the key is the name of the tool
  # and the value the actual binary name
  # output : -
  def Helpers.tools_available(bins)
    bins_not_found = []
    bins.each do |name, bin|
      found = false
      ENV['PATH'].split(':').each do |dir|
        found = found || File.exists?(dir + '/' + bin)
        break if found
      end
      bins_not_found << name if !found
    end

    unless bins_not_found.size == 0
      bins_not_found.each do |name, bin|
        $stderr.puts "bin not found: #{name} (#{bins[name]})"
      end
      Helpers::Usage.error "binaries not found. Bailing out"
    end
  end

end
