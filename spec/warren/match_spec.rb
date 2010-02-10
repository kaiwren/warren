require File.dirname(__FILE__) + '/../spec_helper'

describe Warren::Match do
  before :all do
    # Note that you'd only use this in specs.
    # In the normal course, you'd use ActiveRecord::Base#generate_migration and dump
    # the output into your migrations
    Bottle.class_eval do
      create_read_only_my_isam_table
      enable_fulltext_search
    end
  end

  before :each do
    @one = Bottle.create! :type => 'Glass', :name => 'Orange Green Goodness', :universe_id => 1
    @two = Bottle.create! :type => 'Glass', :name => 'His Other Good Home', :universe_id => 1
    @three = Bottle.create! :type => 'Metal', :name => 'The Drink Maker', :universe_id => 1
    @four = Bottle.create! :type => 'Ceramic', :name => 'Viss Was Here', :universe_id => 1
    @five = Bottle.create! :type => 'Ceramic', :name => 'And Here Too', :universe_id => 1
  end
  
  it "should be able to find stuff" do
    results = Bottle.full_text_search(:query => 'good*', :column => 'name')
    results.should have(2).things
    results.should include(@one, @two)
  end
  
  after :all do
    Bottle.connection.execute("DROP TABLE IF EXISTS #{Bottle.mirror_table_name}")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_insert_bottles_row")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_update_bottles_row")
    Bottle.connection.execute("DROP TRIGGER IF EXISTS clone_delete_bottles_row")
  end
end
