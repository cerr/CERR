function tf=propcheck(obj, prop, value)
% Check to see if PROP for OBJ has VALUE
  
  v=get(obj,prop);

  if isa(v,class(value))
    if isa(v,'char')
      tf=strcmp(v,value);
    else
      if v==value
        tf=1;
      else
        tf=0;
      end
    end
  else
    tf=0;
  end
