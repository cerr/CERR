function str=jp2write(varargin)
  
% JP2WRITE  - Writes images as JPEG 2000 files to disk. Needs jasper installed.
%
% JP2WRITE(IM,'FILENAME',[OPTIONS...])
%
% Options is all options specified with -O to jasper and and an extra 'bitdepth' option.
%
% Example:
%
%     jp2write(im,'myfile.jp2','rate',0.01,'bitdepth',10);
%
% This example saves the image matrix im at 1% size of raw size and stores it with 10 bits per pixel.
%
%
%  (C) Peter Rydesäter 2002-11-08
%
% Se also: JP2IMFORMATS, JP2WRITE, IMFORMATS, IMREAD, IMWRITE, IMFINFO

  [datacells,varargin]=parseparams(varargin);
  im=datacells{1};
  if length(datacells)>1,if length(datacells{2}), warning('Colormap or other numeric options before filename not suported');end, end
  if length(varargin)<1, error('MATLAB:option','You must specify filename'); end
  filename=varargin{1};
  opts=varargin(2:end);
  [jasperoptstr,opts,optexist] = parse_parameter_list('jasper',opts,'bitdepth','format');
  [opts] = parse_parameter_list('str2num',opts);
  if optexist.bitdepth, bits=opts.bitdepth; else bits=0; end
  [pgxopts,opts,optexist] = parse_parameter_list('cell',opts,'format');
  if optexist.format,
    fmtstr=[' --output-format ',opts.format];
  else    
    idx = find(filename == '.');
    if (~isempty(idx))  
      ext = filename((idx(end) + 1):end);
      fmtstr=[' --output-format ' ext];
    else      
      fmtstr='';
    end
  end
  if size(im,3)==1,
    tmp=[tempname '.pgx'];
    try,
      pgxwrite(im,tmp,pgxopts{:});
    catch,
      delete(tmp);
      rethrow(lasterror);
    end
  else
    tmp=[tempname '.bmp'];
    if bits>8, warning('MATLAB:option','Only grayscale (one channel) are supported in more than 8 bits per channel'); end
    try,
      imwrite(im,tmp,'bmp');
    catch,
      delete(tmp);
      rethrow(lasterror);
    end
  end
  exit_code=system(sprintf('jasper --input "%s" %s --output "%s" %s 2>/dev/null',tmp,fmtstr,filename,jasperoptstr));
  if exit_code~=0, error('MATLAB:io','Could (probably) not open file "%s" for writing. Check directory or file permissions.',filename); end
  delete(tmp);
  return;