function Ft=frametight(F);
%-*- texinfo -*-
%@deftypefn {Function} frametight
%@verbatim
%FRAMETIGHT  Construct the canonical tight frame
%   Usage: Ft=frametight(F);
%
%   Ft=FRAMETIGHT(F) returns the canonical tight frame of F.
%
%   The canonical tight frame can be used to get perfect reconstruction if
%   it is used for both analysis and synthesis. This is demonstrated in the
%   following example:
%
%     % Create a frame and its canonical tight
%     F=frame('dgt','hamming',32,64);
%     Ft=frametight(F);
%
%     % Compute the frame coefficients and test for perfect
%     % reconstruction
%     f=gspi;
%     c=frana(Ft,f);
%     r=frsyn(Ft,c);
%     norm(r(1:length(f))-f)
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/frames/frametight.html}
%@seealso{frame, framepair, framedual}
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
  
complainif_notenoughargs(nargin,1,'FRAMETIGHT');
complainif_notvalidframeobj(F,'FRAMETIGHT');

% Default operation, works for a lot of frames
Ft=F;

% Handle the windowed transforms
switch(F.type)
  case {'dgt','dgtreal','dwilt','wmdct','filterbank','ufilterbank',...
        'nsdgt','unsdgt','nsdgtreal','unsdgtreal'}
    
    Ft=frame(F.type,{'tight',F.g},F.origargs{2:end});
    
  case {'filterbankreal','ufilterbankreal'}
    Ft=frame(F.type,{'realtight',F.g},F.origargs{2:end});
    
  case 'gen'
    [U,sv,V] = svd(F.g,'econ');    
    Ft=frame('gen',U*V');

  case 'tensor'
    for ii=1:F.Nframes
        tight_frames{ii}=frametight(F.frames{ii});
    end;
    F=frame('tensor',tight_frames{:});

  case 'fusion'
    tight_w=1./F.w;
    for ii=1:F.Nframes
        tight_frames{ii}=frametight(F.frames{ii});
    end;
    Ft=frame('fusion',tight_w,tight_frames{:});
    
  case 'ufwt'
    % The canonical tight made from ufwt might not keep the iterated
    % filterbank structure
    [g,a] = wfbt2filterbank({F.g,F.J,'dwt'});
    g = comp_filterbankscale(g,a,F.flags.scaling);
    
    Ft = frametight(frame('filterbank',g,ones(numel(g),1),numel(g)));
                 
  case 'uwfbt'
    % The canonical tight made from uwfbt might not keep the iterated
    % filterbank structure
    [g,a] = wfbt2filterbank(F.g,F.J);
    g = comp_filterbankscale(g,a,F.flags.scaling);
    
    Ft = frametight(frame('filterbank',g,ones(numel(g),1),numel(g)));
                 
  case 'uwpfbt'               
    % The canonical tight made from uwpfbt might not keep the iterated
    % filterbank structure
    [g, a] = wpfbt2filterbank(F.g,F.flags.interscaling);
    g = comp_filterbankscale(g,a,F.flags.scaling);
    
    Ft = frametight(frame('filterbank',g,ones(numel(g),1),numel(g)));
      
  case 'fwt'
    is_basis = abs(sum(1./F.g.a)-1)<1e-6;
    is_tight = F.info.istight;

    if is_basis && is_tight
        Ft = F;
    else
        error(['%s: Cannot create the canonical tight frame with the ',...
               'same structure. Consider casting the system to an ',...
               'uniform filterbank.'],...
               upper(mfilename)); 
    end
    
  case 'wfbt'
    is_basis = all(cellfun(@(nEl) abs(sum(1./nEl.a)-1)<1e-6,F.g.nodes));
    is_tight = F.info.istight;               
    
    if is_basis && is_tight
        Ft = F;
    else
        error(['%s: Cannot create the canonical tight frame with the ',...
               'same structure. Consider casting the system to an ',...
               'uniform filterbank.'],...
               upper(mfilename)); 
    end
       
   case 'wpfbt'
     % WPFBT is too wierd.
     error(['%s: Canonical tight frame of wpfbt might not keep the ',...
           'same structure. '],upper(mfilename))

      
end;


switch(F.type)
    case {'ufwt','uwfbt','uwpfbt'}
      warning(sprintf(['%s: The canonical tight system does not preserve ',...
                     'the iterated filterbank structure.'],...
                      upper(mfilename)));   
end


% Treat the fixed length frames
if isfield(F,'fixedlength') && F.fixedlength && isfield(F,'L')
   Ft = frameaccel(Ft,F.L);
   Ft.fixedlength = 1;
end


