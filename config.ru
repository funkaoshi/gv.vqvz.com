ENV['GEM_HOME'] = '/home/ramanan/local/gems'
ENV['GEM_PATH'] = '$GEM_HOME:/usr/lib/ruby/gems/1.8'  
require 'rubygems'
Gem.clear_paths

require 'rack/cache'
require 'vendor/sinatra/lib/sinatra.rb'

Sinatra::Base.set(:run, false)
Sinatra::Base.set(:env, :production);

use Rack::Cache,
    :verbose => true,
    :metastore => "file:cache/meta",
    :entitystore => "file:cache/body"

require 'groupviewer.rb'
run Sinatra::Application
