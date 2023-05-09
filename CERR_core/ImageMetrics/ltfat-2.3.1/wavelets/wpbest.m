function [c,info] = wpbest(f,w,J,varargin)
%-*- texinfo -*-
%@deftypefn {Function} wpbest
%@verbatim
%WPBEST  Best Tree selection
%   Usage: c = wpbest(f,w,J,cost);
%          [c,info] = wpbest(...);
%
%   Input parameters:
%         f   : Input data.
%         w   : Wavelet Filterbank.
%         J   : Maximum depth of the tree.
%
%   Output parameters:
%         c     : Coefficients stored in a cell-array.
%         info  : Transform parameters struct.
%
%   [c,info]=WPBEST(f,w,J,cost) selects the best sub-tree info.wt from
%   the full tree with max. depth J, which minimizes the cost function.
%
%   Only one-dimensional input f is accepted. The supported formats of
%   the parameter w can be found in help for FWT. The format of the
%   coefficients c and the info struct is the same as in WFBT.
%
%   Please note that w should define orthonormal wavelet filters.
%
%   First, the depth J wavelet packet decomposition is performed using WPFBT.
%   Then the nodes are traversed in the breadth-first and bottom-up order
%   and the value of the cost function of the node input and cost of the
%   combined node outputs is compared. If the node input cost function value
%   is less than the combined output cost, the current node and all
%   possible descendant nodes are marked to be deleted, if not, the input is
%   assigned the combined output cost. At the end, the marked nodes are
%   removed and the resulting tree is considered to be a best basis (or
%   near-best basis) in the chosen cost function sense.
%
%   The cost parameter can be a cell array or an user-defined function handle.
%   accepting a single column vector. The cell array should consist of a
%   string, followed by a numerical arguments.
%   The possible formats are listed in the following text.
%
%   Additive costs:
%   ---------------
%
%   The additive cost E of a vector x is a real valued cost function
%   such that:
%
%   ..
%      E(x) = sum E(x(k)),
%              k
%
%   and E(0)=0. Given a collection of vectors x_i being coefficients in
%   orthonormal bases B_i, the best basis relative to E is the one for
%   which the E(x_i) is minimal.
%
%   Additive cost functions allows using the fast best-basis search algorithm
%   since the costs can be precomputed and combined cost of two vectors is
%   just a sum of their costs.
%
%   {'shannon'}
%      A cost function derived from the Shannon entropy:
%
%      ..
%         E_sh(x) = -sum |x(k)|^2 log(|x(k)|^2),
%                 k:x(k)~=0
%
%   {'log'}
%      A logarithm of energy:
%
%      ..
%         E_log(x) = sum log(|x(k)|^2),
%                  k:x(k)~=0
%
%   {'lpnorm',p}
%      Concentration in l^p norm:
%
%      ..
%         E_lp(x) = ( sum (|x(k)|^p) ),
%                      k
%
%   {'thre',th}
%      Number of coefficients above a threshold th.
%
%
%   Non-additive costs:
%   -------------------
%
%   Cost function, which is not additive cost but which is used for the
%   basis selection is called a non-additive cost. The resulting basis for
%   which the cost is minimal is called near-best, because the non-additive
%   cost cannot guarantee the selection of a best basis relative to the
%   cost function.
%
%   {'wlpnorm',p}
%      The weak-l^p norm cost function:
%
%      ..
%         E_wlp(x) = max k^{\frac{1}{p}}v_k(x),
%
%      where 0<p<= 2 and v_k(x) denotes the k*-th largest absolute value
%      of x.
%
%   {'compn',p,f}
%      Compression number cost:
%
%      ..
%         E_cn(x) = arg min |w_k(x,p) - f|,
%                     k
%
%      where 0<p<= 2, 0<f<1 and w_k(u,p) denotes decreasingly sorted,
%      powered, cumulateively summed and renormalized vector:
%
%                     k              N
%         w_k(x,p) = sum v_j^p(x) / sum v_j^p(x)
%                    j=1            j=1
%
%      where v_k(x) denotes the k*-th largest absolute value of x and
%      N is the number of elements of x.
%
%   {'compa',p}
%      Compression area cost:
%
%      ..
%         E_ca(x) = N - sum w_k(x,p),
%                        k
%
%      where 0<p<= 2 and w_k(u,p) and N as in the previous case.
%
%   Examples:
%   ---------
%
%   A simple example of calling WPBEST :
%
%     f = gspi;
%     J = 8;
%     [c,info] = wpbest(f,'sym10',J,'cost','shannon');
%
%     % Use 2/3 of the space for the first plot, 1/3 for the second.
%     subplot(3,3,[1 2 4 5 7 8]);
%     plotwavelets(c,info,44100,90);
%
%     subplot(3,3,[3 6 9]);
%     N=cellfun(@numel,c); L=sum(N); a=L./N;
%     plot(a,'o');
%     xlim([1,numel(N)]);
%     view(90,-90);
%     xlabel('Channel no.');
%     ylabel('Subsampling rate / samples');
%
%   References:
%     M. V. Wickerhauser. Lectures on wavelet packet algorithms. In INRIA
%     Lecture notes. Citeseer, 1991.
%     
%     C. Taswell. Near-best basis selection algorithms with non-additive
%     information cost functions. In Proceedings of the IEEE International
%     Symposium on Time-Frequency and Time-Scale Analysis, pages 13--16. IEEE
%     Press, 1994.
%     
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/wavelets/wpbest.html}
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

