module Nodus
  module Version
    VFILE   = File.join(File.dirname(__FILE__),'..','VERSION')
    VERSION = File.exist?(VFILE) ? File.read(VFILE).strip : `git -C '#{File.dirname(__FILE__)}' describe --tags`.strip
  end
end
