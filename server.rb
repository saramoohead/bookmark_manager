require 'sinatra/base'
require 'data_mapper'
require './lib/tag'
require './lib/user'
require './lib/link'

env = ENV['RACK_ENV'] || 'development'

DataMapper.setup(:default, "postgres://localhost/bookmark_manager_#{env}")

require './lib/link'

DataMapper.finalize
DataMapper.auto_upgrade!

class BookmarkManager < Sinatra::Base

  enable :sessions
  set :session_secret, 'super secret'

  get '/' do
    @links = Link.all
    erb :homepage
  end

  post '/links' do
    url = params['url']
    title = params['title']
    tags = params['tags'].split(' ').map do |tag|
      Tag.first_or_create(text: tag)
    end
    Link.create(url: url, title: title, tags: tags)
    redirect to('/')
  end

  get '/tags/:text' do
    tag = Tag.first(text: params[:text])
    @links = tag ? tag.links : []
    erb :homepage
  end

  get '/users/new' do
    erb :'users/new'
  end

  get '/users' do
    User.create(email: params[:email], password: params[:password])
    redirect to('/')
  end

  post '/users' do
    user = User.create(email: params[:email], 
                       password: params[:password],
                       password_confirmation: params[:password_confirmation])
    session[:user_id] = user.id
    redirect to('/')
  end

  helpers do
    def current_user
      @current_user ||= User.get(session[:user_id]) if session[:user_id]
    end
  end

  # start the server if ruby file executed directly
  run! if app_file == BookmarkManager

end
