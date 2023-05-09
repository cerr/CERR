function [f,relres,iter]=ifilterbankiter(c,g,a,varargin)
%-*- texinfo -*-
%@deftypefn {Function} ifilterbankiter
%@verbatim
%IFILTERBANKITER  Filter bank iterative inversion
%   Usage:  f=ifilterbankiter(c,g,a);
%
%   IFILTERBANKITER(c,g,a) iteratively synthesizes a signal f from the
%   coefficients c which were obtained using the filters stored in g for
%   a channel subsampling rate of a (the hop-size).
%
%   The filter bank g and the subsampling rate a must be the same
%   as used in FILTERBANK or UFILTERBANK.
%
%   This function is useful if there is no way how to explicitly compute
%   a dual system using FILTERBANKDUAL or FILTERBANKREALDUAL.
%
%   Additional parameters
%   ---------------------
%
%   The function calls FRSYNITER and passes all the optional arguments to it.
%   Please refer to help of FRSYNITER for further details.
%
%   Please note that by default, the function expects filterbank g*
%   to be created for real signals i.e. g cover only the positive frequencies.
%   Additional flag 'complex' is required if the filterbank is defined for 
%   positive and negative frequencies.
%
%   Examples:
%   ---------
%
%   The following example compares convergence rates of CG and PCG for a
%   filterbank which forms a frame, but it is neither uniform or painless:
%
%       [f,fs] = greasy; L = size(f,1);
%       [g,a,fc]=erbfilters(fs,L,'fractional','bwmul',0.6,'redmul',4/5,'complex');
%       filterbankfreqz(g,a,L,'plot','linabs');
%       % Filterbankdual does not work
%       try
%           gd=filterbankdual(g,a,L);
%       catch
%           disp('FILTERBANKDUAL exited with error.');
%       end
%
%       c = filterbank(f,g,a);
%       [fpcg,~,iterpcg] = ifilterbankiter(c,g,a,'complex','pcg');
%       [fcg,~,itercg] = ifilterbankiter(c,g,a,'complex','cg');
%
%       fprintf('CG achieved error %e in %d iterations.n',norm(f-fcg), itercg);
%       fprintf('PCG achieved error %e in %d iterations.n',norm(f-fpcg), iterpcg);
%
%   Similar example with real filterbank:
%
%       [f,fs] = greasy; L = size(f,1);
%       [g,a,fc]=erbfilters(fs,L,'fractional','bwmul',0.6,'redmul',4/5);
%       filterbankfreqz(g,a,L,'plot','linabs');
%       % Filterbankrealdual does not work
%       try
%           gd=filterbankrealdual(g,a,L);
%       catch
%           disp('FILTERBANKREALDUAL exited with error.');
%       end
%
%       c = filterbank(f,g,a);
%       [fpcg,~,iterpcg] = ifilterbankiter(c,g,a,'pcg');
%       [fcg,~,itercg] = ifilterbankiter(c,g,a,'cg');
%
%       fprintf('CG achieved error %e in %d iterations.n',norm(f-fcg), itercg);
%       fprintf('PCG achieved error %e in %d iterations.n',norm(f-fpcg), iterpcg);
%
%
%   References:
%     T. Necciari, P. Balazs, N. Holighaus, and P. L. Soendergaard. The ERBlet
%     transform: An auditory-based time-frequency representation with perfect
%     reconstruction. In Proceedings of the 38th International Conference on
%     Acoustics, Speech, and Signal Processing (ICASSP 2013), pages 498--502,
%     Vancouver, Canada, May 2013. IEEE.
%     
%     T. Necciari, N. Holighaus, P. Balazs, Z. Průša, P. Majdak, and
%     O. Derrien. Audlet filter banks: A versatile analysis/synthesis
%     framework using auditory frequency scales. Applied Sciences, 8(1),
%     2018. [1]http ]
%     
%     References
%     
%     1. http://www.mdpi.com/2076-3417/8/1/96
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/filterbank/ifilterbankiter.html}
%@seealso{filterbank, ufilterbank, ifilterbank, filterbankdual}
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

complainif_notenoughargs(nargin,3,'IFILTERBANKITER');

tolchooser.double=1e-9;
tolchooser.single=1e-5;

definput.keyvals.Ls=[];
definput.keyvals.tol=tolchooser.(class(c{1}));
definput.keyvals.maxit=100;
definput.flags.alg={'pcg','cg'};
definput.flags.real={'real','complex'};
[flags,kv,Ls]=ltfatarghelper({'Ls'},definput,varargin);

if flags.do_real
    F = frame('filterbankreal',g,a,numel(g));
else
    F = frame('filterbank',g,a,numel(g));
end

[f,relres,iter] = frsyniter(F,framenative2coef(F,c),'Ls',Ls,flags.alg,'maxit',kv.maxit,'tol',kv.tol);


