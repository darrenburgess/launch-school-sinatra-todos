require "sequel"

class SequelPersistence
  def initialize(logger)
    @db = Sequel.connect("postgres://localhost/todos")
    @db.loggers << logger
  end

  def query(statement, *params)
    @logger.info "#{statement}: #{params}"
    @db.exec_params(statement, params)
  end

  def find_list(list_id)
    sql = "SELECT * FROM lists WHERE id = $1"
    sql = <<SQL
            SELECT lists.*,
            COUNT(NULLIF(todos.completed, true)) AS todos_remaining_count,
            COUNT(todos.id) AS todos_count
            FROM lists
            LEFT JOIN todos ON todos.list_id = lists.id
            WHERE lists.id = $1
            GROUP BY lists.id
SQL

    list_result = query(sql, list_id)

    tuple_to_list_hash(list_result.first)
  end

  def all_lists
    @db[:lists].left_join(:todos, list_id: :id).
      select_all(:lists).
      select_append do
        [ count(todos__id).as(todos_count),
          count(nullif(todos__completed, true)).as(todos_remaining_count) ]
      end.
      group(:lists__id).
      order(:lists__name).to_a
  end

  def create_list(name)
    sql = "INSERT INTO lists (name) VALUES ($1)"
    query(sql, name)
  end

  def update_list_name(id, new_name)
    sql = "UPDATE lists SET name = $1 WHERE id = $2"
    query(sql, new_name, id)
  end

  def change_todo_status(list_id, todo_id)
    find_sql = "SELECT completed FROM todos WHERE id = $1 AND list_id = $2"
    completed = query(find_sql, todo_id, list_id).values.first.first == "f" 
    update_sql = "UPDATE todos SET completed = $1 WHERE id = $2 AND list_id = $3"
    query(update_sql, completed, todo_id, list_id)
  end

  def complete_all_todos(list_id)
    sql = "UPDATE todos SET completed = true WHERE list_id = $1"
    query(sql, list_id)
  end

  def delete_list(id)
    todos_sql = "DELETE from todos WHERE list_id = $1"
    query(todos_sql, id)
    list_sql = "DELETE FROM lists WHERE id = $1"
    query(list_sql, id)
  end

  def create_todo(list_id, todo)
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
    query(sql, list_id, todo)
  end

  def delete_todo(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
  end

  def find_todos(list_id)
    todos_sql = "SELECT * FROM todos WHERE list_id = $1"
    todos_result = query(todos_sql, list_id)

    todos_result.map do |todo_tuple|
      {id: todo_tuple["id"].to_i,
       name: todo_tuple["name"],
       completed: todo_tuple["completed"] == "t"}
    end
  end

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      name: tuple["name"],
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i}
  end
end
