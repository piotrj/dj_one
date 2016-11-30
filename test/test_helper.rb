$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'dj_one'

require "yaml"
require "sqlite3"

require 'minitest/autorun'


def connect_active_record
  adapter = "sqlite"
  config_file = File.expand_path("config/database.yml", File.dirname(__FILE__))

  puts "DB: #{adapter}"
  puts "Config file: #{config_file}"

  config = YAML.load_file(config_file)[adapter]
  puts config.inspect

  ActiveRecord::Base.logger = ActiveSupport::Logger.new("debug.log", 0, 100 * 1024 * 1024)
  ActiveRecord::Base.establish_connection config
end

def load_db_schema
  ActiveRecord::Schema.define do
    create_table :delayed_jobs, force: true do |table|
      table.integer :priority, default: 0, null: false
      table.integer :attempts, default: 0, null: false
      table.text :handler,                 null: false
      table.text :last_error
      table.datetime :run_at
      table.datetime :locked_at
      table.datetime :failed_at
      table.string :locked_by
      table.string :queue
      table.timestamps null: true
    end

    add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"
  end
end

connect_active_record
load_db_schema
