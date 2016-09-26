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
    all_lists.first(lists__id: list_id)
  end

  def all_lists
    @db[:lists].left_join(:todos, list_id: :id).
      select_all(:lists).
      select_append do
        [ count(todos__id).as(todos_count),
          count(nullif(todos__completed, true)).as(todos_remaining_count) ]
      end.
      group(:lists__id).
      order(:lists__name)
  end

  def create_list(name)
    @db[:lists].insert(name: name)
  end

  def update_list_name(id, new_name)
    @db[:lists].where(lists__id: id).update(name: new_name)
  end

  def delete_list(id)
    @db[:todos].where(list_id: id).delete
    @db[:lists].where(id: id).delete
  end

  def find_todos(list_id)
    @db[:todos].where(list_id: list_id)
  end

  def create_todo(list_id, todo)
    @db[:todos]
    sql = "INSERT INTO todos (list_id, name) VALUES ($1, $2)"
    query(sql, list_id, todo)
  end

  def delete_todo(list_id, todo_id)
    sql = "DELETE FROM todos WHERE id = $1 AND list_id = $2"
    query(sql, todo_id, list_id)
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

  private

  def tuple_to_list_hash(tuple)
    { id: tuple["id"].to_i, 
      name: tuple["name"],
      todos_count: tuple["todos_count"].to_i,
      todos_remaining_count: tuple["todos_remaining_count"].to_i}
  end
end
