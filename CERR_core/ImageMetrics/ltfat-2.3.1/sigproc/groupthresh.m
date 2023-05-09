function [xo]=groupthresh(xi,lambda,varargin)
%-*- texinfo -*-
%@deftypefn {Function} groupthresh
%@verbatim
%GROUPTHRESH   Group thresholding
%   Usage:  xo=groupthresh(xi,lambda);
%
%   GROUPTHRESH(x,lambda) performs group thresholding on x, with
%   threshold lambda.  x must be a two-dimensional array, the first
%   dimension labelling groups, and the second one labelling members. This
%   means that the groups are the row vectors of the input (the vectors
%   along the 2nd dimension).
%
%   Several types of grouping behaviour are available:
%
%    GROUPTHRESH(x,lambda,'group') shrinks all coefficients within a given
%     group according to the value of the l^2 norm of the group in
%     comparison to the threshold lambda. This is the default.
%
%    GROUPTHRESH(x,lambda,'elite') shrinks all coefficients within a
%     given group according to the value of the l^1 norm of the
%     group in comparison to the threshold value lambda.
%
%   GROUPTHRESH(x,lambda,dim) chooses groups along dimension
%   dim. The default value is dim=2.
%
%   GROUPTHRESH accepts all the flags of THRESH to choose the
%   thresholding type within each group and the output type (full / sparse
%   matrix). Please see the help of THRESH for the available
%   options. Default is to use soft thresholding and full matrix output.
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
%     G. Yu, S. Mallat, and E. Bacry. Audio Denoising by Time-Frequency Block
%     Thresholding. IEEE Trans. Signal Process., 56(5):1830--1839, 2008.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/sigproc/groupthresh.html}
%@seealso{thresh, demo_audioshrink}
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

%   AUTHOR : Kai Siedenburg, Bruno Torresani.
%   REFERENCE: OK
 

if nargin<2
  error('Too few input parameters.');k
end;

if (prod(size(lambda))~=1 || ~isnumeric(lambda))
  error('lambda must be a scalar.');
end;

% Define initial value for flags and key/value pairs.
definput.import={'thresh','groupthresh'};
definput.importdefaults={'soft'};
definput.keyvals.dim=2;

[flags,keyvals,dim]=ltfatarghelper({'dim'},definput,varargin);

% kv.dim (the time or frequency selector) is handled by assert_sigreshape_pre
[xi,L,NbMembers,NbGroups,dim,permutedsize,order]=assert_sigreshape_pre(xi,[],dim,'GROUPTHRESH');

if flags.do_sparse
  xo = sparse(size(xi));
else
  xo = zeros(size(xi));
end;

if flags.do_group
  
  groupnorm = sqrt(sum(abs(xi).^2));
  w = thresh(groupnorm, lambda, flags.iofun,flags.outclass)./groupnorm;
  
  % Clean w for NaN. NaN appears if the input has a group with norm
  % exactly 0.
  w(isnan(w)) = 0;
  
  xo = bsxfun(@times,xi,w);

end

if flags.do_elite  
  for ii=1:NbGroups,
    y = sort(abs(xi(:,ii)),'descend');
    rhs = cumsum(y);
    rhs = rhs .* lambda ./ (1 + lambda * (1:NbMembers)');
    M_ii = find(diff(sign(y-rhs)));
    if (M_ii~=0)
      tau_ii = lambda * norm(y(1:M_ii),1)/(1+lambda*M_ii);
    else
      tau_ii = 0;
    end        
    
    % FIXME: The following line does not work for sparse matrices.
    xo(:,ii) = thresh(xi(:,ii),tau_ii,flags.iofun,flags.outclass);
  end
end;

xo=assert_sigreshape_post(xo,dim,permutedsize,order);


