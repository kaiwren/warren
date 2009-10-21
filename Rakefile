# Copyright 2009 Sidu Ponnappa

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

require 'rubygems'
gem 'rspec', '>= 1.2.6'
require 'rake'
require 'spec'
require 'spec/rake/spectask'

desc 'Default: run spec tests.'
task :default => :spec

desc "Run all specs"
Spec::Rake::SpecTask.new(:spec) do |task|
  task.spec_files = FileList['spec/warren/**/*_spec.rb']
  task.spec_opts = ['--options', 'spec/spec.opts']
end

begin
  require 'hanna/rdoctask'
rescue LoadError
  puts 'Hanna not available, using standard Rake rdoctask. Install it with: gem install mislav-hanna.'
  require 'rake/rdoctask'
end
desc 'Generate documentation for Wrest'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = 'Warren Documentation'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

begin
  require 'rcov'
  require 'rcov/rcovtask'
  desc "Run all specs in spec directory with RCov"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_opts = ['--options', "spec/spec.opts"]
    t.spec_files = FileList["spec/warren/**/*_spec.rb"]
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
    end
    # t.verbose = true
  end
rescue LoadError
  puts "Rcov not available."
end

namespace :specs do
  desc "Load the spec/schema.rb file into the database"
  task :load_schema do
    require "lib/warren"
    ActiveRecord::Base.establish_connection(YAML.load_file("spec/database.yml")["test"])
    load("spec/schema.rb")
  end
end