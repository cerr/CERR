function [xo]=elitistthresh(xi,lambda,varargin)
%-*- texinfo -*-
%@deftypefn {Function} elitistthresh
%@verbatim
%ELITISTTHRESH   elitist (hard/soft) thresholding
%   Usage:  xo=elitistthresh(xi,lambda);
%
%   ELITISTTHRESH(xi,lambda) performs hard elitist thresholding on xi,
%   with threshold lambda. The input xi must be a two-dimensional array,
%   the first dimension labelling groups, and the second one labelling
%   members.  All coefficients within a given group are shrunk according to
%   the value of the l^1 norm of the group in comparison to the threshold
%   value lambda.
%
%   ELITISTTHRESH(x,lambda,'soft') will do the same using soft
%   thresholding.
%
%   ELITISTTHRESH accepts the following flags at the end of the line of input
%   arguments:
%
%     'hard'    Perform hard thresholding. This is the default.
%
%     'soft'    Perform soft thresholding.  
%
%     'full'    Return the output as a full matrix. This is the default.
%
%     'sparse'  Return the output as a sparse matrix.
%  
%
%
%   References:
%     M. Kowalski. Sparse regression using mixed norms. Appl. Comput. Harmon.
%     Anal., 27(3):303--324, 2009.
%     
%     M. Kowalski and B. Torresani. Sparsity and persistence: mixed norms
%     provide simple signal models with dependent coefficients. Signal, Image
%     and Video Processing, 3(3):251--264, 2009.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/elitistthresh.html}
%@seealso{groupthresh, demo_audioshrink}
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

%   AUTHOR : Bruno Torresani.  
 
if nargin<2
  error('Too few input parameters.');
end;

if (prod(size(lambda))~=1 || ~isnumeric(lambda))
  error('lambda must be a scalar.');
end;

% Define initial value for flags and key/value pairs.
definput.flags.iofun={'hard','soft'};
definput.flags.outclass={'full','sparse'};

[flags,keyvals]=ltfatarghelper({},definput,varargin,mfilename);

NbGroups = size(xi,1);
NbMembers = size(xi,2);

if flags.do_sparse
  xo = sparse(size(xi));
else
  xo = zeros(size(xi));
end;

for g=1:NbGroups,
    y = sort(abs(xi(g,:)),'descend');
    rhs = cumsum(y);
    rhs = rhs .* lambda ./ (1 + lambda * (1:NbMembers));
    M_g = find(diff(sign(y-rhs)));
    if (M_g~=0)
        tau_g = lambda * norm(y(1:M_g),1)/(1+lambda*M_g);
    else
        tau_g = 0;
    end
    xo(g,:) = thresh(xi(g,:),tau_g,flags.iofun,flags.outclass);
end

