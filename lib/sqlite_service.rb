#copyright uCratos.com 2011-2013

#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.


module PersistentObject 
  #Sqlite Service is used to connect to a local sqlite3 database used to cache
  #local data in a persistent manner. It can either use the ruby/sqlite3 module
  #or a simpler pure ruby module that runs off the command line
  #NOTE that these 2 are not mixable 
   
  module SqliteService
    
    #Create a uniform interface independent of whether we use the ruby/sqite3 interface 
    #which uses the C API or the pure ruby interface in this modue which is much simpler
    #and will work on embedded platforms where the C APIII might not be available 
    begin
      raise LoadError, "Sqlite3 needs to support multiple transactions in an execute statement"
      require 'sqlite3'
      
      class SQLite3Interface < SQLite3::Database
        #set up DB with Type translation and outputting results hash
        def initialize(db)
          super(db)
          self.results_as_hash = true
          self.type_translation = true
          
          self
        end
        
        #ensure that execute does the same substitutions as the cmd line version for compatibility
        #don't know when we might want to take a DB dumped on one machine and restore it on another :-)
        def execute(str)
          str.extend(DBString)
          str.substitute!
          rows=super(str)
                    
          rows.each do |r|
            r.each{ |k,v| r[k]=v.extend(DBString).unsubstitute! if v.kind_of? String }
          end
          
          rows
        end 
        
        def simple_transaction(str)
          self.transaction{ self.execute(str) }
        end
        
        def method_missing(sym, *args)
          nil
        end
      end  
      
      
    rescue LoadError
      require_relative 'sqlite3_interface'
    end  
    
    
    ENV['PERSISTENT_OBJECT_PATH']='persistent_object.db'
    attr_reader  :sqlite_database
    
    
    def init(db=ENV['PERSISTENT_OBJECT_PATH'])
      unless @sqlite_database && !@sqlite_database.closed?
        @sqlite_database=SQLite3Interface.new(db)  
      end
     
    end
    alias :init_sqlite_service :init
  end
end
