require 'dreamhost.rb' # loads rubygems on Dreamhost.

require 'vendor/sinatra/lib/sinatra.rb'
Sinatra::Base.set(:run, false)
Sinatra::Base.set(:env, :production);

require 'rack/cache'
use Rack::Cache,
    :verbose => true,
    :metastore => "file:cache/meta",
    :entitystore => "file:cache/body"

require 'groupviewer.rb'
run Sinatra::Application
