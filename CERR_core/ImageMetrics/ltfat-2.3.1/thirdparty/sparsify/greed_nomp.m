function [s, err_mse, iter_time]=greed_nomp(x,A,m,varargin)
%-*- texinfo -*-
%@deftypefn {Function} greed_nomp
%@verbatim
% greed_nomp: Nearly Orthogonal Matching Pursuit or Approximate Conjugate 
%             Gradient Pursuit algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage
%   [s, err_mse, iter_time]=greed_nomp(x,P,m,'option_name','option_value')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input
%   Mandatory:
%               x   Observation vector to be decomposed
%               P   Either:
%                       1) An nxm matrix (n must be dimension of x)
%                       2) A function handle (type "help function_format" 
%                          for more information)
%                          Also requires specification of P_trans option.
%                       3) An object handle (type "help object_format" for 
%                          more information)
%               m   length of s 
%
%   Possible additional options:
%   (specify as many as you want using 'option_name','option_value' pairs)
%   See below for explanation of options:
%__________________________________________________________________________
%   option_name         AVAILABLE OPTION_VALUES                 default
%--------------------------------------------------------------------------
%   stopCrit        M, CORR, MSE, MSE_CHANGE                    M
%   stopTol         NUMBER (SEE BELOW)                          n/4
%   P_trans         FUNCTION_HANDLE (SEE BELOW)                 
%   maxIter         POSITIVE INTEGER (SEE BELOW)                n
%   verbose         TRUE, FALSE                                 false
%   start_val       VECTOR OF LENGTH M                          zeros
%   GradSteps       'AUTO' OR INTEGER                           'auto'
%   wf              WEAKNES FACTOR [1 0)                        1
%
%   Available stopping criteria :
%               M           -   Extracts exactly M = stopTol elements.
%               corr        -   Stops when maximum correlation between
%                               residual and atoms is below stopTol value.
%               mse         -   Stops when mean squared error of residual 
%                               is below stopTol value.
%               mse_change  -   Stops when the change in the mean squared 
%                               error falls below stopTol value.
%
%   stopTol: Value for stopping criterion.
%
%   P_trans: If P is a function handle, then P_trans has to be specified and 
%            must be a function handle. 
%
%   maxIter: Maximum number of allowed iterations.
%
%   verbose: Logical value to allow algorithm progress to be displayed.
%
%   start_val: Allows algorithms to start from partial solution.
%
%   GradSteps: Number of gradient optimisation steps per iteration.
%              'auto' uses inner products to decide if more gradient steps 
%              are required. 
%
%   wf: weakness factor alpha (see [2] and [3]). Algorithm will select all 
%       elements fror which P_TRANS RESIDUAL >= alpha max(|P_trans residual|)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs
%    s              Solution vector 
%    err_mse        Vector containing mse of approximation error for each 
%                   iteration
%    iter_time      Vector containing computation times for each iteration
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description
%   greed_nomp performs a greedy signal decomposition. 
%   In each iteration a new element is selected depending on the inner
%   product between the current residual and columns in P.
%   A directional update is used that is conjuagte to the previously used
%   direction.
%   
%   THIS ALGORITHM IS AN ALTERNATIVE TO OMP IF OMP IS NOT FEASIBLE DUE TO
%   COMPUTATION TIME OR STORAGE REQUIREMENTS! IT IS IN GENERAL BETTER THAN
%   greed_gp
%   
% References
%   [1] T. Blumensath and M.E. Davies, "Gradient Pursuits", to appear in 
%       IEEE Transactions on Signal Processing
%   [2] M.E. Davies and T. Blumensath; "Faster & Greedier: algorithms for 
%       sparse reconstruction of large datasets ", invited paper to the 
%       third IEEE International Symposium on Communications, Control, and 
%       Signal Processing, St Julians, Malta, March 2008.
%   [3] T. Blumensath, M. E. Davies; "Fast greedy algorithms for large
%       sparse inverse problems", submitted to EUSIPCO, 2008
% See Also
%   greed_omp, greed_ols, greed_mp, greed_gp, greed_pcgp
%
% Copyright (c) 2007 Thomas Blumensath
%
% The University of Edinburgh
% Email: thomas.blumensath@ed.ac.uk
% Comments and bug reports welcome
%
% This file is part of sparsity Version 0.3
% Created: April 2007
%
% Part of this toolbox was developed with the support of EPSRC Grant
% D000246/1
%
% Please read COPYRIGHT.m for terms and conditions.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/thirdparty/sparsify/greed_nomp.html}
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    Default values and initialisation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



