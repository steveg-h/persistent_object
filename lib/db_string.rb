module DBString 
  def where(conditions={})
     condition_strs=conditions.collect do |k,v| 
       #if v is a pure string then quote it
       #otherwise, assume it is a string expression
       vs=  '='+v.to_s
       if v.kind_of?(String) 
         vs=(v=~/^\W/) ? v.to_s : "='"+v.to_s+"'"
       end 
        
       k.to_s + vs
     end
     self << (condition_strs.empty? ? '' : ' WHERE '+condition_strs.join(' AND '))
   end
   
   def order(field, dir="asc")
     self << ' ORDER BY '+field.to_s+' '+dir
   end
   
   def limit(no)
     self << ' LIMIT '+no.to_s
   end
   
end
