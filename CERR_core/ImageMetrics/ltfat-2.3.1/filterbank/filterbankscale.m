function [g,scal] = filterbankscale(g,varargin)
%-*- texinfo -*-
%@deftypefn {Function} filterbankscale
%@verbatim
%FILTERBANKSCALE Scale filters in filterbank
%   Usage:  g=filterbankscale(g,scal)
%           g=filterbankscale(g,'flag')
%           g=filterbankscale(g,L,'flag')
%           [g,scal]=filterbankscale(...)
%
%   g=FILTERBANKSCALE(g,scal) scales each filter in g by multiplying it
%   with scal. scal can be either scalar or a vector of the same length
%   as g. The function only works with filterbanks already instantiated
%   (returned from a function with a filter (of filters) suffix or run
%   trough FILTERBANKWIN) such that the elements of g must be either structs
%   with .h or .H fields or be plain numeric vectors.
%
%   g=FILTERBANKSCALE(g,'flag') instead normalizes each filter to have
%   unit norm defined by 'flag'. It can be any of the flags recognized by
%   NORMALIZE. The  normalization is done in the time domain by default.
%   The normalization can be done in frequency by passing extra flag 'freq'.
%
%   g=FILTERBANKSCALE(g,L,'flag') works as before, but some filters require
%   knowing L to be instantialized to obtain their norm. The normalization
%   will be valid for the lengh L only.
%
%   [g,scal]=FILTERBANKSCALE(g,...) additionally returns a vector scal 
%   which contains scaling factors used.
%
%   In any case, the returned filters will be in exactly the same format as
%   the input filters.
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/filterbankscale.html}
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

complainif_notenoughargs(nargin,2,'FILTERBANKSCALE');

definput.import={'normalize'};
definput.importdefaults={'norm_notset'};
definput.flags.normfreq = {'nofreq','freq'};
definput.keyvals.arg1 = [];
[flags,kv,arg1]=ltfatarghelper({'arg1'},definput,varargin);

% Try running filterbankwin without L. This should fail
% for any strange filter definitions like 'gauss','hann',{'dual',...}
try
    filterbankwin(g,1,'normal');
catch
    err = lasterror;
    if strcmp(err.identifier,'L:undefined')
        % If it blotched because of the undefined L, explain that.
        % This should capture only formats like {'dual',...} and {'gauss'}
        error(['%s: Function cannot handle g in such format. ',...
        'Consider pre-formatting the filterbank by ',...
        'calling g = FILTERBANKWIN(g,a) or ',...
        'g = FILTERBANKWIN(g,a,L) first.'],upper(mfilename));
   else
       % Otherwise just rethrow the error
       error(err.message);
   end
end


% At this point, elements of g can only be:
% struct with numeric field .h,
% struct with numeric field .H
% struct with function handle in .H
% numeric vectors

if flags.do_norm_notset
    % No flag from normalize was set
    scal = scalardistribute(arg1,ones(size(g)));

    for ii=1:numel(g)
        if isstruct(g{ii})
            % Only work with .h or .H, any other struct field is not
            % relevant
            if isfield(g{ii},'h')
                if ~isnumeric(g{ii}.h)
                    error('%s: g{ii}.h must be numeric',upper(mfilename));
               end
               g{ii}.h = scal(ii)*g{ii}.h;
           elseif isfield(g{ii},'H')
               if isa(g{ii}.H,'function_handle')
                   g{ii}.H = @(L) scal(ii)*g{ii}.H(L);
               elseif isnumeric(g{ii}.H)
                   g{ii}.H = scal(ii)*g{ii}.H;
               else
                   error(['%s: g{ii}.H must be either numeric or a ',...
                   ' function handle'],upper(mfilename));
               end
           else
               error('%s: SENTINEL. Unrecognized filter struct format',...
               upper(mfilename));
           end
       elseif isnumeric(g{ii})
           % This is easy
           g{ii} = scal(ii)*g{ii};
       else
           error('%s: SENTINEL. Unrecognized filter format',...
           upper(mfilename));
       end
   end
else
    scal = zeros(numel(g),1);
    % Normalize flag was set
    for ii=1:numel(g)
        L = arg1; % can be still empty
        % Run again with L specified
        [g2,~,info] = filterbankwin(g,1,L,'normal');

        if ~isempty(L) && L < max(info.gl)
            error('%s: One of the windows is longer than the transform length.',upper(mfilename));
        end;

        if isstruct(g{ii})
            if isfield(g{ii},'h')
                if ~isnumeric(g{ii}.h)
                    error('%s: g{ii}.h must be numeric',upper(mfilename));
                end
                % Normalize either in time or in the frequency domain

                if flags.do_freq
                    complain_L(L);
                    % Get frequency response and it's norm
                    H = comp_transferfunction(g2{ii},L);
                    [~,scal(ii)] = normalize(H,flags.norm);
                    g{ii}.h = g{ii}.h/scal(ii);
                else
                    if isfield(g{ii},'fc') && g{ii}.fc~=0
                        complain_L(L); % L is required to do a proper modulation
                    else
                        L = numel(g2{ii}.h);
                    end
                    % Get impulse response with all the fields applied
                    tmpg = comp_filterbank_pre(g2(ii),1,L,inf);
                    [~,scal(ii)] = normalize(tmpg{1}.h,flags.norm);
                     g{ii}.h = g{ii}.h/scal(ii);
                end
            elseif isfield(g{ii},'H')
                if isa(g{ii}.H,'function_handle')
                    complain_L(L);
                    H = comp_transferfunction(g2{ii},L);
                    if flags.do_freq
                        [~,scal(ii)] = normalize(H,flags.norm);
                        g{ii}.H = @(L) g{ii}.H(L)/scal(ii);
                    else
                        [~,scal(ii)] = normalize(ifft(H),flags.norm);
                        g{ii}.H = @(L) g{ii}.H(L)/scal(ii);
                    end
                elseif isnumeric(g{ii}.H)
                    if ~isfield(g{ii},'L')
                        error('%s: g.H is numeric, but .L field is missing',...
                        upper(mfilename));
                    end
                    if isempty(L)
                        L = g{ii}.L;
                    else
                        if L ~= g{ii}.L
                            error('%s: L and g.L are not equal',...
                            upper(mfilename));
                        end
                    end

                    H = comp_transferfunction(g2{ii},L);
                    if flags.do_freq
                        [~,scal(ii)] = normalize(H,flags.norm);
                        g{ii}.H = g{ii}.H/scal(ii);
                    else
                        [~,scal(ii)] = normalize(ifft(H),flags.norm);
                        g{ii}.H = g{ii}.H/scal(ii);
                    end
                end
            else
                  error('%s: SENTINEL. Unrecognized filter struct format',...
                  upper(mfilename));
            end
        elseif isnumeric(g{ii})
            % This one is not so easy
            if flags.do_freq
                complain_L(L);
                % We must use g2 here
                [~, scal(ii)] = normalize(fft(g2{ii}.h,L),flags.norm);
                g{ii} = g{ii}/scal(ii);
            else
                [g{ii}, scal(ii)] = normalize(g{ii},flags.norm);
            end
        else
            error('%s: SENTINEL. Unrecognized filter format',...
            upper(mfilename));
        end
    end
    % Convert to a scaling factor
    scal = 1./scal;
end

function complain_L(L)

if isempty(L)
     error('%s: L must be specified',upper(mfilename));
end

complainif_notposint(L,'L',mfilename)