[n1 n2]=size(x);
if n2 == 1
    n=n1;
elseif n1 == 1
    x=x';
    n=n2;
else
   error('x must be a vector.');
end
    
sigsize     = x'*x/n;
initial_given=0;  
err_mse     = [];
iter_time   = [];
STOPCRIT    = 'M';
STOPTOL     = ceil(n/4);
MAXITER     = n;
verbose     = false;
s_initial   = zeros(m,1);
GradSteps   = 'auto';
alpha       = 1;
weakness    = 1;

if verbose
   display('Initialising...') 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           Output variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

switch nargout 
    case 3
        comp_err=true;
        comp_time=true;
    case 2 
        comp_err=true;
        comp_time=false;
    case 1
        comp_err=false;
        comp_time=false;
    case 0
        error('Please assign output variable.')        
    otherwise
        error('Too many output arguments specified')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       Look through options
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Put option into nice format
Options={};
OS=nargin-3;
c=1;
for i=1:OS
    if isa(varargin{i},'cell')
        CellSize=length(varargin{i});
        ThisCell=varargin{i};
        for j=1:CellSize
            Options{c}=ThisCell{j};
            c=c+1;
        end
    else
        Options{c}=varargin{i};
        c=c+1;
    end
end
OS=length(Options);
if rem(OS,2)
   error('Something is wrong with argument name and argument value pairs.') 
end
for i=1:2:OS
   switch Options{i}
        case {'stopCrit'}
            if (strmatch(Options{i+1},{'M'; 'corr'; 'mse'; 'mse_change'},'exact'));
                STOPCRIT    = Options{i+1};  
            else error('stopCrit must be char string [M, corr, mse, mse_change]. Exiting.'); end 
        case {'stopTol'}
            if isa(Options{i+1},'numeric') ; STOPTOL     = Options{i+1};   
            else error('stopTol must be number. Exiting.'); end
        case {'P_trans'} 
            if isa(Options{i+1},'function_handle'); Pt = Options{i+1};   
            else error('P_trans must be function _handle. Exiting.'); end
        case {'maxIter'}
            if isa(Options{i+1},'numeric'); MAXITER     = Options{i+1};             
            else error('maxIter must be a number. Exiting.'); end
        case {'wf'}
            if isa(Options{i+1},'numeric'); alpha       = Options{i+1}; 
                if alpha <1 weakness =0; else alpha =1; weakness = 1; end          
            else error('wf must be a number. Exiting.'); end
        case {'verbose'}
            if isa(Options{i+1},'logical'); verbose     = Options{i+1};   
            else error('verbose must be a logical. Exiting.'); end 
        case {'start_val'}
            if isa(Options{i+1},'numeric') && length(Options{i+1}) == m ;
                s_initial     = Options{i+1};   
                initial_given=1;
            else error('start_val must be a vector of length m. Exiting.'); end
        case {'GradSteps'}
            if isa(Options{i+1},'numeric') || strcmp(Options{i+1},'auto') ;
                GradSteps     = Options{i+1};   
            else error('start_val must be a vector of length m. Exiting.'); end
        otherwise
            error('Unrecognised option. Exiting.') 
   end
end




if strcmp(STOPCRIT,'M') 
    maxM=STOPTOL;
