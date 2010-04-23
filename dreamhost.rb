# Used to get Rubygems running properly on Dreamhost.
ENV['GEM_HOME'] = '/home/ramanan/local/gems'
ENV['GEM_PATH'] = '$GEM_HOME:/usr/lib/ruby/gems/1.8'
require 'rubygems'
Gem.clear_paths
