require File.dirname(__FILE__) + '/../spec_helper'

describe 'Extending', ActiveRecord::Base do
  it "should include itself into ActiveRecord::Base" do
    ActiveRecord::Base.included_modules.should include(Warren::Extensions)
  end
end