require File.dirname(__FILE__) + '/../spec_helper'

describe ActiveRecord::Base, 'with', Warren::Extensions do
  before :all do
    Bottle.connection.execute("DROP TABLE IF EXISTS #{Bottle.mirror_table_name}")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_insert_bottles_row")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_update_bottles_row")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_delete_bottles_row")
  end
  
  it "should know how to generate the migration to create a myisam mirror" do
    Bottle.create_myisam_table_migration.should == <<-EOMIGRATION
    create_table :read_only_bottles, :options => 'ENGINE MyISAM' do |t|
      t.integer\t:id
      t.string\t:type
      t.string\t:name
      t.integer\t:universe_id
    end
EOMIGRATION
  end
  
  it "should know how to generate the insert trigger sql" do
    Bottle.insert_trigger_sql.should == "CREATE TRIGGER clone_insert_bottles_row AFTER INSERT ON bottles FOR EACH ROW BEGIN INSERT INTO read_only_bottles (id, type, name, universe_id) VALUES (NEW.id, NEW.type, NEW.name, NEW.universe_id); END;"
  end
  
  it "should know how to generate the update trigger sql" do
    Bottle.update_trigger_sql.should == "CREATE TRIGGER clone_update_bottles_row AFTER UPDATE ON bottles FOR EACH ROW BEGIN UPDATE read_only_bottles SET id = NEW.id, type = NEW.type, name = NEW.name, universe_id = NEW.universe_id; END;"
  end
  
  it "should know how to generate the update trigger sql" do
    Bottle.delete_trigger_sql.should == "CREATE TRIGGER clone_delete_bottles_row AFTER DELETE ON bottles FOR EACH ROW BEGIN DELETE FROM read_only_bottles WHERE id = OLD.id; END;"
  end
  
  it "should know how to generate an entire migration for a given model" do
    expected_migration = <<-EOMIGRATION_FILE
class CreateReadOnlyBottles < ActiveRecord::Migration
  def self.up
    create_table :read_only_bottles, :options => 'ENGINE MyISAM' do |t|
      t.integer\t:id
      t.string\t:type
      t.string\t:name
      t.integer\t:universe_id
    end

    statements = <<-EOSQL
CREATE FULLTEXT INDEX fulltext_name ON read_only_bottles (name(255));
CREATE FULLTEXT INDEX fulltext_type ON read_only_bottles (type(255));
CREATE TRIGGER clone_insert_bottles_row AFTER INSERT ON bottles FOR EACH ROW BEGIN INSERT INTO read_only_bottles (id, type, name, universe_id) VALUES (NEW.id, NEW.type, NEW.name, NEW.universe_id); END;
CREATE TRIGGER clone_update_bottles_row AFTER UPDATE ON bottles FOR EACH ROW BEGIN UPDATE read_only_bottles SET id = NEW.id, type = NEW.type, name = NEW.name, universe_id = NEW.universe_id; END;
CREATE TRIGGER clone_delete_bottles_row AFTER DELETE ON bottles FOR EACH ROW BEGIN DELETE FROM read_only_bottles WHERE id = OLD.id; END;
EOSQL
    statements.split("\n").each do |statement|
      execute statement
    end
  end

  def self.down
    # Triggers for a table are also dropped if you drop the table.
    drop_table  :read_only_bottles
  end
end
EOMIGRATION_FILE
    Bottle.generate_migration(:name => 255, :type => 255).should == expected_migration
  end
  
  it "should know what the database column names for a model are" do
    Bottle.column_names.should == ["id", "type", "name", "universe_id"]
  end

  it "should know what triggers exist on its table" do
    Bottle.create_read_only_my_isam_table
    Bottle.show_triggers.should == [
      ["clone_insert_bottles_row", "INSERT", "bottles", "BEGIN INSERT INTO read_only_bottles (id, type, name, universe_id) VALUES (NEW.id, NEW.type, NEW.name, NEW.universe_id); END", "AFTER", nil, "", "root@localhost"], 
      ["clone_update_bottles_row", "UPDATE", "bottles", "BEGIN UPDATE read_only_bottles SET id = NEW.id, type = NEW.type, name = NEW.name, universe_id = NEW.universe_id; END", "AFTER", nil, "", "root@localhost"], 
      ["clone_delete_bottles_row", "DELETE", "bottles", "BEGIN DELETE FROM read_only_bottles WHERE id = OLD.id; END", "AFTER", nil, "", "root@localhost"]]
  end

  it "should know what tables exist in the database" do
    Bottle.show_db_tables.should == ["bottles", "schema_migrations"]
  end

  it "should know how to generate a mirror ISAM table" do
    Bottle.show_db_tables.should == ["bottles", "schema_migrations"]
    Bottle.show_triggers.should == []
    Bottle.create_read_only_my_isam_table
    Bottle.show_db_tables.should == ["bottles", "read_only_bottles", "schema_migrations"]
  end

  after :each do
    Bottle.connection.execute("DROP TABLE IF EXISTS #{Bottle.mirror_table_name}")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_insert_bottles_row")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_update_bottles_row")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_delete_bottles_row")
  end  
end
