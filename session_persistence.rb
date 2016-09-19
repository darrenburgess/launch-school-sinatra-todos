class SessionPersistence
  def initialize(session)
    @session = session
    @session[:lists] ||= []
    @lists = @session[:lists]
  end

  def find_list(id)
    @session[:lists].select { |list| list[:id] == id }.first if id
  end

  def all_lists
    @session[:lists]
  end

  def create_list(name)
    id = next_id(all_lists)
    all_lists << { id: id, name: name, todos: [] }
  end

  def update_list_name(id, new_name)
    list = find_list(id)
    list[:name] = new_name
  end

  def change_todo_status(list_id, todo_id)
    list = find_list(list_id)
    todo = list[:todos].find { |t| t[:id] == todo_id }
    todo[:completed] = todo[:completed] == true ? false : true
  end

  def complete_all_todos(list_id)
    list = find_list(list_id)
    list[:todos].each { |todo| todo[:completed] = true }
  end

  def delete_list(id)
    @lists.reject! { |list| list[:id] == id }
  end

  def create_todo(list_id, todo)
    list = find_list(list_id)
    id = next_id(list[:todos])
    list[:todos] << { id: id, name: todo, completed: false} 
  end

  def delete_todo(list_id, todo_id)
    list = find_list(list_id)
    list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  private

  def next_id(items)
    items.map { |item| item[:id] }.max.to_i + 1
  end
end

