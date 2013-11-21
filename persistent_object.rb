unless Kernel.respond_to?(:require_relative)   
  def require_relative(path)
    require File.join(File.dirname(caller[0]), path.to_str)
  end
end

require_relative 'lib/sqlite_service.rb'
require_relative 'lib/persistent_object'
