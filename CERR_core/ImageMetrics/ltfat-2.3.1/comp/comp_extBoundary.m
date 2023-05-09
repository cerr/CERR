function fout = comp_extBoundary(f,extLen,ext,varargin)
%-*- texinfo -*-
%@deftypefn {Function} comp_extBoundary
%@verbatim
%EXTENDBOUNDARY Extends collumns
%    Usage: fout = comp_extBoundary(f,extLen,ext); 
%           fout = comp_extBoundary(f,extLen,ext,'dim',dim);
%
%   Input parameters:
%         f          : Input collumn vector/matrix
%         extLen     : Length of extensions
%         ext        : Type of extensions
%   Output parameters:
%         fout       : Extended collumn vector/matrix
%
%   Extends input collumn vector or matrix f at top and bottom by 
%   extLen elements/rows. Extended values are determined from the input
%   according to the type of extension ext.
%
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/comp/comp_extBoundary.html}
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


 if(ndims(f)>2)
     error('%s: Multidimensional signals (d>2) are not supported.',upper(mfilename));
 end

definput.flags.ext = {'per','ppd','perdec','odd','even','sym','asym',...
                      'symw','asymw','zero','zpd','sp0'};
definput.keyvals.a = 2;
definput.keyvals.dim = [];
[flags,kv,a]=ltfatarghelper({'a'},definput,varargin);

% How slow is this?
[f,L,Ls,W,dim,permutedsize,order]=assert_sigreshape_pre(f,[],kv.dim,upper(mfilename));


fout = zeros(size(f,1) + 2*extLen,size(f,2),assert_classname(f));
fout(extLen+1:end-extLen,:) = f;

legalExtLen = min([size(f,1),extLen]);
timesExtLen = floor(extLen/size(f,1));
moduloExtLen = mod(extLen,size(f,1));

% zero padding by default
% ext: 'per','zpd','sym','symw','asym','asymw','ppd','sp0'
if(strcmp(ext,'perdec')) % possible last samples replications
    moda = mod(size(f,1),a);
    repl = a-moda;
    if(moda)
        % version with replicated last sample
        fout(end-extLen+1:end-extLen+repl,:) = f(end,:);
        fRepRange = 1+extLen:extLen+length(f)+repl;
        fRep = fout(fRepRange,:);
        fRepLen = length(fRepRange);
        timesExtLen = floor(extLen/fRepLen);
        moduloExtLen = mod(extLen,fRepLen);

        fout(1+extLen-timesExtLen*fRepLen:extLen,:) = repmat(fRep,timesExtLen,1);
        fout(1:moduloExtLen,:) = fRep(end-moduloExtLen+1:end,:);
        
        timesExtLen = floor((extLen-repl)/fRepLen);
        moduloExtLen = mod((extLen-repl),fRepLen);
        fout(end-extLen+repl+1:end-extLen+repl+timesExtLen*fRepLen,:) = repmat(fRep,timesExtLen,1);
        fout(end-moduloExtLen+1:end,:) = f(1:moduloExtLen,:);
        
        %fout(rightStartIdx:end-extLen+timesExtLen*length(f)) = repmat(f(:),timesExtLen,1);
        %fout(1+extLen-legalExtLen:extLen-repl)= f(end-legalExtLen+1+repl:end);
    else
        fout = comp_extBoundary(f,extLen,'per',varargin{:});
       % fout(1+extLen-legalExtLen:extLen) = f(end-legalExtLen+1:end);
       % fout(1:extLen-legalExtLen) = f(end-(extLen-legalExtLen)+1:end);
       % fout(end-extLen+1:end-extLen+legalExtLen) = f(1:legalExtLen);
    end
elseif(strcmp(ext,'per') || strcmp(ext,'ppd'))
       % if ext > length(f)
       fout(1+extLen-timesExtLen*size(f,1):extLen,:) = repmat(f,timesExtLen,1);
       fout(end-extLen+1:end-extLen+timesExtLen*size(f,1),:) = repmat(f,timesExtLen,1);
       %  mod(extLen,length(f)) samples are the rest
       fout(1:moduloExtLen,:) = f(end-moduloExtLen+1:end,:);
       fout(end-moduloExtLen+1:end,:) = f(1:moduloExtLen,:);
elseif(strcmp(ext,'sym')||strcmp(ext,'even'))
    fout(1+extLen-legalExtLen:extLen,:) = f(legalExtLen:-1:1,:);
    fout(end-extLen+1:end-extLen+legalExtLen,:) = f(end:-1:end-legalExtLen+1,:);
elseif(strcmp(ext,'symw'))
    legalExtLen = min([size(f,1)-1,extLen]);
    fout(1+extLen-legalExtLen:extLen,:) = f(legalExtLen+1:-1:2,:);
    fout(end-extLen+1:end-extLen+legalExtLen,:) = f(end-1:-1:end-legalExtLen,:);
elseif(strcmp(ext,'asym')||strcmp(ext,'odd'))
    fout(1+extLen-legalExtLen:extLen,:) = -f(legalExtLen:-1:1,:);
    fout(end-extLen+1:end-extLen+legalExtLen,:) = -f(end:-1:end-legalExtLen+1,:);
elseif(strcmp(ext,'asymw'))
    legalExtLen = min([size(f,1)-1,extLen]);
    fout(1+extLen-legalExtLen:extLen,:) = -f(legalExtLen+1:-1:2,:);
    fout(end-extLen+1:end-extLen+legalExtLen,:) = -f(end-1:-1:end-legalExtLen,:);
elseif(strcmp(ext,'sp0'))
    fout(1:extLen,:) = f(1,:);
    fout(end-extLen+1:end,:) = f(end,:);
elseif(strcmp(ext,'zpd')||strcmp(ext,'zero')||strcmp(ext,'valid'))
    % do nothing
else
    error('%s: Unsupported flag.',upper(mfilename));
end

% Reshape back according to the dim.
permutedsizeAlt = size(fout);
fout=assert_sigreshape_post(fout,dim,permutedsizeAlt,order);

