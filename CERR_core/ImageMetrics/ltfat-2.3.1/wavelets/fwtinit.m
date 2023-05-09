function [w,info] = fwtinit(wdef,prefix)
%-*- texinfo -*-
%@deftypefn {Function} fwtinit
%@verbatim
%FWTINIT  Wavelet Filterbank Structure Initialization
%   Usage:  w = fwtinit(wdef);
%           w = fwtinit(wdef,prefix);
%           [w,info]=fwtinit(...)
%
%   Input parameters:
%         wdef   : Wavelet filters specification.
%         prefix : Function name prefix
%
%   Output parameters:
%         w    : Structure defining the filterbank.
%   
%   FWTINIT(wdef) produces a structure describing the analysis 
%   (field w.h) and synthesis (field w.g) filterbanks and a hop factors 
%   (field w.a) of a basic wavelet-type filterbank defined by wdef.
%
%   The analysis filterbank w.h is by default used in FWT and the
%   synthesis filterbank w.g in IFWT.
%
%   Both w.h and w.g are cell arrays of structs defining FIR filters
%   compatible with FILTERBANK, IFILTERBANK and related functions.
%   More preciselly, each elemement of either cell array is a struct with
%   fields .h and .offset defining impulse response and the initial 
%   shift respectivelly.
%   
%   [w,info]=FWTINIT(...) additionally returns a info struct which 
%   provides some information about the wavelet filterbank:
%
%      info.istight
%         Wavelet filterbank forms a tight frame. In such case, w.h and
%         w.g are identical.
%
%   The function is a wrapper for calling all the functions with the 
%   wfilt_ prefix defined in the LTFAT wavelets directory.
%
%   The possible formats of the wdef are the following:
%
%   1) Cell array with first element being the name of the function defining
%      the basic wavelet filters (wfilt_ prefix) and the other elements
%      are the parameters of the function. 
%
%   2) Character string as concatenation of the name of the wavelet
%      filters defining function (as above) and the numeric parameters
%      delimited by ':' character. Examples:
%
%      {'db',10} or 'db10'   
%         Daubechies with 10 vanishing moments. It calls wfilt_db(10) 
%         internally.
%      
%      {'spline',4,4} or 'spline4:4'  
%         Biorthogonal spline wavelet filters with 4 vanishing moments. 
%         Calls wfilt_spline(4,4) internally.
%      
%      {'dden',1} or 'dden1'
%         Double density wavelet filters. Calls wfilt_dden(1) where
%         the filters are stored as numerical vectors.
%
%   3) Cell array of one dimensional numerical vectors directly defining
%      the wavelet filter impulse responses.  By default, outputs of the 
%      filters are subsampled by a factor equal to the number of the 
%      filters. Pass additional key-value pair 'a',a (still inside of the
%      cell array) to define the custom subsampling factors, e.g.: 
%      {h1,h2,'a',[2,2]}.
%
%   4) The fourth option is to pass again the structure obtained from the
%      FWTINIT function. The structure is checked whether it has a valid
%      format.
%
%   5) Two element cell array. First element is the string 'dual' and the
%      second one is in format 1), 2) or 4). This returns a dual of whatever
%      is passed as the second argument.
%
%   6) Two element cell array. First element is the string 'strict' and the
%      second one is in format 1), 2), 4) or 5). This in the non tight case
%      the filters has to be defined explicitly using 'ana' and 'syn'
%      identifiers. See below.
%
%   7) Two element cell array. First element is a cell array of structures
%      defining FIR filterbank (.h and .offset fields) as in FILTERBANKWIN
%      and the second element is a numeric vector of subsampling factors.
%   
%   One can interchange the filter in w.h and w.g and use the
%   filterbank indended for synthesis in FWT and vice versa by
%   re-using the items 1) and 2) in the following way:
%
%   1) Add 'ana' or 'syn' as the first element in the cell array e.g. 
%      {'ana','spline',4,4} or {'syn','spline',4,4}.
%
%   2) Add 'ana:' or 'syn:' to the beginning of the string e.g. 
%      'ana:spline4:4' or 'syn:spline4:4'.
%
%   This only makes difference if the filterbanks are biorthogonal 
%   (e.g. wfilt_spline) or a general frame (e.g. 'symds2'), in other 
%   cases, the analysis and synthesis filters are identical. 
%
%   Please note that using e.g. c=fwt(f,'ana:spline4:4',J) and 
%   fhat=ifwt(c,'ana:spline4:4',J,size(f,1)) will not give a perfect
%   reconstruction.
%
%   The output structure has the following additional field:
%
%      w.origArgs 
%          Original parameters in format 1).
%
%
%   References:
%     S. Mallat. A Wavelet Tour of Signal Processing, Third Edition: The
%     Sparse Way. Academic Press, 3rd edition, 2008.
%     
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/fwtinit.html}
%@seealso{fwt, ifwt, wfilt_db}
%@end deftypefn

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.3.1
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.


