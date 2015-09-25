function popset(handle,prop)
% POPSET - pop values for a property from a value stack.
%
% POPSET(HANDLE, PROP) will restore a prevously HGPUSHED property value.
%


  nargchk(2,2,'wrong number of arguments.');

  proplist=fieldnames(get(handle(1)));
  prop=proplist{strcmpi(prop,proplist)};

  appstr = [prop '_hgstack'];

  for k=1:prod(size(handle))
    
    olds = getappdata(handle(k),appstr);

    if length(olds) <= 1
      error(['Nothing left to pop for property ' prop '.']);
    end

    set(handle(k),prop,olds{1});
    setappdata(handle(k),appstr,olds{2:end});

  end
