function gf=filterbankresponse(g,a,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} filterbankresponse
%@verbatim
%FILTERBANKRESPONSE  Response of filterbank as function of frequency
%   Usage:  gf=filterbankresponse(g,a,L);
%      
%   gf=FILTERBANKRESPONSE(g,a,L) computes the total response in frequency
%   of a filterbank specified by g and a for a signal length of
%   L. This corresponds to summing up all channels. The output is a
%   usefull tool to investigate the behaviour of the windows, as peaks
%   indicate that a frequency is overrepresented in the filterbank, while
%   a dip indicates that it is not well represented.
%
%   CAUTION: This function computes a sum of squares of modulus of the 
%   frequency responses, which is  also the diagonal of the Fourier 
%   transform of the frame operator.
%   Use FILTERBANKFREQZ for evaluation or plotting of frequency responses
%   of filters.
%
%   FILTERBANKRESPONSE(g,a,L,'real') does the same for a filterbank
%   intended for positive-only filterbank.
%
%   FILTERBANKRESPONSE(g,a,L,fs) specifies the sampling rate fs. This
%   is only used for plotting purposes.
%
%   gf=FILTERBANKRESPONSE(g,a,L,'individual') returns responses 
%   in frequency of individual filters as columns of a matrix. The total
%   response can be obtained by gf = sum(gf,2). 
%
%   FILTERBANKRESPONSE takes the following optional parameters:
%
%      'fs',fs    
%                 Sampling rate, used only for plotting.
%
%      'complex'  
%                 Assume that the filters cover the entire frequency
%                 range. This is the default.
%
%      'real'     
%                 Assume that the filters only cover the positive
%                 frequencies (and is intended to work with real-valued
%                 signals only).
%
%      'noplot'   
%                 Don't plot the response, just return it.
%
%      'plot'     
%                 Plot the response using PLOTFFTREAL or PLOTFFT.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankresponse.html}
%@seealso{filterbank, filterbankbounds}
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
  
definput.flags.ctype={'complex','real'};
definput.flags.plottype={'noplot','plot'};
definput.flags.type={'total','individual'};
definput.keyvals.fs=[];
[flags,kv,fs]=ltfatarghelper({'fs'},definput,varargin);

[g,asan]=filterbankwin(g,a,L,'normal');
M=numel(g);

gf = zeros(L,M);
for m=1:M
    gf(:,m) = comp_filterbankresponse(g(m),asan(m,:),L,flags.do_real);
end

if flags.do_total
    gf = sum(gf,2);
end

if flags.do_plot
    if flags.do_real
        plotfftreal(gf(1:floor(L/2)+1,:),fs,'lin');
    else
        plotfft(gf,fs,'lin');
    end;
end;

