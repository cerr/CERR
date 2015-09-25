function jp2imformats(opt,varargin)
% JP2IMFORMATS - Add and remove jp2/jpc as interface for imread/imwrite/imfinfo 
%
% This function adds jpeg2000 support to MATLABs imread/imwrite/infinfo
% via an interface to jasper. by calling the IMFORMATS function.
% 
% Syntax:
%
%    JP2IMFORMATS 'OPTION1' 'OPTION2' ....
%
% Available options:
%
%    'JP2'   Add jp2 jpc support.
%    'JPC'   Add jp2 jpc support.
%    'PGX'   Add pgx support.
%    'ADD'   Add jp2 jpc and pgx support.
%    'RMJP2' Remove jp2 jpc support.
%    'RMJPC' Remove jp2 jpc support.
%    'RM'    Remove jp2 jpc and pgx support.
%    'SHOW'  List all imageformats with IMFORMATS.
%
%  Add support to  IMREAD, IMWRITE, IMFINFO for jpeg 2000 via jasper is in
%  this example:
%
%     jp2format jp2
%
%
%  This interface created by Peter Rydesäter 2002-11-08
%
% Se also: JP2WRITE, JP2READ, IMFORMATS, IMREAD, IMWRITE, IMFINFO
%
  if nargin==0,
    return;
  end
  switch lower(opt),
   case {'add'}
    jp2imformats jp2 pgx;
   case {'remove' 'rm'}
    jp2imformats rmjp2 rmpgx;
   case {'show'}
    imformats;
   case {'jp2' 'jpc'}
    stjp2=imformats('jp2'); 
    stlst=imformats;
    if isempty(stjp2),
      st.ext= {'jp2' 'jpc'};
      st.isa= @isjp2;
      st.info= @jp2info;
      st.read= @jp2read;
      st.write= @jp2write;
      st.alpha= 0;
      st.description= 'JPEG 2000, Interface to "jasper" by Peter Rydesäter';      
      imformats([stlst st]);
    end
   case {'pgx'}
    stjp2=imformats('pgx'); 
    stlst=imformats;
    if isempty(stjp2),
      st.ext= {'pgx'};
      st.isa= @ispgx;
      st.info= '';
      st.read= @pgxread;
      st.write= @pgxwrite;
      st.alpha= 0;
      st.description= 'PGX, A "jasper" input/output format, Peter Rydesäter';      
      imformats([stlst st]);
    end
   case {'rmjp2' 'rmjpc'}
    stjp2=imformats('jp2'); 
    stlst=imformats;
    if length(stjp2),
      idx=strmatch(stjp2.description,{ stlst(:).description });
      stlst=stlst([ 1:idx-1, idx+1:end]);
      imformats(stlst);
    end
   case {'rmpgx' }
    stjp2=imformats('pgx'); 
    stlst=imformats;
    if length(stjp2),
      idx=strmatch(stjp2.description,{ stlst(:).description });
      stlst=stlst([ 1:idx-1, idx+1:end]);
      imformats(stlst);
    end
  end
  if length(varargin),
    jp2imformats(varargin{:});
  end
  return;
    