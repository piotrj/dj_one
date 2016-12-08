require "rails/generators"
require "rails/generators/active_record"

module DelayedJob
  class AddDjOne < Rails::Generators::Base
    include ActiveRecord::Generators::Migration
    source_root File.expand_path("../templates", __FILE__)

    def add_migration
      migration_template "install_dj_one_migration.rb", "db/migrate/install_dj_one.rb"
    end
  end
end
