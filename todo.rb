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

  def error_for_list(name)
    return "The name must between 1 and 100 characters" unless size_in_range(name)
    "The list name must be unique" if @lists.any? { |list| list[:name] == name }
  end

  def error_for_todo(name)
    "The todo name must between 1 and 100 characters" unless size_in_range(name)
  end

  def complete?(list)
    list[:todos].all? { |todo| todo[:completed] } && count_total_todos(list) > 0
  end

  def count_completed_todos(list)
    list[:todos].count { |todo| todo[:completed]}
  end

  def count_total_todos(list)
    list[:todos].count
  end

  def list_class(list)
    "complete" if complete? list
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

# home
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
  @list_id = params[:id].to_i
  @list = @lists[@list_id]
  @name = @lists[@list_id][:name]
  @todos = @lists[@list_id][:todos]
  erb :list, layout: :layout 
end

# render edit list form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  @current_list_name = @lists[@id][:name]
  erb :edit_list, layout: :layout
end

# save list
post "/lists/:id" do
  @id = params[:id].to_i
  @submitted_name = params[:list_name]
  @new_list_name = params[:list_name].strip
  @list = session[:lists][@id]
  @current_list_name = @list[:name]

  redirect "/lists/#{id}" if @current_list_name == @new_list_name 

  error = error_for_list(@new_list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = @new_list_name
    session[:success] = "The list has been updated"
    redirect "/lists/#{@id}"
  end
end

# todo mark as completed true or completed false
post "/lists/:list_id/todos/:todo_id/update" do
  @list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i

  @list = @lists[@list_id]
  @name = @list[:name]
  @todos = @list[:todos]

  is_completed = params[:completed] == "true"
  @todos[todo_id][:completed] = is_completed

  redirect "/lists/#{@list_id}"
end

# mark all todos complete/uncomplete
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = @lists[@list_id]

  @list[:todos].each { |todo| todo[:completed] = !todo[:completed] }

  session[:success] = "All todos have been updated"
  redirect "/lists/#{@list_id}"
end

# delete list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  @lists.delete_at(id)
  session[:success] = "The list was deleted"
  redirect "/lists"
end

# delete todo
post "/lists/:list_id/todos/:todo_id/destroy" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  @lists[list_id][:todos].delete_at(todo_id)
  session[:success] = "The todo was deleted"
  redirect "/lists/#{list_id}"
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list(list_name)
  if error
    session[:error] = error
    redirect "/lists/new"
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

# create new todo for a list 
post "/lists/:list_id/todos" do
  @todo = params[:todo].strip
  @list_id = params[:list_id].to_i
  
  @list = session[:lists][@list_id]
  @todos = @list[:todos]
  @name = @list[:name]
 
  error = error_for_todo(@todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
    @list[:todos] << {name: @todo, completed: false} 
    @todos = @list[:todos]
    session[:success] = "The todo has been created"
    redirect "/lists/#{@list_id}"
  end
end
