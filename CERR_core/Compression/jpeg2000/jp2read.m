function [im,map,bits]=jp2read(filename,varargin)

% JP2READ  - Reads JPEG 2000 image files from disk. Needs jasper installed
%
% [IM,MAP,BITS]=JP2READ('FILENAME')
%
%
%  (C) Peter Rydesäter 2002-11-08
%
% Se also: JP2IMFORMATS, JP2WRITE, IMFORMATS, IMREAD, IMWRITE, IMFINFO
  
  map=[];
  try,f=fopen(filename,'r'); fclose(f);catch er=lasterror; if strcmp(E.identifier,'MATLAB:interupt'),rethrow(er);end,end
   
  if f==-1, if length( which(filename) ), filename=which(filename); f=inf; end; end
  if f==-1,  error('MATLAB:io','File "%s" does not exist or is not possible to read from.',filename); end

  opts=varargin;
  [jasperoptstr,opts,optexist] = parse_parameter_list('jasper',opts,'format');
  if optexist.format,
    fmtstr=[' --input-format ' opts.format];
  else    
    idx = find(filename == '.');
    if (~isempty(idx))  
      ext = filename((idx(end) + 1):end);
      fmtstr=[' --input-format ' ext];
    else
      fmtstr='';
    end
  end
  %% Try to read via 1-31 bits grayscale pgxformat
  tmp=[tempname '.pgx'];
  exit_code=system(sprintf('jasper --input "%s" %s --output "%s" %s 2>/dev/null',filename,fmtstr,tmp,jasperoptstr));
  if exit_code==0,
    try,
      [im,map,bits]=pgxread(tmp);
    catch
      delete(tmp);
      rethrow(lasterror);
    end
  else
    %% if pgx fails
    delete(tmp);
    tmp=[tempname '.bmp'];
    exit_code=system(sprintf('jasper --input "%s" %s --output "%s" %s  2>/dev/null',filename,fmtstr,tmp, jasperoptstr));
    st=dir(tmp);
    if isempty(st), st(1).bytes=0; end
    if st(1).bytes==0, error('MATLAB:io','The file "%s" seams not possible to read via this interface.',filename); end      
    im=imread(tmp,'bmp');
    st=imfinfo(tmp);
    bits=st.BitDepth;
  end
  delete(tmp);
  return;