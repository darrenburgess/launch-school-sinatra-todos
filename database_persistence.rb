require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "todos")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end


  def find_list(list_id)
    sql = "SELECT * FROM lists WHERE id = $1"
    list_result = query(sql, list_id)

    tuple = list_result.first

    todos = find_todos(list_id)
    {id: tuple["id"], name: tuple["name"], todos: todos}
  end

  def all_lists
    list_sql = "SELECT * FROM lists"

    lists_result = query(list_sql)

    lists_result.map do |tuple|
      list_id = tuple["id"].to_i
      todos = find_todos(list_id)
      {id: list_id, name: tuple["name"], todos: todos}
    end
  end

  def create_list(name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, name)
  end

  def update_list_name(id, new_name)
    #list = find_list(id)
    #list[:name] = new_name
  end

  def change_todo_status(list_id, todo_id)
    #list = find_list(list_id)
    #todo = list[:todos].find { |t| t[:id] == todo_id }
    #todo[:completed] = todo[:completed] == true ? false : true
  end

  def complete_all_todos(list_id)
    #list = find_list(list_id)
    #list[:todos].each { |todo| todo[:completed] = true }
  end

  def delete_list(id)
    #@lists.reject! { |list| list[:id] == id }
  end

  def create_todo(list_id, todo)
    #list = find_list(list_id)
    #id = next_id(list[:todos])
    #list[:todos] << { id: id, name: todo, completed: false} 
  end

  def delete_todo(list_id, todo_id)
    #list = find_list(list_id)
    #list[:todos].reject! { |todo| todo[:id] == todo_id }
  end

  private

  def find_todos(list_id)
    todos_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todos_sql, list_id)

    todos_result.map do |todo_tuple|
      {id: todo_tuple["id"].to_i,
       name: todo_tuple["name"],
       completed: todo_tuple["completed"] == "t"}
    end
  end
end
