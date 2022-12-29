require "minitest/test_task"
require_relative "./lib/storage"

Minitest::TestTask.create

task :default => :test

namespace "storage" do
  task :create_table do
    Storage.new.create_table
  end

  task :drop_table do
    Storage.new.drop_table
  end

  task :clear_table do
    Storage.new.clear_table
  end
end
