function vnorms = framevectornorms(F,L,varargin)
%-*- texinfo -*-
%@deftypefn {Function} framevectornorms
%@verbatim
%FRAMEVECTORNORMS  Norm of frame vectors 
%   Usage: vnorms = framevectornorms(F,L)
%          vnorms = framevectornorms(F,L,idx)
%
%   Input parameters:
%       F        : Frame definition
%       L        : System length
%       idx      : Index (or range) of vector(s)
%   Output parameters:
%       vnorms   : Vector norms
%
%   FRAMEVECTORNORMS(F,L) returns 2-norms of vectors of frame F for
%   system length L. The number of vectors in a frame (and the length of
%   the output vector) can be obtained as frameclength(F,L).
%
%   FRAMEVECTORNORMS(F,L,idx) returns 2-norms of vectors with indices 
%   idx. Elements in idx must be in range 1:frameclength(F,L).
%
%   Real-valued-input frames
%   ------------------------
%
%   By default, the function returns the norm of vectors used for
%   synthesis. Frames like 'dgtreal', 'filterbankreal' do not contain the 
%   ''redundant'' conjugate-symmetric vectors and their synthesis operator
%   is not linear. Therefore the vectors used in synthesis do not have 
%   an explicit form and their norm is unspecified. The vectors used for 
%   analysis are well defined and can be obtained by passing additional
%   flag 'ana'.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/framevectornorms.html}
%@seealso{frsynmatrix}
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

%AUTHOR: Zdenek Prusa

thismfile = upper(mfilename);
complainif_notenoughargs(nargin,2,thismfile);
complainif_notvalidframeobj(F,thismfile);
complainif_notposint(L,'L',thismfile);

definput.keyvals.idx=[];
definput.flags.method = {'auto', 'slow'};
definput.flags.anasyn = {'syn','ana'};
[flags,kv,idx]=ltfatarghelper({'idx'},definput,varargin);

Lcheck = framelength(F,L);

if Lcheck~=L
    error('%s: Incompatible frame length. Next compatible one is %i.',...
          upper(mfilename),Lcheck);
end

if F.realinput && flags.do_syn
     error(['%s: The real-valued-input frame synthesis opearor is ' ...
            'non-linear, therefore the vector norms are undefined. ' ... 
            'To get norms of the vectors used in the analysis pass ' ...
            '''ana'''], upper(mfilename));
end

N = frameclength(F,L);

if isempty(idx)
    idx = 1:N;
end

if any(idx > N) || any(idx < 1)
    error('%s: Requested vector index is not in range 1:%d', ...
          thismfile,N);
end

F = frameaccel(F,L);
vnorms = zeros(numel(idx),1);

if flags.do_auto
    switch F.type
        case 'gen'
            [~,vnorms] = normalize(F.g(:,idx));
        case {'dgt','dgtreal','dwilt','wmdct'}
            vnorms(:) = norm(F.g);
        case {'filterbank','filterbankreal','ufilterbank'}
            [~,scal] = filterbankscale(F.g,L,'2');
            channorm = 1./scal;
            subidx = [0; cumsum(L./F.a(:,1).*F.a(:,2))];
            for ii = 1:numel(vnorms)
               vnorms(ii) = channorm(find( idx(ii) > subidx, 1,'last'));
            end
        case { 'dft','dftreal',...
               'dcti','dctii','dctiii','dctiv',...
               'dsti','dstii','dstiii','dstiv', 'identity'}
             vnorms(:) = 1;
        case 'fwt'
            [g, a] = wfbt2filterbank({F.g,F.J,'dwt'});
            vnorms = framevectornorms(frame('filterbank',g,a,numel(g)),L,idx);
        case 'ufwt'
            g = wfbt2filterbank({F.g,F.J,'dwt'});
            vnorms = framevectornorms(frame('filterbank',g,1,numel(g)),L,idx);
        case 'wfbt'
            [g, a] = wfbt2filterbank(F.info.wt);
            vnorms = framevectornorms(frame('filterbank',g,a,numel(g)),L,idx);
        case 'uwfbt'
            g = wfbt2filterbank(F.info.wt);
            vnorms = framevectornorms(frame('filterbank',g,1,numel(g)),L,idx);
        case 'fusion'
            idxaccum = 1;
            for p = 1:numel(F.frames)
                atno = frameclength(F.frames{p},L);
                thisframeidx = idx(idx >= idxaccum & idx < idxaccum + atno);
                vnorms(thisframeidx) = ...
                    F.w(p)*framevectornorms(F.frames{p},L,thisframeidx-idxaccum+1);
                idxaccum = idxaccum + atno;
            end
        otherwise
            flags.do_slow = 1;
    end
end

if flags.do_slow
    % Fallback option
    if ~flags.do_syn
        error('%s: Unsupported frame.',thismfile);
    end

    ctmp = zeros(N,1);
    for ii = 1:numel(vnorms)
        ctmp(idx(ii)) = 1;
        vnorms(ii) = norm(F.frsyn(ctmp));
        ctmp(:) = 0;
    end
end


