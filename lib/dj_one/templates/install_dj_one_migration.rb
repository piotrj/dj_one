superclass = if ActiveRecord.version >= Gem::Version.new(5)
               ActiveRecord::Migration[5.0]
             else
               ActiveRecord::Migration
             end


class InstallDjOne < superclass
  def self.up
    add_column :delayed_jobs, :unique_id, :string
    add_index :delayed_jobs, [:unique_id], name: :unique_delayed_jobs, unique: true
  end

  def self.down
    remove_column :delayed_jobs, :unique_id
    remove_index :delayed_jobs, name: :unique_delayed_jobs
  end
end
