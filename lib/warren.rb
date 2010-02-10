require 'rubygems'
require 'active_record'
require 'logger'

module Warren
  Root = File.dirname(__FILE__)

  def self.logger
    ActiveRecord::Base.logger
  end  
  
  # Be aware that explicitly setting the
  # Warren logger changes the ActiveRecord logger too.
  #
  # Because Warren is an ActiveRecord extension, so by
  # default it uses the ActiveRecord logger for logging.
  # You may find it easier to simply configure ActiveRecord::Base.logger.
  def self.logger= logger
    ActiveRecord::Base.logger = logger
  end  
end

require "#{Warren::Root}/warren/modes"
require "#{Warren::Root}/warren/match"
require "#{Warren::Root}/warren/extensions"

ActiveRecord::Base.class_eval{ include Warren::Extensions }