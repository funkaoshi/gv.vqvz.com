require File.dirname(__FILE__) + '/vendor/sinatra/lib/sinatra.rb'
require 'flickraw'
require 'haml'

# Some basic information about an image (on Flickr)
class Image
  attr_accessor :id, :img_url, :flickr_url
  
  def initialize(id, img_url, flickr_url)
    @id = id
    @img_url = img_url
    @flickr_url = flickr_url
  end
end

# Sinatra !!

configure do
  # use HTML5 when generating HTML
  set :haml, :format => :html5

  # set the last mod time to now, when the app starts up. Updated via /update/now
  @@last_mod_time = Time.now
end

before do
  unless request.path_info =~ /update/
    expires 300, :public, :must_revalidate  # always cache for 5 minutes ...
    last_modified(@@last_mod_time)          # ... and rely on 304 query after that
  end
end

helpers do
  # Loads 30 medium images from the flickr group
  def load_group(group, page)
    params[:per_page] = 30 unless page == 0
    params[:page] = page unless page == 0
    params[:group_id] = group
    begin
      photos = flickr.groups.pools.getPhotos(params)
      group_info = flickr.groups.getInfo(:group_id => group)
    rescue FlickRaw::FailedResponse => e
      halt 404
    end
    @group_id = group
    @name = group_info.name
    @page = page.to_i
    @pages = photos.pages
    @sequence = build_sequence(photos)
  end

  # build list of images.
  def build_sequence(photos)
    return [] if photos.nil?
    photos.map do |photo|
      sizes = flickr.photos.getSizes(:photo_id => photo.id)
      size = sizes.find { |s| s.label == 'Medium'}
      flickr_url = size.url[0..-9]
      Image.new(photo.id, size.source, flickr_url)
    end
  end

  def nav_links
    next_link = 
      if @page == @pages 
        "Next" 
      else      
        "<a class='next_page' href='/group/#{@group_id}?pg=#{@page+1}'>Next</a>"
      end
    prev_link = 
      case @page
      when 1
        "Prev"
      when 2
        "<a class='prev_page' href='/group/#{@group_id}'>Prev</a>"
      else
        "<a class='prev_page' href='/group/#{@group_id}?pg=#{@page-1}'>Prev</a>"
      end
    "<span class='nav'>#{prev_link} | #{@page} of #{@pages} | #{next_link}</span>"
  end
end

# Routes

get '/' do
  haml :index
end

get '/group/:group_id/?' do |group|
  page = params['pg']
  page ||= 1
  load_group(group, page)
  haml :group
end

get '/group/?' do
  redirect '/'
end

post '/group' do
  halt 404 unless params['url'] =~ /http:\/\/(?:www.)?flickr.com\/groups\/([\w@]*)\/?/
  begin
    group = flickr.urls.lookupGroup(:url => params['url'])
  rescue FlickRaw::FailedResponse => e
    halt 404
  end
  redirect "/group/#{group.id}"
end

# Lame web-cache thing which I don't think really works.

get '/update/now' do
  @@last_mod_time = Time.now
end

get '/update/show' do
  "Last-Update: #{@@last_mod_time}"
end

# Error Handlers in Production

not_found do
  haml :wtf
end

error do
  haml :wtf
end