else
    maxM=MAXITER;
end

if nargout >=2
    err_mse = zeros(maxM,1);
end
if nargout ==3
    iter_time = zeros(maxM,1);
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Make P and Pt functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if          isa(A,'float')      P =@(z) A*z;  Pt =@(z) A'*z;
elseif      isobject(A)         P =@(z) A*z;  Pt =@(z) A'*z;
elseif      isa(A,'function_handle') 
    try
        if          isa(Pt,'function_handle'); P=A;
        else        error('If P is a function handle, Pt also needs to be a function handle. Exiting.'); end
    catch error('If P is a function handle, Pt needs to be specified. Exiting.'); end
else        error('P is of unsupported type. Use matrix, function_handle or object. Exiting.'); end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Do we start from zero or not?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if initial_given ==1;
    IN          = find(s_initial);
    Residual    = x-P(s_initial);
    s           = s_initial;
    oldERR      = Residual'*Residual/n;
else
    IN          = [];
    Residual    = x;
    s           = s_initial;
    sigsize     = x'*x/n;
    oldERR      = sigsize;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 Random Check to see if dictionary is normalised 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        mask=zeros(m,1);
        mask(ceil(rand*m))=1;
        nP=norm(P(mask));
        if abs(1-nP)>1e-3;
            display('Dictionary appears not to have unit norm columns.')
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Main algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if verbose
   display('Main iterations...') 
end
tic
t=0;
p=zeros(m,1);
DR=Pt(Residual);
[v I] = max(abs(DR));
if weakness ~= 1
    [vals inds] = sort(abs(DR),'descend');
    I=inds( find( vals >= alpha * v ) );
end
    
IN = union(IN,I);
if strcmp(STOPCRIT,'M') & length(IN) >= STOPTOL
    IN=IN(1:STOPTOL);
end
MASK=zeros(size(DR));
pDDp=1;
done = 0;
iter=1;

while ~done

    
    % Select new element
    if isa(GradSteps,'char')
        if strcmp(GradSteps,'auto')
             
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Iteration to automatic selection of the number of gradient steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%             finished=0;    
%             while ~finished
            % Update direction    
                 if iter==1
                     p(IN)=DR(IN);
                     Dp=P(p);
                 else
                     MASK(IN)=1;
                     PDR=P(DR.*MASK);
                     b=-Dp'*PDR/pDDp;
                     p(IN)=DR(IN) +b*p(IN);
                     Dp=PDR +b* Dp;
                 end
             % Step size
%                  Dp=P(p); % =P(DR(IN)) +b P(p(IN));
                 pDDp=Dp'*Dp;
                 a=Residual'*Dp/(pDDp);
             % Update coefficients   
                 s=s+a*p;
             % New Residual and inner products
                 Residual=Residual-a*Dp;
                 DR=Pt(Residual);
                 % select new element
                     [v I] = max(abs(DR));
                     if weakness ~= 1
                         [vals inds] = sort(abs(DR),'descend');
                         I=inds( find( vals >= alpha * v ) );
                     end
                     IN = union(IN,I);
                     if strcmp(STOPCRIT,'M') & length(IN) >= STOPTOL
                        IN=IN(1:STOPTOL);
                     end

%                  % Only if we select new element do we leave the loop    
%                      if isempty(find (IN==I, 1))
%                         IN=[IN I];
%                         finished=1;
%                      end
%             end
        else
            
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                           Is option known?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            error('Undefined option for GradSteps, use ''auto'' or an integer.')
        end
    elseif isa(GradSteps,'numeric') 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               Iteration for fixed number of gradient steps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
                
        % Do GradSteps gradient steps
        count=1;
        while count<=GradSteps
            % Update direction    
                 if iter==1
                     p(IN)=DR(IN);
                     Dp=P(p);
                 else
                     MASK(IN)=1;
                     PDR=P(DR.*MASK);
                     b=-Dp'*PDR/pDDp;
                     p(IN)=DR(IN) +b*p(IN);
                     Dp=PDR +b* Dp;
                 end
             % Step size
