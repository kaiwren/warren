# Copyright 2009 Sidu Ponnappa

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

module Warren
  module Extensions
    def self.included(klass)
      klass.extend ClassMethods
      klass.class_eval{ include InstanceMethods }
    end
    
    module ClassMethods
      def enable_fulltext_search
        Kernel.const_set("ReadOnly#{self.name.demodulize}", Class.new(ActiveRecord::Base))
      end

      def create_read_only_my_isam_table
        mig = generate_migration(:name => 255, :type => 255)
        puts mig
        Object.class_eval mig, __FILE__, __LINE__
        migration_name.constantize.migrate(:up)
      end
      
      # fulltext_columns is a hash containing the indexable column names
      # as keys and lengths as the values, and this controls
      # the generation of CREATE FULLTEXT INDEX sql statements.
      #
      # For example, invoking Bottle.generate_migration with {:name => 255}
      # (where Bottle is an arbitrary ActiveRecord mapped to table bottles)
      # would generate
      #  CREATE FULLTEXT INDEX fulltext_name ON read_only_bottles (name(255));
      def generate_migration(fulltext_columns)
        columns = fulltext_columns.stringify_keys
        <<-EOMIGRATION
class #{migration_name} < ActiveRecord::Migration
  def self.up
#{create_myisam_table_migration}
    statements = <<-EOSQL
#{columns.keys.sort.map{|column_name| "CREATE FULLTEXT INDEX fulltext_#{column_name} ON #{mirror_table_name} (#{column_name}(#{columns[column_name]}));" }.join("\n")}
#{insert_trigger_sql}
#{update_trigger_sql}
#{delete_trigger_sql}
EOSQL
    statements.split("\n").each do |statement|
      execute statement
    end
  end

  def self.down
    # Triggers for a table are also dropped if you drop the table.
    drop_table  :#{mirror_table_name}
  end
end
EOMIGRATION
      end
      
      def migration_name
        "Create#{mirror_table_name.camelize}"
      end
      
      def create_myisam_table_migration
        <<-EOMIGRATION
    create_table :#{mirror_table_name}, :options => 'ENGINE MyISAM' do |t|
      #{columns.map{|c| "t.#{c.type}\t:#{c.name}"}.join("\n      ")}
    end
EOMIGRATION
      end
      
      def insert_trigger_sql
        "CREATE TRIGGER clone_insert_#{table_name}_row AFTER INSERT ON #{table_name} FOR EACH ROW BEGIN INSERT INTO #{mirror_table_name} (#{column_names.join(', ')}) VALUES (#{column_names.map{|name| 'NEW.' + name }.join(', ')}); END;"
      end
      
      def update_trigger_sql
        "CREATE TRIGGER clone_update_#{table_name}_row AFTER UPDATE ON #{table_name} FOR EACH ROW BEGIN UPDATE #{mirror_table_name} SET #{column_names.map{|name| name + ' = ' + 'NEW.' + name }.join(', ')}; END;"
      end
      
      def delete_trigger_sql
        "CREATE TRIGGER clone_delete_#{table_name}_row AFTER DELETE ON #{table_name} FOR EACH ROW BEGIN DELETE FROM #{mirror_table_name} WHERE #{primary_key} = OLD.#{primary_key}; END;"
      end
      
      def mirror_table_name
        "read_only_#{self.table_name}"
      end
      
      def column_names
        self.columns.map(&:name)
      end
      
      def show_db_tables
        returning(self.connection.execute('show tables')){|result| result.extend(Enumerable)}.map.flatten
      end
      
      # Accepts a set of search options as a hash. The options are:
      # :query    => String # The search query. No default value.
      # :column   => String # A comma separated string containing the names of the database columns to search. No default value.
      # :mode     => String # Fulltext search mode. Defaults to Warren::Modes::Boolean
      def full_text_search(search = {})
        search = search.clone
        search[:mode] ||= Warren::Modes::Boolean
        primary_key = self.primary_key

        returning([]) do |instances|
          query = "SELECT * FROM #{ReadOnlyBottle.table_name} WHERE MATCH (#{search[:column]}) AGAINST ('#{search[:query]}' #{search[:mode]})"
          self.connection.execute(query).each_hash do |data|
            instance = self.new(data)
            instance.send("#{primary_key}=", data[primary_key])
            instances << instance
          end
        end
      end
    end

    module InstanceMethods
    end
  end
end
