require "pg"
require "yaml"

class Storage

  class ExistsError < StandardError; end

  def initialize
    @options = YAML.load File.open(config_path)
  end

  def save(number, key)
    raise ExistsError if exists? key
    connection.exec_params("INSERT INTO numbers (number, key) VALUES ($1, $2);", [number, key])
  end

  def sum
    connection.exec("SELECT sum(number) FROM numbers;").values.first.first.to_i
  end

  def clear_table
    connection.exec("DELETE FROM numbers;")
  end

  def create_table
    connection.exec("CREATE TABLE numbers (id SERIAL PRIMARY KEY, number INT, key VARCHAR(20));")
  end

  def drop_table
    connection.exec("DROP TABLE numbers;")
  end

  private

  def connection
    PG.connect(@options)
  end

  def exists?(key)
    connection.exec_params("SELECT * FROM numbers WHERE key=$1", [key]).values.size > 0
  end


  def config_path
    "./config/database.yml"
  end

end