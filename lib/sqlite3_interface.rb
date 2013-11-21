
module PersistentObject
  class SQLite3Interface
    
    SEP='|'
    INIT_FILE=File.join(File.dirname(__FILE__),'..','config','sqliterc')
    SQLITE_CMD="sqlite3 -init #{INIT_FILE}"

    def initialize(db_name)
      @db_name=db_name
    end

  
       
    def parse_response_line(headers,line)
      field_hash=Hash.new 
      fields=line.split(SEP)
      fields.each_with_index do |field,i| 
        field.extend(DBString)
        field.unsubstitute!
        val=field
        val=field.to_i if f=~/^\d+/
        val=field.to_f if f=~/^\d+\.\d+/
        field_hash[headers[i]]=val
      end
      field_hash
    end

    
    def execute(cmd, sub_hash={})
      response=[]
      begin
        #replace "\n" chars with EOL and write (YAML may have EOLs)
        cmd.extend(DBString)
        cmd.substitute!
        sub_hash.each{|k,v| cmd.gsub!(':'+k.to_s, v.to_s) } #pattern substitution in statements
                
        cmd_str="#{SQLITE_CMD}  #{@db_name} \"#{cmd}\" 2>/dev/null"                                                                               
        str=`#{cmd_str}`
        
        #STDERR.puts cmd_str,str
         
        resp=str.split("\n")
        resp.shift #remove loading statement from sqlite startup
        
        unless resp.empty?
          #are turn it into an array
          headers=resp.shift.split(SEP).collect{|s| s.strip}
          response=resp.inject([]) do |array, line|
            field_hash=parse_response_line(headers,line)
            array << field_hash
          end
        end
      ensure
      end  
      
      response
    end
    
    def simple_transaction(str)
      self.execute('BEGIN;'+str+';END')
    end
    
    def method_missing(sym, *args)
      nil
    end
  end
end
