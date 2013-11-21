module PersistantObject

  module Substitution
    EOL='EOLEOL'
    QUOTE='QQQ'
        
    def substitute(str)
      sub=str.gsub("\n",EOL)
      sub.gsub!('"', QUOTE)
      
      sub
            
    end
    
    def unsubstitute(str)
      sub=str.gsub(EOL,"\n")
      sub.gsub!(QUOTE,'"')
      
      sub
    end

  end
end