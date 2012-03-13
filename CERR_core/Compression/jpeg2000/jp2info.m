function [info,msg,im] = jp2info(filename);
%JP2INFO Get information about the image in a JP2 or JPC file.
%
%  [INFO,MSG] = JP2INFO(FILENAME)
%
% This function returns a structure holding information about a JPEG 2000 image file.
% Support function to IMFINFO.
%
%  (C) Peter Rydesäter 2002-11-08
%
% Se also: JP2READ, JP2IMFORMATS, IMFINFO
%
  msg = '';
  im=[];
  if (~isstr(filename))
    msg = 'FILENAME must be a string';
    return;
  end
  
  try,
    [im,map,bits]=jp2read(filename);
  catch,
    [msg,id]=lasterr;
    if strcmp(id,'MATLAB:interupt'), rethrow(lasterror); end
    info = [];
    return;
  end
  d = dir(filename);      % Read directory information
  info.Filename = filename;
  info.FileModDate = d.date;
  info.FileSize = d.bytes;
  info.Format = isjp2(filename);
  info.FormatVersion = [];
  info.Width = size(im,2);
  info.Height = size(im,1);
  info.BitDepth = bits*size(im,3);
  if size(im,3)~=1,
    info.ColorType = 'truecolor' ;
  else
    info.ColorType = 'grayscale' ;
  end
  if strcmp(info.Format,'jp2'),
    info.FormatSignature = [0 0 0 12];      % ISTHIS OK??
  else
    info.FormatSignature = [255 79 255 81]; % ISTHIS OK??
  end
  return;
