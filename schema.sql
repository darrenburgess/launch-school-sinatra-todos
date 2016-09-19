CREATE TABLE lists (
  id SERIAL PRIMARY KEY,
  name text UNIQUE NOT NULL
);

CREATE TABLE todos (
  id SERIAL PRIMARY KEY,
  name text NOT NULL DEFAULT false,
  list_id integer REFERENCES lists(id)
);