% AUTHOR: Zdenek Prusa

complainif_notenoughargs(nargin,3,'WPBEST');
complainif_notposint(J,'J','WPBEST');

if numel(nonzeros(size(f)>1))>1
   error('%s: Function accepts only single channel inputs.',upper(mfilename));
end

definput.import = {'fwt','wfbtcommon'};
definput.flags.buildOrder = {'bottomup','topdown'};
definput.flags.bestWhat = {'tree','level'};
definput.keyvals.cost = {'shannon'};
[flags,kv]=ltfatarghelper({'cost'},definput,varargin);


if flags.do_topdown
    error('%s: Flag %s not supported yet.',upper(mfilename),flags.buildOrder);
end

if flags.do_level
    error('%s: Flag %s not supported yet.',upper(mfilename),flags.bestWhat);
end

if(~iscell(kv.cost))
   kv.cost = {kv.cost};
end

% test if the chosen entropy measure is additive
do_additive = isAdditive(kv.cost);

if(flags.do_bottomup)
   % Do full-tree Wavelet Packet decomposition beforehand and prune.
   [c,info] = wpfbt(normalize(f,'2'),{w,J,'full'},'nat',flags.ext,'intnoscale');

   % Nodes in the reverse BF order
   treePath = fliplr(nodeBForder(0,info.wt));
   % Relationships between nodes
   [pOutIdxs,chOutIdxs] = treeWpBFrange(info.wt);
   % Nodes to be removed
   removeNodes = [];

   % Energy normalization
   % totalE = sum(cellfun(@(cEl) sum(cEl.^2),c));
   % c = cellfun(@(cEl) cEl.^2/totalE,c,'UniformOutput',0);
   
   % pre-calculate entropy of all subbands
   cEnt = cellfun(@(cEl) wcostwrap(cEl,kv.cost,0),c);
   if do_additive
       for ii=1:length(pOutIdxs)-1
          pEnt = cEnt(pOutIdxs(ii));
          chEnt = sum(cEnt(chOutIdxs{ii}));
          if pEnt<=chEnt
             removeNodes(end+1) = treePath(ii);
          else
             % Set parent entropy to the sum of the children entropy.
             cEnt(pOutIdxs(ii)) = chEnt;
          end
       end
   else
       for ii=1:length(pOutIdxs)-1
          pEnt = cEnt(pOutIdxs(ii));
          chEnt = wcostwrap(c(chOutIdxs{ii}),kv.cost,0);
          % Set parent entropy to value obtanied by concatenating child
          % subbands.
          if(pEnt<=chEnt)
             removeNodes(end+1) = treePath(ii);
          else
             % Search the pOutIdxs(ii) in chOutIdxs
             % There should be the only one..
             foundId = cellfun(@(chEl)find(chEl==pOutIdxs(ii)),chOutIdxs,...
                               'UniformOutput',0);
             chId = find(~cellfun(@isempty,foundId));
             chOutIdxs{chId}(chOutIdxs{chId} == pOutIdxs(ii)) = [];
             chOutIdxs{chId} = [chOutIdxs{chId},chOutIdxs{ii}];
          end

       end
   end


   % Do tree prunning.
   for ii=1:length(removeNodes)
       [info.wt] = nodeSubtreeDelete(removeNodes(ii),info.wt);
   end

