function g = comp_filterbank_pre(g,a,L,crossover)
%-*- texinfo -*-
%@deftypefn {Function} comp_filterbank_pre
%@verbatim
%COMP_FILTERBANK_PRE Return sanitized filterbank
%
%   The purpose of this function is to evauate all parameters of the
%   filters, which can be evaluated knowing L. The function can work only
%   with g and a in proper formats i.e. processed by
%   FILTERBANKWINDOW.
%
%   This function expects all numeric g{ii}.H to be instantiated with a
%   proper L.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_filterbank_pre.html}
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


if nargin<4
   crossover = 0; 
end

M=numel(g);

% Divide filters to time domain and frequency domain groups
mFreq = 1:M;
mTime = mFreq(cellfun(@(gEl,aEl) isfield(gEl,'h') && numel(gEl.h)<=crossover,g(:),num2cell(a(:,1)))>0); 
mFreq(mTime) = [];

% Prepare time-domain filters
for m = mTime

   % Handle .fc parameter
   if isfield(g{m},'fc') && g{m}.fc~=0
      l = (g{m}.offset:g{m}.offset+numel(g{m}.h)-1).'/L;
      g{m}.h = g{m}.h.*exp(2*pi*1i*round(g{m}.fc*L/2)*l);
      g{m}.fc = 0;
   end

   if isfield(g{m},'realonly') && g{m}.realonly
      g{m}.h = real(g{m}.h);
      g{m}.realonly = 0;
   end

   % Do zero padding when the offset is big enough so the initial imp. resp.
   % support no longer intersects with zero
   if g{m}.offset > 0
      g{m}.h = [zeros(g{m}.offset,1,class(g{m}.h));g{m}.h(:)];
      g{m}.offset = 0;
   end

   if g{m}.offset < -(numel(g{m}.h)-1)
      g{m}.h = [g{m}.h(:);zeros(-g{m}.offset-numel(g{m}.h)+1,1,class(g{m}.h))];
      g{m}.offset = -(numel(g{m}.h)-1);
   end

end

% Prepare frequency-domain filters
%l=(0:L-1).'/L;
for m=mFreq

    if isfield(g{m},'h')
       tmpg = circshift(postpad(g{m}.h,L),g{m}.offset);
       g{m}=rmfield(g{m},'h');
       g{m}=rmfield(g{m},'offset');
       if isfield(g{m},'fc') 
           l=(0:L-1).'/L;
           tmpg = tmpg.*exp(2*pi*1i*round(g{m}.fc*L/2)*l);
           g{m}=rmfield(g{m},'fc'); 
       end;
       g{m}.H = fft(tmpg);
       % The following parameters have to be set to zeros, because they
       % have already been incorporated in the freq. resp. calculation.
       g{m}.foff = 0;
       % Store the length used
       g{m}.L = L;
    elseif isfield(g{m},'H') 
       if isnumeric(g{m}.H)
           if isfield(g{m},'L')
              if g{m}.L~=L
                 % middlepad in the time domain. This will break
                 %g.H = fft(middlepad(ifft(circshift(postpad(g.H(:),g.L),g.foff)),L));
                 %g.foff = 0;
                 %g.L = L;
                 error(['%s: g.H was already instantialized with L=%i, but ',...
                 'it is now used with L=%i.'],upper(mfilename),g{m}.L,L);
              end
           else
              % We do not know which L was g.H created with, there is no way
              % how to handle this properly.
              error('%s: g.H is already a numeric vector, but g.L was not specified.',...
              upper(mfilename));
           end
       elseif isa(g{m}.H,'function_handle')
          g{m}.H=g{m}.H(L);
          if numel(g)>1 && isempty(g{m}.H)
              fprintf('%s: Warning: Filter %4d has zero bandwidth.\n',upper(mfilename),m);
          end
          
          if numel(g{m}.H) > L
              error('%s: Filter bandwidth is bigger than L.\n',upper(mfilename));
          end
          
          % Store the length used
          g{m}.L = L;
       else
           error('%s: SENTINEL: Wrong format of g{ii}.H ',upper(mfilename));
       end
       if isfield(g{m},'foff')
           if isa(g{m}.foff,'function_handle') 
              g{m}.foff=g{m}.foff(L);
           elseif isscalar(g{m}.foff)
               % Nothing
           else
              error('%s: SENTINEL: Wrong format of g{ii}.foff ',upper(mfilename));
           end
        else
           g.foff = 0;
        end
    end

    if isfield(g{m},'H') && isfield(g{m},'delay') && g{m}.delay~=0
       % handle .delay parameter
       lrange = mod(g{m}.foff:g{m}.foff+numel(g{m}.H)-1,L).'/L;
       g{m}.H=g{m}.H.*exp(-2*pi*1i*round(g{m}.delay)*lrange); 
       g{m}.delay = 0;
    end


    % Treat full-length .H, but only for non-fractional subsampling
    % 
    % Just find out whether we are working with fract. subsampling.
    [~,info]=comp_filterbank_a(a,M,struct); 

    if numel(g{m}.H)==L && ~info.isfractional
       if isfield(g{m},'foff') && g{m}.foff~=0 
          % handle .foff parameter for full-length freq. resp.
          g{m}.H = circshift(g{m}.H,g{m}.foff);
          % to avoid any other moving
          g{m}.foff = 0;
       end

       if isfield(g{m},'realonly') && g{m}.realonly
          % handle .realonly parameter for full-length freq. resp.
          g{m}.H=(g{m}.H+involute(g{m}.H))/2;
          g{m}.realonly = 0;
       end;
    end
end;





