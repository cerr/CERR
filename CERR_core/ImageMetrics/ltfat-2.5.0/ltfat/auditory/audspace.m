function [y,bw] = audspace(fmin,fmax,n,varargin)
%AUDSPACE  Equidistantly spaced points on auditory scale
%   Usage: y=audspace(fmin,fmax,n,scale);
%
%   AUDSPACE(fmin,fmax,n,scale) computes a vector of length n*
%   containing values equidistantly scaled on the selected auditory scale
%   between the frequencies fmin and fmax. All frequencies are
%   specified in Hz.
%
%   See the help on FREQTOAUD to get a list of the supported values of the
%   scale parameter.
%  
%   [y,bw]=AUDSPACE(...) does the same but outputs the bandwidth between
%   each sample measured on the selected scale.
%  
%   See also: freqtoaud, audspacebw, audfiltbw
%
%   Url: http://ltfat.github.io/doc/auditory/audspace.html

% Copyright (C) 2005-2022 Peter L. Soendergaard <peter@sonderport.dk> and others.
% This file is part of LTFAT version 2.5.0
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
  
%   AUTHOR : Peter L. Søndergaard
  
%% ------ Checking of input parameters ---------

if nargin<3
  error('%s: Too few input parameters.',upper(mfilename));
end;
  
% Default parameters.

if ~isnumeric(fmin) || ~isscalar(fmin) 
  error('%s: fmin must be a scalar.',upper(mfilename));
end;

if ~isnumeric(fmax) || ~isscalar(fmax) 
  error('%s: fmax must be a scalar.',upper(mfilename));
end;

if ~isnumeric(n) || ~isscalar(n) || n<=0 || fix(n)~=n
  error('%s: n must be a positive, integer scalar.',upper(mfilename));
end;

if fmin>fmax
  error('%s: fmin must be less than or equal to fmax.',upper(mfilename));
end;

definput.import={'freqtoaud'};
[flags,kv]=ltfatarghelper({},definput,varargin);


%% ------ Computation --------------------------

audlimits = freqtoaud([fmin,fmax],flags.audscale);

y = audtofreq(linspace(audlimits(1),audlimits(2),n),flags.audscale);

bw=(audlimits(2)-audlimits(1))/(n-1);

% Set the endpoints to be exactly what the user specified, instead of the
% calculated values
y(1)=fmin;
y(end)=fmax;


