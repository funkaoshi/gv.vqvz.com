require 'sinatra'
require 'flickraw'
require 'haml'

# Models and the like 

class String
  def is_untitled?
    return self.empty? || self == '.' || self =~ /IMG_/ || self =~ /DSC_/
  end
end

# Some basic information about an image (on Flickr)
class Image
  attr_accessor :id, :img_url, :flickr_url, :title, :photographer

  def initialize(photo)
    @id, @img_url, @flickr_url = photo.id, FlickRaw::url(photo), FlickRaw::url_photopage(photo)
    @photographer = "<a href='#{FlickRaw::url_photostream(photo)}'>#{photo.ownername}</a>"
    @title = photo.title.is_untitled? ? 'untitled' : photo.title
  end
end

# All the information about a page of images that need to be displayed
class ImageListing
  attr_accessor :flickr_id, :title, :page, :pages, :sequence
  
  def initialize(id, title, page, pages, sequence)
    @flickr_id, @title, @page, @pages, @sequence = id, title, page, pages, sequence
  end
end


# Sinatra !!

configure do
  # Set API Key
  FlickRaw.api_key = 'd14c1db0be6b1519a09274054a8be802'

  # use HTML5 when generating HTML
  set :haml, :format => :html5

  # set the last mod time to now, when the app starts up. Updated via /update/now
  @last_mod_time = Time.now

  ## for google analytics
  @analytics_token = 'UA-2675737-8'
end

before do
  unless request.path_info =~ /update/
    expires 300, :public, :must_revalidate  # always cache for 5 minutes ...
    last_modified(@last_mod_time)          # ... and rely on 304 query after that
  end
end

helpers do  
  def set_paging(params, page)
    params[:per_page] = 30 unless page == 0
    params[:page] = page unless page == 0
  end
  
  # Loads 30 medium images from the flickr group
  def load_group(group, page)
    params = { :group_id => group, :extras => 'path_alias, owner_name' }
    set_paging(params, page)
    begin
      photos = flickr.groups.pools.getPhotos(params)
      group_info = flickr.groups.getInfo(:group_id => group)
    rescue FlickRaw::FailedResponse => e
      halt 404
    end
    @list = ImageListing.new(group, group_info.name, page.to_i, photos.pages, build_sequence(photos))
    @mode = "group"
  end

  # Loads 30 medium images from a flickr user
  def load_favs(user_name, page)
    user_id = flickr.people.findByUsername(:username => user_name).id
    params = { :user_id => user_id, :extras => 'path_alias, owner_name' }
    set_paging(params, page)
    begin
      photos = flickr.favorites.getPublicList(params)
    rescue FlickRaw::FailedResponse => e
      halt 404
    end
    @list = ImageListing.new(user_name, "#{user_name}'s Favourites", page.to_i, photos.pages, build_sequence(photos))
    @mode = "favs"
  end

  # build list of images.
  def build_sequence(photos)
    return [] if photos.nil?
    photos.map do |photo|
      Image.new(photo)
    end
  end

  def nav_links
    next_link =
      if @list.page == @list.pages
        "Next"
      else
        "<a class='next_page' href='/#{@mode}/#{@list.flickr_id}?pg=#{@list.page+1}'>Next</a>"
      end
    prev_link =
      case @list.page
      when 1
        "Prev"
      when 2
        "<a class='prev_page' href='/#{@mode}/#{@list.flickr_id}'>Prev</a>"
      else
        "<a class='prev_page' href='/#{@mode}/#{@list.flickr_id}?pg=#{@list.page-1}'>Prev</a>"
      end
    "#{prev_link} | #{@list.page} of #{@list.pages} | #{next_link}"
  end
end

# Routes

get '/' do
  haml :index
end

get '/favs/:user_id' do |user_name|
  page = params['pg']
  page ||= 1
  load_favs(user_name, page)
  haml :group
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
  @last_mod_time = Time.now
end

get '/update/show' do
  "Last-Update: #{@last_mod_time}"
end

# Error Handlers in Production

not_found do
  haml :wtf
end

error do
  haml :wtf
end
