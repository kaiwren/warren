require File.expand_path(File.dirname(__FILE__) + "/../lib/warren")
require 'spec'

Warren.logger = Logger.new(File.open("#{Warren::Root}/../log/test.log", 'a'))

ActiveRecord::Base.establish_connection(YAML.load_file("spec/database.yml")["test"])

class Bottle < ActiveRecord::Base
end