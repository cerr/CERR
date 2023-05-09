function  varargout = block_interface(varargin)
%-*- texinfo -*-
%@deftypefn {Function} block_interface
%@verbatim
%BLOCK_INTERFACE Common block processing backend
%
%  Object-like interface for sharing data between block handling
%  functions. 
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/block_interface.html}
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

if nargin<1
     error('%s: Too few input parameters.',upper(mfilename));
end

% Persistent data
persistent pos;
persistent datapos; % Second data pointer
persistent pageNo;
persistent sourceName;
persistent maxBufCount;
persistent pageList;
persistent playChanList;
persistent recChanList;
persistent skipCounter;

persistent classid;
persistent toPlayBlock;
persistent anaOverlap;
persistent synOverlap;
persistent dispLoad;

persistent Ls;
persistent Fs;

persistent loop;

% DEFAULTS
persistent bufLen;

persistent outFile;

persistent offline;

command = varargin{1};



switch command
   case {'reset','clearAll'}
      pos = 0; 
      datapos = 0; 
      sourceName = [];
      maxBufCount = 3;
      pageList = [];
      playChanList = [];
      recChanList = [];
      pageNo = 0;
      skipCounter = 0;
      classid = 'double';
      anaOverlap = [];
      synOverlap = [];
      toPlayBlock = [];
      dispLoad = 1;
      loop = 0;
      Ls = -1;
      bufLen = 1024;
      outFile = [];
      offline = 0;
      Fs = 0;
%% SETTERS %%%
   case 'setLs'
      Ls = varargin{2};
   case 'setFs'
      Fs = varargin{2};
   case 'setOutFile'
      outFile = varargin{2};
   case 'setOffline'
      offline = varargin{2};
   case 'setPos'
      pos = varargin{2};
   case 'setDatapos'
      datapos = varargin{2};
   case 'setBufCount'
      maxBufCount = varargin{2};
   case 'setPlayChanList'
      playChanList = varargin{2};
   case 'setRecChanList'
      recChanList = varargin{2};
   case 'setPageNo'
      pos = varargin{2};
   case 'setSkipped'
      skipCounter = varargin{2};
   case 'setBufLen'
      bufLen = varargin{2}; 
   case 'setClassId'
      classid = varargin{2};
   case 'setAnaOverlap'
      anaOverlap = varargin{2};
   case 'setSynOverlap'
      synOverlap = varargin{2};
   case 'setDispLoad'
      dispLoad = varargin{2};
   case 'setToPlay'
      toPlayBlock=varargin{2};
   case 'setIsLoop'
      loop = varargin{2};
   case 'setSource'
      sourceName = varargin{2};
%% GETTERS %%%
   case 'getLs'
      varargout{1}=Ls;
   case 'getFs'
      varargout{1}=Fs;
   case 'getOutFile'
      varargout{1}=outFile;
   case 'getOffline'
      varargout{1}=offline;
   case 'getPos'
      varargout{1}=pos;
   case 'getDatapos'
      varargout{1}=datapos;
   case 'getBufCount'
      varargout{1}= maxBufCount;
   case 'getPlayChanList'
      varargout{1}=playChanList;
   case 'getRecChanList'
      varargout{1}=recChanList; 
   case 'getPageList'
      varargout{1}=pageList; 
   case 'getPageNo'
      varargout{1}=pageNo; 
   case 'getSkipped'
      varargout{1}=skipCounter; 
   case 'getBufLen'
      varargout{1}=bufLen; 
   case 'getClassId'
      varargout{1}=classid; 
   case 'getAnaOverlap'
      varargout{1}=anaOverlap;
   case 'getSynOverlap'
      varargout{1}=synOverlap;
   case 'getDispLoad'
      varargout{1}=dispLoad;
   case 'getToPlay'
      varargout{1}=toPlayBlock; 
      toPlayBlock = [];
   case 'getIsLoop'
      varargout{1}=loop;
   case 'getSource'
      if isnumeric(sourceName)
         varargout{1}='numeric';
      else
         varargout{1}=sourceName;
      end
   case 'getEnqBufCount'
      varargout{1}= numel(pageList);

%% OTHER %%%
   case 'incPageNo'
      pageNo = pageNo +1;
   case 'flushBuffers'
      anaOverlap = [];
      synOverlap = [];
   case 'popPage'
      varargout{1}=pageList(1);
      pageList = pageList(2:end);
   case 'pushPage'
      pageList = [pageList, varargin{2}];   


%   case 'incSkipped'
%      skipCounter = skipCounter + varargin{2};
%   case 'readNumericBlock'
%      L = varargin{2};
%      varargout{1}=sourceName(pos+1:pos+1+L,:); 
   otherwise
      error('%s: Unrecognized command.',upper(mfilename));
end


