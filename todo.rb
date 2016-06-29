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

def error_for_list_name(list_name)
  return "The list name must between 1 and 100 characters" unless (1..100).cover? list_name.size
  "The list name must be unique" if @lists.any? { |list| list[:name] == list_name }
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  if error = error_for_list_name(list_name)
    session[:error] = error
    redirect "/lists/new"
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end
