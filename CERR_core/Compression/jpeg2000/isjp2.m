%ISJP2   Support function to IMFORMATS, IMREAD ....
%
%  (C) Peter Rydesäter 2002-11-08
%
% Se also: JP2READ, JP2IMFORMATS, IMFINFO
%
function fmt=isjp2(filename)
  fmt='';
  if length(filename)<4,
    return;
  end
  ext=lower(filename(end-3:end));
  if strcmp(ext,'.jp2'),
    fmt='jp2';
  elseif strcmp(ext,'.jpc'),
    fmt='jpc';
  end
  return;
