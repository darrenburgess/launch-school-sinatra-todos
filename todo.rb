require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"
require "pry" if development?

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
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
    count_remaining_todos(list) == 0 && count_total_todos(list) > 0
  end

  def count_remaining_todos(list)
    list[:todos].count { |todo| !todo[:completed]}
  end

  def count_total_todos(list)
    list[:todos].count
  end

  def list_class(list)
    "complete" if complete? list
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| complete?(list) }

    all_lists = incomplete_lists + complete_lists
    all_lists.each { |list| yield list, lists.index(list) }
  end

  def sort_todos(todos, &block)
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }
    
    all_todos = incomplete_todos + complete_todos
    all_todos.each { |todo| yield todo, todos.index(todo) }
  end
end

before do
  session[:lists] ||= []
  @lists = session[:lists]
end

def load_list(id)
  list = @lists.select { |list| list[:id] == id }.first if id
  return list if list

  session[:error] = "The specified list was not found"
  redirect "/lists"
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
  @list = load_list(@list_id)

  @name = @list[:name]
  @todos = @list[:todos]

  erb :list, layout: :layout
end

# render edit list form
get "/lists/:id/edit" do
  @id = params[:id].to_i
  list = load_list(@id)

  @current_list_name = list[:name]
  erb :edit_list, layout: :layout
end

# save list
post "/lists/:id" do
  @id = params[:id].to_i
  @list = load_list(@id)

  @submitted_name = params[:list_name]
  @new_list_name = params[:list_name].strip
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

  @list = load_list(@list_id)
  @name = @list[:name]
  @todos = @list[:todos]

  is_completed = params[:completed] == "true"
  todo = @todos.find { |todo| todo[:id] == todo_id }
  todo[:completed] = is_completed

  redirect "/lists/#{@list_id}"
end

# mark all todos complete/uncomplete
post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = load_list(@list_id)

  @list[:todos].each { |todo| todo[:completed] = !todo[:completed] }

  session[:success] = "All todos have been updated"
  redirect "/lists/#{@list_id}"
end

# delete list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  @list = load_list(id)
  @lists.reject! { |list| list[:id] == id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "The list was deleted"
    redirect "/lists"
  end
end

# delete todo
post "/lists/:list_id/todos/:todo_id/destroy" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i

  @list = load_list(list_id)
  @list[:todos].reject! { |todo| todo[:id] == todo_id }

  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "The todo was deleted"
    redirect "/lists/#{list_id}"
  end
end

# derive next id for list of items
def next_id(items)
  items.map { |item| item[:id] }.max.to_i + 1
end

# create new list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list(list_name)
  if error
    session[:error] = error
    redirect "/lists/new"
  else
    id = next_id(@lists)
    session[:lists] << { id: id, name: list_name, todos: [] }
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

# create new todo for a list 
post "/lists/:list_id/todos" do
  @todo = params[:todo].strip
  @list_id = params[:list_id].to_i

  @list = load_list(@list_id)
  @todos = @list[:todos]
  @name = @list[:name]

  error = error_for_todo(@todo)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else

    id = next_id(@todos)

    @list[:todos] << { id: id, name: @todo, completed: false} 
    @todos = @list[:todos]
    session[:success] = "The todo has been created"
    redirect "/lists/#{@list_id}"
  end
end
