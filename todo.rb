require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# show all lists
get "/lists" do
  @lists = session[:lists]
  erb :lists
end

# render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# create new list
post "/lists" do
  session[:lists] << {name: params[:list_name], todos: []}
  redirect "/lists"
end
