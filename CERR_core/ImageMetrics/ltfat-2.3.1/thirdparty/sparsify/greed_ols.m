function [s, err_mse, iter_time]=greed_ols(x,A,m,varargin)
%-*- texinfo -*-
%@deftypefn {Function} greed_ols
%@verbatim
% greed_ols: Orthogonal Least Squares algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage
%   [s, err_mse, iter_time]=greed_ols(x,P,m,'option_name','option_value');
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
%                       NOTE: The algorithm works on matrices, so P will be
%                       converted to matrix. This means that the algorithm
%                       only works for small problems.
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
%   maxIter         POSITIVE INTEGER (SEE BELOW)                n
%   verbose         TRUE, FALSE                                 false
%   start_val       VECTOR OF LENGTH M                          zeros
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
%   maxIter: Maximum of allowed iterations.
%
%   verbose: Logical value to allow algorithm progress to be displayed.
%
%   start_val: Allows algorithms to start from partial solution.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs
%    s              Solution vector 
%    err_mse        Vector containing mse of approximation error for each 
%                   iteration
%    iter_time      Vector containing times for each iteration
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description
%   greed_ols performs a greedy signal decomposition. 
%   In each iteration a new element is selected that will reduce the 
%   residual error the most in the next step. This is different from OMP.
%   See [1] and [2] for details.
%   The non-zero elements of s are approximated by orthogonally projecting 
%   x onto the selected elements in each iteration.
%   The algorithm uses QR factorisation.
%   
% References
%   [1] S. Chen and S. A. Billings Modelling and analysis of non-linear time series. 
%	International Journal of Control, 50 pp. 2151-2171, 1989
%   [2] T. Blumensath, M. E. Davies; "On the Difference Between Orthogonal Matching Pursuit and %       Orthogonal Least Squares", manuscript 2007
%
% See Also
%   greed_omp, greed_mp, greed_gp, greed_nomp, greed_pcgp
%
% Copyright (c) 2007 Thomas Blumensath
%
% The University of Edinburgh
% Email: thomas.blumensath@ed.ac.uk
% Comments and bug reports welcome
%
% This file is part of sparsity Version 0.1
% Created: April 2007
%
% Part of this toolbox was developed with the support of EPSRC Grant
% D000246/1
%
% Please read COPYRIGHT.m for terms and conditions.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/thirdparty/sparsify/greed_ols.html}
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
        case {'maxIter'}
            if isa(Options{i+1},'numeric'); MAXITER     = Options{i+1};             
            else error('maxIter must be a number. Exiting.'); end
        case {'verbose'}
            if isa(Options{i+1},'logical'); verbose     = Options{i+1};   
            else error('verbose must be a logical. Exiting.'); end 
        case {'start_val'}
            if isa(Options{i+1},'numeric') & length(Options{i+1}) == m ;
                s_initial     = Options{i+1};  
                initial_given=1;
            else error('start_val must be a vector of length m. Exiting.'); end
        case {'P_trans'}
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
%                        Make P a matrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isa(A,'float')
    P = A;
elseif      isobject(A)
    try P=zeros(n,m);
    catch error('Problem size too large for this algorithm.')
    end
    for i=1:m
        mask=zeros(m);
        mask(i)=1;
        P(:,i) = A*mask;
        P(:,i) = P(:,i) / norm(P(:,i));
    end
elseif isa(A,'function_handle')
    try P=zeros(n,m);
    catch error('Problem size too large for this algorithm.')
    end
    for i=1:m
        mask=zeros(m);
        mask(i)=1;
        P(:,i) = A(mask);
        P(:,i) = P(:,i) / norm(P(:,i));
    end
else
    error('P is of unsupported type. Use matrix, function handle or object. Exiting.') 
end

% Make a copy of A
A=P;


try R=zeros(m);
catch error('Problem size too large for this algorithm.')
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Do we start from zero or not?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



if initial_given == 1;
    in=find(s_initial);
    IN=[];
    NI=1:m;
    z=[];
    for i=length(in):-1:1 %Go backwards so that we can take of elements in NI from the rear.
            INI=in(i);
            IN=[IN INI];
            NI(INI)=[];
            R(INI,INI)= norm(A(:,INI));
            A(:,INI)=A(:,INI)/R(INI,INI);
            for k=1:length(NI)
                 R(INI,NI(k))  =  A(:,INI)'* A(:,NI(k));
                 A(:,NI(k)) = A(:,NI(k)) - R(INI,NI(k)) * A(:,INI);
            end
            % New coefficient in Q domain
            zn=A(:,INI)'*x;
            z=[z ; zn];
        end
        Residual    = x-A(:,IN)*z;
        oldERR      = Residual'*Residual/n;
        s           = s_initial;
else
    IN=[];
    NI=1:m;
    Residual=x;
    z=[];
    oldERR      = sigsize;
    s           = s_initial;
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Main algorithm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if verbose
   display('Main iterations...') 
end
tic
t=0;
DR=A'*Residual;
done = 0;
iter=1;
while ~done
    % select new element
     normA=(sum(A.^2,1)).^0.5;
     [v I]=max(abs(DR(NI))./normA(NI)');
     INI=NI(I);
     IN=[IN INI];
     NI(I)=[];
    
    % Update QR factorisation and non-selected elements
    % We here overwrite those columns of A in IN with the matrix Q and
    % overwrite the other columns so that they are orthogonal to the
    % elements in Q.
    
    % One step of QR
     R(INI,INI)= norm(A(:,INI));
     A(:,INI)=A(:,INI)/R(INI,INI);
     
     for k=1:length(NI)
         R(INI,NI(k))  =  A(:,INI)'* A(:,NI(k));
         A(:,NI(k)) = A(:,NI(k)) - R(INI,NI(k)) * A(:,INI);
     end
     

     % New coefficient in Q domain
     zn=A(:,INI)'*x;
     z=[z ; zn];
     
    % New Residual and inner products
     Residual=Residual-zn*A(:,INI);
     DR=A'*Residual;
     
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
         if iter >= STOPTOL
             done =1;
         elseif verbose && toc-t>10
            display(sprintf('Iteration %i. --- %i iterations to go',iter ,STOPTOL-iter)) 
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
             if oldERR<1e-16
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
%            Now we can solve for s by back-substitution
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 s(IN)=R(IN,IN)\z;
 
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


