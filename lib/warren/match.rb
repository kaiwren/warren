# Copyright 2009 Sidu Ponnappa

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and limitations under the License.

module Warren
  module Match
    def self.extended(klass)
      Kernel.const_set(klass.mirror_class_name, Class.new(ActiveRecord::Base))
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
        query = "SELECT * FROM #{self.mirror_table_name} WHERE MATCH (#{search[:column]}) AGAINST ('#{search[:query]}' #{search[:mode]})"
        self.connection.execute(query).each_hash do |data|
          instance = self.new(data)
          instance.send("#{primary_key}=", data[primary_key])
          instances << instance
        end
      end
    end
  end
end