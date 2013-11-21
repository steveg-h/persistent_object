persistent_object
=================

Simple object persistence library for ruby built on sqlite database

PersitentObject is designed for use in embedded situations - the itch that needed
to be scratchedwas ensuring that certain types of ruby objects could be persited through
a reboot of the process or of the entire embedded platform

PersistentObject is built as a Module, so it can be added to any existing class structure
Basically what it provides is a combination of YAML marshaling, with index fields to create a
serachable database of marshalled objects

use

require 'persistent_object'
class Foo
  include PersitentObject

  attr_accessor :foo, :bar, :baz
  self.persists :foo, :bar           # persisted variables act as inidices which acn be searched on
  
  def initialize(f,b)
    @foo=f
    @bar=b
  end
                                  
end

f=Foo.new
f.foo='a'; f.bar='b', f.baz='c'

f.save
g=Foo.load(foo: 'a', bar: 'b')          # will reload on f from the db into g
h=Foo.load(foo: 'c', bar: 'd')          # will create a new Foo, taking the persists arguments in order as constructor
                                        # arguments, up to the constructor arity

