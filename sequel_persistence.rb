require "sequel"

DB = Sequel.connect("postgres://localhost/todos")

class SequelPersistence
  def initialize(logger)
    DB.logger = logger
  end

  def find_list(list_id)
    all_lists.first(lists__id: list_id)
  end

  def all_lists
    DB[:lists].left_join(:todos, list_id: :id).
      select_all(:lists).
      select_append do
        [ count(todos__id).as(todos_count),
          count(nullif(todos__completed, true)).as(todos_remaining_count) ]
      end.
      group(:lists__id).
      order(:lists__name)
  end

  def create_list(name)
    DB[:lists].insert(name: name)
  end

  def update_list_name(id, new_name)
    DB[:lists].where(lists__id: id).update(name: new_name)
  end

  def delete_list(id)
    DB[:todos].where(list_id: id).delete
    DB[:lists].where(id: id).delete
  end

  def todos
    DB[:todos]
  end

  def find_todos(list_id)
    todos.where(list_id: list_id)
  end

  def create_todo(list_id, todo)
    todos.insert(list_id: list_id, name: todo)
  end

  def delete_todo(list_id, todo_id)
    todos.where(list_id: list_id, id: todo_id).delete
  end

  def change_todo_status(list_id, todo_id)
    status = todos.where(list_id: list_id, id: todo_id).to_a.first[:completed]
    todos.where(list_id: list_id, id: todo_id).update(completed: !status)
  end

  def complete_all_todos(list_id)
    todos.where(list_id: list_id).update(completed: true)
  end
end
