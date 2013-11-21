#copyright uCratos.com 2011
$:<<Dir.getwd

$test=true

require 'test/unit'
require 'test/unit_ext'
require 'fileutils'

require 'test/free_port'
require 'lib/ext/kernel'
require 'lib/db_client/persistant_object'
require 'pp'


include DBClient

class Mock
  include PersistantObject
  attr_accessor :param1, :param2, :param3
  self.persists :param1, :param2
  
  def initialize(p1,p2)
    @param1=p1
    @param2=p2
    @param3=@param1*@param2
  end
end

class TestPersistantObject < Test::Unit::TestCase
  include PersistantObject
  
  THREAD_SLEEP=$thread_sleep || 0.02
  TEST_SLEEP=$test_sleep || THREAD_SLEEP*10
  LONG_SLEEP=$long_sleep || TEST_SLEEP*10
  
  attr_accessor :param1, :param2
  self.persists :param1, :param2
  
  
  def setup
    init_sqlite_service
    @sqlite_database.execute("delete from #{self.class}")
    @sqlite_database.execute("delete from #{Mock}")
        @tpo=self.class
  end
  
  def test_01_create_table
    #table should be created automatically
    assert_not_nil(@sqlite_database.execute('.tables'))
    assert_equal(YAML, self.class.marshal)
  end
    
  def test_02_DBSting
    #need to add DBString functionality to a blank string
    #and dup it every time we use it as the DBString methods act in place
    s=''
    s.extend(DBString) 
    
    assert_equal('', s.clone.where())
    assert_equal(' WHERE param3=1', s.clone.where(:param3 => 1) )
    assert_equal(" WHERE param4='text'",  s.clone.where(:param4 => 'text') )
    assert_equal(' WHERE param5!=2',  s.clone.where(:param5 => "!=2") )
    assert_equal(" WHERE param6!='text'",  s.clone.where(:param6 => "!='text'") )
                
    str= s.clone.where(:param7 => 1, :param8 => "text")
    assert(str=~/param7=1/ && str=~/param8='text'/)  #no set order as Hash does not keep keys in a set order
  end
  
  def test_03_find_first_last
    self.param1=1
    self.param2=2
    
    @sqlite_database.execute("INSERT into #{self.class}(param1, param2) VALUES(#{self.param1}, #{self.param2})")
    
    rows=@tpo.find {|x| x.where(:param1 => param1, :param2 => param2) }
    assert_equal(1, rows.size)
    
    rows=@tpo.find(:param1 => param1, :param2 => param2) 
    assert_equal(1, rows.size)
 
    rows=@tpo.find(:param1 => param1, :param2 => param2){|x| x.order :param1 }
    assert_equal(1, rows.size)
  
    
    row=@tpo.first(:param1 => param1, :param2 => param2)
    assert_equal(1, rows.size) 
    
    row=@tpo.last(:param1 => param1, :param2 => param2) 
    assert_equal(1, rows.size)
    
  end
  
  def test_04_save
    self.param1=1
    self.param2='test'
    
    assert_equal(['param1','param2'], self.persisted_keys)
    assert_equal([self.param1, "'"+self.param2.to_s+"'"], self.persisted_values)
    
    assert_equal({:param1 => self.param1, :param2 =>self.param2}, self.persisted_hash)
    assert_equal("param1=#{self.param1},param2=#{PersistantObject.sqlite_field(self.param2)}", self.persisted_update_str)
    
    self.param2=2
    
    m=Mock.new(self.param1, self.param2)
    id=m.save
    assert(id)
    assert(mm=Mock.first(:id => id))
    assert(mm['param1']=m.param1)
    assert(mm['param2']=m.param2)
      
    m.param2=3
    id=m.save
    assert(id)
    assert(mm=Mock.first(:id => id))
    assert(mm['param1']=m.param1)
    assert(mm['param2']=m.param2)
      
    mmm=Mock.load(:param1 => m.param1, :param2 =>m.param2)
    assert_equal(m.param1,mmm.param1)
    assert_equal(m.param2,mmm.param2)
  
    mmmm=Mock.load(:param1 => 3, :param2 =>4)
    assert mmmm.kind_of? Mock
    assert_equal(3, mmmm.param1)
    assert_equal(4, mmmm.param2)
  end
end