require 'yaml'



require_relative 'sqlite_service'


module PersistantObject
  require_relative 'db_string'

  include SqliteService
  extend SqliteService

  attr_reader :persistant_object_id
  
  def self.included(base)
    base.extend(ClassMethods)
    base.extend(SqliteService)
  end
  
  #quotes a field if required - leaves numbers as numeric
  def self.sqlite_field(v)
    v.kind_of?(Numeric) ? v : "'"+v.to_s+"'"
  end
  
  


  module ClassMethods   
    def first(params={}, &block)
      ret=self.find(params, &block)
      row=ret && ret[0] 
      row    
    end
    
    def last(params={}, &block)
      ret=self.find(params, &block)
      row=ret && ret[-1] 
      row    
    end
    
    #load from the DB
    #if the object does not exist in the DB, and we have a single persisted variable, use that as the constructor arg
    #if the constructor takes a single arg, and we have multiple persisted variables, pass in the hash
    #otherwise pass in the first n persisted variables to match the n constructor args 
    
    def load(params, &block)
      row=first(params, &block)
      if row && row['marshal']
        self.marshal.load(row['marshal'])
      else
        param_count=self.allocate.method(:initialize).arity
        STDERR.puts "param_count is #{param_count}, persists is #{@persists.inspect}"
        if param_count==1
          @persists.size==1 ? self.new(params.values.first) : self.new(params)
        else
          param_count=param_count.abs
          param_count=@persists.size if @persists.size < param_count
          args=@persists[0...param_count].collect{|k| params[k] }
          STDERR.puts "param_count is #{param_count}, args are #{args.inspect}"
          self.new(*args)
        end
      end
    end
    
    
    def find(params={}, &block)
      #STDERR.puts "In find #{params}"
      #STDERR.puts block if block_given?
      init_sqlite_service
      
      str="SELECT * FROM #{self.name} "
      str.extend(DBString)
      unless params.empty?
        proc=param_args(params)
        #STDERR.puts proc.inspect, str
        proc.call(str) 
        #STDERR.puts proc.inspect, str
      end
        
      yield str if block_given?
      
      #STDERR.puts str
      
      ret=@sqlite_database.execute(str) 
    end    
      
    #create a list of params to persist
    #will create the table if it does not exist, but will not check that an 
    #existing table has fields for each sym in the persists list
    def persists (*sym_list)
      @persists ||=sym_list
      self.create_table
      self.marshal||=YAML
    end 
    
    def marshal=(marshal_class)
      @marshal=marshal_class
    end
    
    def marshal
      @marshal
    end
    
    def create_table
      class_name=self.name
      create_str_base="CREATE TABLE IF NOT EXISTS #{self.name}(id INTEGER PRIMARY KEY, "
      create_str=create_str_base + (@persists.collect {|p| p.to_s+' TEXT'} << 'marshal TEXT').join(',') +')'
      
      self.init_sqlite_service 
      @sqlite_database.execute(create_str)
    end
    
    #access to the list of persisted attributes for objects
    def persisted
      @persists
    end
   
    private
      
    #sanitize the param arguments to #first and #last
    def param_args(params)
      k=params.class
      p=case 
      when k<=Hash then Proc.new{|x| x.where(params) }
      when k<=Proc then params
      when k<=NilClass then  Proc.new{}
      else 
        params
      end
      
      p
    end 
    
        
  end
  
  #-------------------------------------------------------------------------------------------
  
  #find an object based on its id or persisted values
  def find(params=[])
    persisted_params=params & self.class.persisted
    conditions=persisted_params.inject({}){|h,p| h[p]=self.send(p)}
    self.class.first(conditions)
  end

  #instance methods added to each object that is persisted
  
  def save(id=nil)
    init_sqlite_service
    id||=@persistant_object_id
    
    before_save
    
    begin
      #see if we can find the object
      unless id
        row=self.class.first(self.persisted_hash) 
        id=@persistant_object_id=row['id'] if row  
      end
        
      if id
        cmd="UPDATE #{self.class} set #{self.persisted_m_update_str} where id=#{id}"
      else
        marshaler=self.class.marshal
        dump=PersistantObject.sqlite_field(marshaler.dump(self))
        cmd="BEGIN; INSERT into #{self.class}(#{(persisted_keys << 'marshal').join(',')}) VALUES(#{(persisted_values << dump).join(',')}); SELECT last_insert_rowid() AS id; END" 
      end
      #STDERR.puts cmd
      row=@sqlite_database.execute(cmd)
      @persistant_object_id ||= row && row[0] && row[0]['id']
      ensure
        after_save
      end
      
      @persistant_object_id 
    end
 
    
private unless $test
       
    #array of fields that could be used to find an object
  def persisted_keys
    self.class.persisted.collect{|x| x.to_s}
  end
  
  #array of the values that would be inserted into the persisted fields
  def persisted_values
    self.class.persisted.collect do |x| 
      v=self.send(x)
      PersistantObject.sqlite_field(v)
      
    end
  end
      
  #Hash of key-value pairs for each persisted value
  def persisted_hash
    self.class.persisted.inject({}) do |h,x|
      v=self.send(x)
      h[x]=v
      h
    end
  end
  
  #string to use for update - without marshal additions
  def persisted_update_str
    self.persisted_hash.to_a.collect{|x| "#{x[0]}=#{PersistantObject.sqlite_field(x[1])}" }.join(',')
  end
  
  #string to use for update - without marshal additions
  def persisted_m_update_str
    ph=self.persisted_hash
    ph['marshal']=self.class.marshal.dump(self)
    ph.to_a.collect{|x| "#{x[0]}=#{PersistantObject.sqlite_field(x[1])}" }.join(',')
  end
  
  #stub methods
  def before_save
  end
  
  def after_save
  end
  
  def before_load
  end
  
  def after_load
  end 

end