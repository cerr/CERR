function pgxwrite(varargin)
  
% PGXWRITE  - Writes images as PGX files to disk.
%  
%  This format is an input/output format to jasper and other JPEG 2000 codecs.
%
% PGXWRITE(IM,'FILENAME',['bitdepth',bits])
%
% Bit 'bitdepth' set number of bits to store with, otherwise detected from the
% data type of IM
%
% Example:
%
%     pgxwrite(im,'myfile.pgx','bitdepth',10);
%
% This example saves the image matrix im at 1% and tells that 10 bits per pixel
% should be used.
%
%  (C) Peter Rydesäter 2002-11-08
%
% Se also: JP2IMFORMATS, PGXREAD, JP2READ, JP2WRITE, IMREAD, IMWRITE, IMFINFO
  
  [datacells,varargin]=parseparams(varargin);
  im=datacells{1};
  if size(im,3)>1, error('PGXWRITE do not suport color images. Only gray single chanel.'); end
  if length(datacells)>1,if length(datacells{2}), warning('Colormap or other numeric options before filename not suported');end,end
  if length(varargin)<1, error('You must specify filename'); end
  filename=varargin{1};
  varargin=varargin(2:end);
  
  pgx_opts=struct([]);
%  if length(varargin),
    [dummy,pgx_opts,optexist] = parse_parameter_list('struct',varargin,'bitdepth');
    [pgx_opts      ] = parse_parameter_list('num2str',pgx_opts);
    dfn=fieldnames(dummy);
    if length(dfn),
      warning( ['Uknown options: ', sprintf('"%s" ',dfn{:})] );
    end
%  end  
  if optexist.bitdepth,
    bits=pgx_opts.bitdepth;
    if strncmp(class(im),'i',1),
      sign=1;
    else
      sign=0;
    end
  elseif strcmp(class(im),'uint8'),
    bits=8; sign=0;    
  elseif strcmp(class(im),'uint16'),
    bits=16;sign=0;
  elseif strcmp(class(im),'uint32'),
    bits=32;sign=0;
    sign=0
  elseif strcmp(class(im),'int8'),
    bits=8; sign=1;    
  elseif strcmp(class(im),'int16'),
    bits=16;sign=1;
  elseif strcmp(class(im),'int32'),
    bits=32;sign=1;
  elseif islogical(im),
    bits=1;sign=0;
  else
    bits=8;sign=0;
  end

  if strcmp(class(im),'double'),
    im=im.*(2.^(bits-sign)-1);
  elseif strcmp(class(im),'uint8') & bits>8,
    im=bitshift(im,bits-8);
  elseif strcmp(class(im),'uint16') & bits<=8,
    im=bitshift(im,bits-16);
  end
  
  if sign,
    if bits<=8,    
      im=int8(im);
    elseif bits<=16,
      im=int16(im);
    else
      im=int32(im);
    end
  else
    if bits<=8,    
      im=uint8(im);
    elseif bits<=16,
      im=uint16(im);
    else
      im=uint32(im);
    end
  end
  f=fopen(filename,'w','b');
  if f==-1, error(['Could not open file "' filename '" for writing.  Check directory or file permissions.']); end
  sigtab='+-';
  fprintf(f,'PG ML %s %d %d %d\n',sigtab(sign+1),bits,size(im,2),size(im,1));
  fwrite(f,im',class(im));
  fclose(f);
  return;
  
  