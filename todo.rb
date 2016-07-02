require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt/erubis"
require "pry"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def size_in_range(name)
    (1..100).cover? name.size
  end

  # return error message if name is invalid, nil if valid
  def error_for_list_name(name)
    return "The name must between 1 and 100 characters" unless size_in_range(name)
    "The list name must be unique" if @lists.any? { |list| list[:name] == name }
  end

  def error_for_todo_name(name)
    return "The todo name must between 1 and 100 characters" unless size_in_range(name)
    "The todo name must be unique" if @list[:todos].any? { |todo| todo[:name] == name }
  end
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

# show one list
get "/lists/:id" do
  @id = params[:id].to_i
  @name = @lists[@id][:name]
  @todos = @lists[@id][:todos]
  erb :list
end

# render edit list form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @current_list_name = @lists[@id][:name]
  erb :edit_list, layout: :layout
end

# save list
post "/lists/:id" do
  id = params[:id].to_i
  @submitted_name = params[:list_name]
  @new_list_name = params[:list_name].strip
  @list = session[:lists][id]
  @current_list_name = @list[:name]

  redirect "/lists/#{id}" if @current_list_name == @new_list_name 

  error = error_for_list_name(@new_list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = @new_list_name
    session[:success] = "The list has been updated"
    redirect "/lists/#{id}"
  end
end

post "/lists/:id/destroy" do
  id = params[:id].to_i
  @lists.delete_at(id)
  session[:success] = "The list was deleted"
  redirect "/lists"
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    redirect "/lists/new"
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

# create new todo to a list 
post "/lists/:list_id/todos" do
  @todo = params[:todo].strip
  list_id = params[:list_id].to_i
  
  @list = session[:lists][list_id]
  @todos = @list[:todos]
 
  error = error_for_todo_name(@todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: @todo, completed: false} 
    @todos = @list[:todos]
    session[:success] = "The todo has been created"
    redirect "/lists/#{list_id}"
  end
end
