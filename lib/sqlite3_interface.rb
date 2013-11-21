
module PersistantObject
  class SQLite3Interface
    include Substitution
    
    SEP='|'
    INIT_FILE=File.join(File.absolute_path(__FILE__),'..','config','sqliterc')
    SQLITE_CMD="sqlite3 -init #{INIT_FILE}"

    def initialize(db_name)
      @db_name=db_name
    end

  
       
    def parse_response_line(headers,line)
      field_hash=Hash.new 
      fields=line.split(SEP)
      fields.each_with_index do |f,i| 
        field=self.unsubstitute(f)
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
        ex_cmd=self.substitute(cmd)
        ex_cmd+=';' unless ex_cmd[-1]==';'
        sub_hash.each{|k,v| ex_cmd.gsub!(':'+k.to_s, v.to_s) } #pattern substitution in statements
                
        cmd_str="#{SQLITE_CMD}  #{@db_name} \"#{ex_cmd}\" 2>/dev/null"                                                                               
        str=`#{cmd_str}`
        
        #STDERR.puts cmd_str   
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
  end
end