%   **Remark:** Function names with the `wfilt_` prefix cannot contain numbers
%   and cannot start with 'ana' or 'syn'! 



% wavelet filters functions definition prefix
wprefix = 'wfilt_';
waveletsDir = 'wavelets';

% output structure definition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w.origArgs = {};
w.wprefix = wprefix;
w.h = {};
w.g = {};
w.a = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
info.istight = 0;


% return empty struct if no argument was passed
if nargin<1
  return;
end;

if isempty(wdef)
    error('%s: Input argument is empty.',upper(mfilename)); 
end

if nargin>1 
    if ischar(prefix) && ~isempty(prefix)
       wprefix = prefix;
       w.wprefix = wprefix;
    else
       error('%s: Bad format of prefix.',upper(mfilename));
    end
end


do_strict = 0;
do_dual = 0;

% Check 'strict'
if iscell(wdef) && ischar(wdef{1}) && strcmpi(wdef{1},'strict')
   do_strict = 1;
   wdef = wdef{2:end};
end
if iscell(wdef) && ischar(wdef{1}) && strcmpi(wdef{1},'dual')
   do_dual = 1;
   wdef = wdef{2:end};
end

if isstruct(wdef)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Process wdef in format 4)%
    % Do checks and return quicky %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Check the fields
    if isequal(fieldnames(wdef),fieldnames(w))
        if ~do_dual && ~do_strict
           w = wdef;
           %cachw = w;
           return;
        else 
           if ~isempty(wdef.origArgs)
              wdef = wdef.origArgs;
           else
              error('%s: The structure was not built using compatible formats.',upper(mfilename));
           end
        end
    else
       error('%s: Passed structure has different fields.',upper(mfilename)); 
    end
end

if iscell(wdef)
    wname = wdef;
    if ~ischar(wname{1})
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % Process wdef in format 3)%
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%

       if isnumeric(wname{1})
             complainDual(do_dual,'numeric cell array');
             equalsa = cellfun(@(wEl)strcmp(wEl,'a'),wname);
             apos = find(equalsa==1);
             if isempty(apos)
                apos = numel(wname)+1;
                w.a = ones(numel(wname),1)*numel(wname);
             else
                if apos==numel(wname)-1 && isnumeric(wname{apos+1}) && numel(wname{apos+1})==apos-1
                   w.a = wname{apos+1};
                else
                   error('%s: Key ''a'' have to be followed by a vector of length %i.',upper(mfilename),apos-1);
                end
             end
             w.h = formatFilters(wname(1:apos-1),[]);
             w.g = formatFilters(wname(1:apos-1),[]);
             w.origArgs = wname;
       elseif iscell(wname{1}) && numel(wname)==2 && numel(wname{1})>1
            complainDual(do_dual,'filterbank cell array');
            g = wname{1};
            a = wname{2};
            [g,asan,infotmp]=filterbankwin(g,a,'normal');
            if ~infotmp.isfir
                error('%s: Only FIR filters are supported.',upper(mfilename));
            end
            w.h = g;
            w.g = g;
            w.a = asan(:,1);
            w.origArgs = wname;
       else
          error('%s: Unrecognizer format of the filterbank definition.',upper(mfilename));
       end
       
       %cachw = w;
       return;
    end
elseif ischar(wdef)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Process wdef in format 2)%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
   try
       wname = parseNameValPair(wdef,wprefix);
       % Octave does not support the "catch err" stament, so use "lasterror"
       % instead    
       %catch err
   catch
      err=lasterror;
      % If failed, clean the cache.
      cachwDesc = [];
      cachw = [];
      error(err.message);
   end
else
    error('%s: First argument must be a string, cell or struct.',upper(mfilename));
end;

do_forceAna = [];
is_tight = 0;

