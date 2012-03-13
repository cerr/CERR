function [a, s]=getarrowslice
% Return the Arrow and Slice based on the GCO

  if isempty(getappdata(gco,'controlarrow')) & ...
        isempty(getappdata(gco,'isosurface'))
    a = gco;
    s = getappdata(a,'arrowslice');
    if isempty(s)
      s=getappdata(a,'arrowiso');
    end
  else
    s = gco;
    if ~isempty(getappdata(s,'isosurface'))
      s=getappdata(s,'isosurface');
    end
    a = getappdata(s,'controlarrow');
  end

