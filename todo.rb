require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

get "/" do
  redirect "/lists"
end

# show all lists
get "/lists" do
  erb :lists
end

# render new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip
  lists = []
  @lists.each {|list| lists << list[:name].to_s }
  if lists.include? list_name 
    session[:error] = "List names must be unique"
    redirect "/lists/new"
  elsif (1..100).cover? list_name.size
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  else
    session[:error] = "List name must be between 1 and 100 characters"
    redirect "/lists/new"
  end
end