% Check whether wavelet definition starts with ana or syn
if ischar(wname{1}) && numel(wname{1})==3
   if strcmpi(wname{1},'ana') || strcmpi(wname{1},'syn')
      % Set field only if ana or syn was explicitly specified.
      do_forceAna = strcmpi(wname{1},'ana');
      wname = wname(2:end);
   end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wname now contains wdef in format 1)%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Search for m-file containing string wname
wfiltFile = dir(fullfile(ltfatbasepath,sprintf('%s/%s%s.m',waveletsDir,wprefix,lower(wname{1}))));
if(isempty(wfiltFile))
   error('%s: Unknown wavelet type: %s',upper(mfilename),wname{1}); 
else
   % if found, crop '.m' from the filename 
   tmpFile = wfiltFile.name(1:end-2); 
end

% There is a bug in nargout in version 3.6 of Octave, but not in later
% stable versions
if isoctave
    octs=strsplit(version,'.');
    octN=str2num(octs{1})*1000+str2num(octs{2});
    if octN<3008
        try
            feval(tmpFile);
        catch
        end;
    end;
end;
    
wfiltNargout = nargout(tmpFile);

if(nargin(tmpFile)~=numel(wname)-1)
   error('%s: Incorrect number of parameters to be passed to the %s func.',upper(mfilename),tmpFile);
end


if(wfiltNargout==3)
   [w.h, w.g, w.a] = feval(tmpFile,wname{2:end});
elseif(wfiltNargout==4) 
   [w.h, w.g, w.a, info] = feval(tmpFile,wname{2:end});
else
   error('%s: Function %s does not return 3 or 4 arguments.',upper(mfilename),upper(tmpFile));
end


if ~isempty(info)&&isfield(info,'istight')
   is_tight = info.istight;
else
   info.istight = 0;
end

% d = [];
% if isfield(info,'d')
%    d = info.d;
% end
% 
% if numel(tmph)~=numel(w.a) || numel(tmpg)~=numel(w.a)
%    error('%s: Variables returned by %s have different element counts.',upper(mfilename),upper(tmpFile));
% end

