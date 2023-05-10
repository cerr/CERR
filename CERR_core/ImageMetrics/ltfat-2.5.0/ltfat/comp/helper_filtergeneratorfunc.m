function [filterfunc,winbw] = helper_filtergeneratorfunc(wintype,winCell,fs,bwmul,min_win,trunc_at,audscale,do_subprec,do_symmetric,do_warped)
firwinflags=getfield(arg_firwin,'flags','wintype');
freqwinflags=getfield(arg_freqwin,'flags','wintype');
probelen = 10000;

subprecflag = 'pedantic';
if ~do_subprec, subprecflag = 'nopedantic'; end

switch wintype
    case firwinflags
        winbw=norm(firwin(wintype,probelen)).^2/probelen;
        % This is the ERB-type bandwidth of the prototype

        if do_symmetric
            filterfunc = @(fsupp,fc,scal)... 
                         blfilter(winCell,fsupp,fc,'fs',fs,'scal',scal,...
                                  'inf','min_win',min_win,subprecflag);
        else
            fsupp_scale=1/winbw*bwmul;
            filterfunc = @(fsupp,fc,scal)...
                         warpedblfilter(winCell,fsupp_scale,fc,fs,...
                                        @(freq) freqtoaud(freq,audscale),...
                                        @(aud)  audtofreq(aud,audscale),...
                                        'scal',scal,'inf');
        end
        bwtruncmul = 1;
    case freqwinflags
        if do_warped
            error('%s: TODO: Warping is not supported for windows from freqwin.',...
                upper(mfilename));
        end

        probebw = 0.01;

        % Determine where to truncate the window
        H = freqwin(winCell,probelen,probebw);
        winbw = norm(H).^2/(probebw*probelen/2);
        bwrelheight = 10^(-3/10);

        if trunc_at <= eps
            bwtruncmul = inf;
        else
            try
                bwtruncmul = winwidthatheight(abs(H),trunc_at)/winwidthatheight(abs(H),bwrelheight);
            catch
                bwtruncmul = inf;
            end
        end

        filterfunc = @(fsupp,fc,scal)...
                     freqfilter(winCell, fsupp, fc,'fs',fs,'scal',scal,...
                                'inf','min_win',min_win,...
                                'bwtruncmul',bwtruncmul,subprecflag);
end


function width = winwidthatheight(gnum,atheight)

width = zeros(size(atheight));
for ii=1:numel(atheight)
    gl = numel(gnum);
    gmax = max(gnum);
    frac=  1/atheight(ii);
    fracofmax = gmax/frac;

    ind =find(gnum(1:floor(gl/2)+1)==fracofmax,1,'first');
    if isempty(ind)
        %There is no sample exactly half of the height
        ind1 = find(gnum(1:floor(gl/2)+1)>fracofmax,1,'last');
        ind2 = find(gnum(1:floor(gl/2)+1)<fracofmax,1,'first');
        rest = 1-(fracofmax-gnum(ind2))/(gnum(ind1)-gnum(ind2));
        width(ii) = 2*(ind1+rest-1);
    else
        width(ii) = 2*(ind-1);
    end
end

%
%   Url: http://ltfat.github.io/doc/comp/helper_filtergeneratorfunc.html

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

