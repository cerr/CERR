function [im,map,bits]=pgxread(filename)
% PGXREAD  - Reads images as PGX files from disk.
%  
%  This format is an input/output format to jasper and other JPEG 2000 codecs.
%
% [IM,MAP,BITS]=PGXREAD('FILENAME')
%
% IM is returned image. MAP is always empty, BITS holds number of valid bits
% in input format.
%
%  (C) Peter Rydesäter 2002-11-08
%
% Se also: JP2IMFORMATS, PGXWRITE, JP2READ, JP2WRITE, IMREAD, IMWRITE, IMFINFO
  
  map=[];
  try,f=fopen(filename,'r'); fclose(f);catch er=lasterror; if strcmp(E.identifier,'MATLAB:interupt'),rethrow(er);end,end
  if f==-1, if length( which(filename) ), filename=which(filename); f=inf; end; end
  if f==-1, error('File "%s" does not exist or is not possible to read from.',filename); end
  f=fopen(filename,'r','b');
  str=fgetl(f);
  [args]=sscanf(str,'%s %s %s %d %d %d');
  si=args(end-1:end)';
  if upper(args(3))=='L',
    fclose(f);
    f=fopen(filename,'r','l');
    fgetl(f);
  end    
  bits=args(end-2);
  if bits>16,  type='uint32';  elseif bits>8   type='uint16';    else    type='uint8';  end
  if args(5)=='-', type=type(2:end); end
  im=fread(f,si,[type '=>' type])';
  fclose(f);
  return;