if ~is_tight && do_strict && isempty(do_forceAna)
   error(['%s: %s filters does not form a tight frame. Choose either ',...
          '''ana:%s'' or ''syn:%s'' '],upper(mfilename),tmpFile,...
                                       wcell2str(wname),wcell2str(wname));
end
 
% w.h = formatFilters(tmph,d);
% w.g = formatFilters(tmpg,d);

w.origArgs = wname;

if ~isempty(do_forceAna)
   if do_dual
      do_forceAna = ~do_forceAna; 
   end
   if do_forceAna
      w.g = w.h;
      w.origArgs = [{'ana'}, w.origArgs];
      % Hande the Dual-tree specific stuff
      if ~isempty(info) && isfield(info,'defaultfirst')
         info.defaultfirst.g = info.defaultfirst.h; 
         info.defaultfirst.origArgs = [{'ana'},info.defaultfirst.origArgs];
      end
      if ~isempty(info) && isfield(info,'defaultleaf')
         info.defaultleaf.g = info.defaultleaf.h; 
         info.defaultleaf.origArgs = [{'ana'},info.defaultleaf.origArgs];
      end
   else
      w.h = w.g;
      w.origArgs = [{'syn'}, w.origArgs];
      % Hande the Dual-tree specific stuff
      if ~isempty(info) && isfield(info,'defaultfirst')
         info.defaultfirst.h = info.defaultfirst.g; 
         info.defaultfirst.origArgs = [{'syn'},info.defaultfirst.origArgs];
      end
      if ~isempty(info) && isfield(info,'defaultleaf')
         info.defaultleaf.h = info.defaultleaf.g; 
         info.defaultleaf.origArgs = [{'syn'},info.defaultleaf.origArgs];
      end
   end
end


end %END FWTINIT

function filts = formatFilters(cellf,d)
   noFilts = numel(cellf);
   filts = cell(noFilts,1);
   if(isempty(d))
      d = findFiltDelays(cellf,'half');
   end

   for ff=1:noFilts
      %filts{ff} = wfiltstruct('FIR');
      filts{ff}.h = cellf{ff}(:);
      filts{ff}.offset = -d(ff);
   end

end %END FORMATFILTERS

function wcell = parseNameValPair(wchar,wprefix)
%PARSENAMEVALPAIR
%Parses string in the following format wnameN1:N2... , where wname have to
%be name of the existing function with wfilt_ prefix. N1,N2,... are doubles
%delimited by character ':'.
%The output is cell array {wname,str2double(N1),str2double(N2),...}
%The wfilt_ function name cannot contain numbers

wcell = {}; 
numDelimiter = ':';

% Check whether the first 4 characters are 'ana:' or 'syn:'
if numel(wchar)>4
   if strcmpi(wchar(1:4),'ana:')
      wcell = [wcell,{'ana'}];
      wchar = wchar(5:end);
   elseif strcmpi(wchar(1:4),'syn:')
      wcell = [wcell,{'syn'}];
      wchar = wchar(5:end);
   end
end

% Take out all numbers from the string
wcharNoNum = wchar(1:find(isstrprop(wchar,'digit')~=0,1)-1);

% List all files satysfying the following: [ltfatbase]/wavelets/wfilt_*.m?
wfiltFiles = dir(fullfile(ltfatbasepath,sprintf('%s/%s*.m','wavelets',wprefix)));
% Get just the filanames without the wfilt_ prefix
wfiltNames = arrayfun(@(fEl) fEl.name(1+find(fEl.name=='_',1):find(fEl.name=='.',1,'last')-1),wfiltFiles,'UniformOutput',0);
% Compare the filenames with a given string
wcharMatch = cellfun(@(nEl) strcmpi(wcharNoNum,nEl),wfiltNames);
% Find index(es) of the matches.
wcharMatchIdx = find(wcharMatch~=0);
% Handle faulty results.
if(isempty(wcharMatchIdx))
   dirListStr = cell2mat(cellfun(@(wEl) sprintf('%s, ',wEl), wfiltNames(:)','UniformOutput',0));
   if ~all(cellfun(@isempty,wfiltNames))
      error('%s: Unknown wavelet filter definition string: %s.\nAccepted are:\n%s',upper(mfilename),wcharNoNum,dirListStr(1:end-2));
   else
      error('%s: Cannot find %s%s',upper(mfilename),wprefix,wcharNoNum); 
   end
end
if(numel(wcharMatchIdx)>1)
   error('%s: Ambiguous wavelet filter definition string. Probably bug somewhere.',upper(mfilename));
end


match = wfiltNames{wcharMatchIdx};
wcell = [wcell,{match}];
% Extract the numerical parameters from the string (delimited by :)
numString = wchar(numel(match)+1:end);
if(isempty(numString))
   error('%s: No numeric parameter specified in %s.',upper(mfilename),wchar); 
end
% Parse the numbers.
wcharNum = textscan(numString,'%f','Delimiter',numDelimiter);
if(~isnumeric(wcharNum{1})||any(isnan(wcharNum{1})))
   error('%s: Incorrect numeric part of the wavelet filter definition string.',upper(mfilename));
end
wcell = [wcell, num2cell(wcharNum{1}).'];
end %END PARSENAMEVALPAIR

function d = findFiltDelays(cellh,type)
   filtNo = numel(cellh);
   d = ones(filtNo,1);

   for ff=1:filtNo
       if(strcmp(type,'half'))
               d(ff) = floor((length(cellh{ff})+1)/2);
%        elseif(strcmp(type,'energycent'))
%            tmphh =cellh{ff};
%            tmphLen = length(tmphh);
%            ecent = sum((1:tmphLen-1).*tmphh(2:end).^2)/sum(tmphh.^2);
%            if(do_ana)
%                d(ff) = round(ecent)+1;
%                if(rem(abs(d(ff)-d(1)),2)~=0)
%                   d(ff)=d(ff)+1;
%                end
%            else
%                anad = round(ecent)+1;
%                d(ff) = tmphLen-anad;
%                if(rem(abs(d(ff)-d(1)),2)~=0)
%                   d(ff)=d(ff)-1;
%                end
%            end

       else        
           error('TO DO: Unsupported type.');
       end
  end
end %END FINDFILTDELAYS

function complainDual(dual,whereStr)
if dual
  error('%s: ''dual'' option not allowed for the %s input.',upper(mfilename),whereStr); 
end
end % END COMPLAINA

function str = wcell2str(wcell)
strNums = cellfun(@(wEl) [num2str(wEl),':'],wcell(2:end),'UniformOutput',0);
strNums = cell2mat(strNums);
str = [wcell{1},strNums(1:end-1)];
end