%                  Dp=P(p);   
                 pDDp=Dp'*Dp;
                 a=Residual'*Dp/(pDDp);
             % Update coefficients   
                 s=s+a*p;
             % New Residual and inner products
                 Residual=Residual-a*Dp;
                 DR=Pt(Residual);
                  count=count+1;
        end
             % select new element
                 [v I] = max(abs(DR));
                 if weakness ~= 1
                     [vals inds] = sort(abs(DR),'descend');
                     I=inds( find( vals >= alpha * v ) );
                 end
                 IN = union(IN,I);
                 if strcmp(STOPCRIT,'M') & length(IN) >= STOPTOL
                    IN=IN(1:STOPTOL);
                 end
                
     else
          error('Undefined option for GradSteps, use ''auto'' or an integer.')
     end


     ERR=Residual'*Residual/n;
     if comp_err
         err_mse(iter)=ERR;
     end
     
     if comp_time
         iter_time(iter)=toc;
     end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Are we done yet?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

     if strcmp(STOPCRIT,'M')
         if length(IN) >= STOPTOL
             done =1;
         elseif verbose && toc-t>10
            display(sprintf('Iteration %i. --- %i selected elements',iter ,length(IN))) 
            t=toc;
         end
    elseif strcmp(STOPCRIT,'mse')
         if comp_err
            if err_mse(iter)<STOPTOL;
                done = 1; 
            elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i mse',iter ,err_mse(iter))) 
                t=toc;
            end
         else
             if ERR<STOPTOL;
                done = 1; 
             elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i mse',iter ,ERR)) 
                t=toc;
             end
         end
     elseif strcmp(STOPCRIT,'mse_change') && iter >=2
         if comp_err && iter >=2
              if ((err_mse(iter-1)-err_mse(iter))/sigsize <STOPTOL);
                done = 1; 
             elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i mse change',iter ,(err_mse(iter-1)-err_mse(iter))/sigsize )) 
                t=toc;
             end
         else
             if ((oldERR - ERR)/sigsize < STOPTOL);
                done = 1; 
             elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i mse change',iter ,(oldERR - ERR)/sigsize)) 
                t=toc;
             end
         end
     elseif strcmp(STOPCRIT,'corr') 
          if max(abs(DR)) < STOPTOL;
             done = 1; 
          elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i corr',iter ,max(abs(DR)))) 
                t=toc;
          end
     end
     
    % Also stop if residual gets too small or maxIter reached
     if comp_err
         if err_mse(iter)<1e-16
             display('Stopping. Exact signal representation found!')
             done=1;
         end
     else


         if iter>1
             if ERR<1e-16
                 display('Stopping. Exact signal representation found!')
                 done=1;
             end
         end
     end

     if iter >= MAXITER
         display('Stopping. Maximum number of iterations reached!')
         done = 1; 
     end
     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    If not done, take another round
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
     if ~done
        iter=iter+1;
        oldERR=ERR;
     end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  Only return as many elements as iterations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargout >=2
    err_mse = err_mse(1:iter);
end
if nargout ==3
    iter_time = iter_time(1:iter);
end
if verbose
   display('Done') 
end


%
% Change history
% 9th of May: Set update direction to gradient for first iteration. 
%             Otherwise incorrect direction is used when initial vector is given. 
%
% 22 of November: Original code did not calculate b value correctly. This
%                 has now been fixed.
%
% 14 of December: Faster implementation using recursive calculation of Dp
%
%  4 of January: Implemented weak element selection. This allows the
%  algorithm to select more than a single element in each iteration.
%
% 8 of Februray: Algo does no longer stop if dictionary is not normaliesd.
%
% 29 of Februray: USed unon command to combine selected elements.