end

% Finally do the analysis using the created best tree. with correct
% frequency bands order
[c,info] = wfbt(f,info.wt,flags.ext,flags.forder);
%END WPBEST

function ad = isAdditive(entFunc)
x = 1:5;
%x = x./norm(x);
ent1 = wcostwrap(x',entFunc,0);
ent2 = sum(arrayfun(@(xEl) wcostwrap(xEl,entFunc,0),x));
ad = ent1==ent2;

function E = wcostwrap(x,fname,do_normalization)
%WENTWRAP Entropy functions wrapper
%   Usage:  E = wentwrap(x,fname,varargin)
%
%   `E = wentwrap(x,fname,varargin)` passes given parameters further to the
%   appropriate function.
%

if iscell(x)
   x = cell2mat(x);
end

if do_normalization
   x = x./norm(x);
end

if isa(fname,'function_handle')
   E = fname(x);
   return;
end

if numel(fname)>1
   E = feval(sprintf('%s%s','wcost_',fname{1}),x,fname{2:end});
else
   E = feval(sprintf('%s%s','wcost_',fname{1}),x);
end

%%%%%%%%%%%%%%%%%%
% ADDITIVE COSTS %
%%%%%%%%%%%%%%%%%%

function E = wcost_shannon(x)
% Cost function derived from the Shannon-Weaver entropy.

u = abs(x(x~=0)).^2;
E = -sum(u.*log(u));

function E = wcost_log(x)
% Logarithm of energy.
% It may be interpreted as the entropy of a Gauss-Markov process, composed
% of numel(x) uncorrelated Gaussian random variables of variences
% x(1),..,x(end). Minimizing the function finds the best approximation to
% the Karhuen-loeve basis for the process.

x = x(x~=0);
E = sum(log(x(:).^2));

function E = wcost_thre(x,th)
% Number of coefficients above a treshold.
% It gives a number of coefficients needed to transimt the signal to
% precision th.

E = numel(x(abs(x)>th));

function E = wcost_lpnorm(x,p)
% Concentration in l^p norm, p<2
% The smaller is the l^p norm of a signal with l^2 equal to 1, the more
% concentrated is its energy into a few coefficients.
assert(0<p&&p<2,'%s: Parameter p have to be in the range ]0,2[',upper(mfilename));
E = sum(abs(x(:)).^p);

%%%%%%%%%%%%%%%%%%%%%%
% NON-ADDITIVE COSTS %
%%%%%%%%%%%%%%%%%%%%%%

function E = wcost_wlpnorm(x,p)
% Weak Lp-norm

v = sort(abs(x(:)),'descend');

k = 1:length(v);
E = max((k.'.^(1/p)).*v);

function E = wcost_compa(x,p)
% Compresion Area Entropy, p<2
%

% 0<p<=2
assert(0<p&&p<=2,'Parameter p have to be in the range ]0,2]');
N = numel(x);
%u = x./norm(x);
v = sort(abs(x(:)),'descend');

wnom = cumsum(v.^p);
w = wnom./wnom(end);

E=N-sum(w);

function E = wcost_compn(x,p,f)
% Compresion Number entropy
% Represents a minimum number of coefficients containing 100*f% of the total
% p norm of x.


% 0<p<=2
assert(0<p&&p<=2,'Parameter p have to be in the range ]0,2]');
assert(0<f&&f<1,'Parameter f  have to be in the range ]0,1[');

%u = x./norm(x);
v = sort(abs(x(:)),'descend');

wnom = cumsum(v.^p);
w = wnom./wnom(end);

[~,E]=min(abs(w-f));



