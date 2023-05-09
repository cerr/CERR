function [s, err_cost, iter_time]=nonlin_gg(x,F,C,m,varargin)
%-*- texinfo -*-
%@deftypefn {Function} nonlin_gg
%@verbatim
% nonlin_gg: Nonlinear sparse approximation by greedy gradient search.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage
% [s, err_cost, iter_time]=nonlin_gg(x,P,m,'option_name','option_value')
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Input
%   Mandantory:
%               x   Observation vector to be decomposed
%               F   Function mapping from the sparse coeficient domain to
%                   the observation domain.
%               C   Function handle to cost function to be optimised
%               m   length of s 
%
%   Possible additional options:
%   (specify as many as you want using 'option_name','option_value' pairs)
%   See below for explanation of options:
%__________________________________________________________________________
%   option_name         AVAILABLE OPTION_VALUES                 default
%--------------------------------------------------------------------------
%   stopCrit        M, CORR, COST, COST_CHANGE                  M
%   stopTol         NUMBER (SEE BELOW)                          n/4
%   maxIter         POSITIVE INTEGER (SEE BELOW)                n
%   verbose         TRUE, FALSE                                 false
%   start_val       VECTOR OF LENGTH M                          zeros
%   weights         VECTOR OF LENGTH M CONTAINING WEIGHTS       ones
%                   TO BIASE ATOM SELECTION                    
%   grad_pert       PERTUBATION SIZE TO NUMERICALLY EVALUATE    1e-6
%                   GRADIENT                                   
%   step_size       STEP SIZE FOR GRADIENT OPTIMISATION STEP    0.1
%   grad_stop       CHANGE IN THE NORM OF THE GRADIENT BELOW    1e-3
%                   WHICH GRADIENT OPTIMISATION STOPS          
%   max_grad        MAXIMUM NUMBER OF GRADIENT STEPS            1000
%   grad            FUNCTION HANDLE TO GRADIENT OF COST        
%                   FUNCTION TO BE OPTIMISED                    
%   optimiser       FUNCTION HANDLE TO A FUNCTION THAT         
%                   OPTIMISES F FOR GIVEN INITIAL VALUE AND    
%                   GIVEN SUBSET OF COEFFICIENTS               
%   PlotFunc        FUNCTION HANDLE TO A FUNCTION THAT         
%                   PLOTS ESTIMATE OF SIGNAL GIVEN SPARSE      
%                   COEFFICIENT ESTIMATE                       
%                                                               
%
%   Available stopping criteria :
%               M           -   Extracts exactly M = stopTol elements.
%               corr        -   Stops when maximum correlation between
%                               residual and atoms is below stopTol value.
%               cost        -   Stops when cost C is below stopTol value.
%               cost_change -   Stops when the change cost C falles below
%                               stopTol value.
%
%   stopTol: Value for stoping criterion.
%
%   maxIter: Maximum of allowed iterations.
%
%   verbose: Logical value to allow algorithm progress to be displayed.
%
%   start_val: Allows algorithms to start from partial solution.
%
%   optimiser: Allows the specification of a function OPT(s,x,INDEX). 
%              OPT msut return the full coefficient vector s after 
%              optimisation of the cost function C over a given subset of
%              coefficients in s indexed by INDEX.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Outputs
%	 s              Solution vector 
%    err_cost       Vector containing cost of approximation error for each 
%                   iteration
%    iter_time      Vector containing times for each iteration
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Description
%   Algorithm selects greedily new elements in each iteration based on the
%   gradient of the cost function to be minimised with respect to the
%   coefficients. If the exact gradient is not specified, the gradienbt is
%   approximated using diference between cost at s and at s+DELTA. Once a
%   new element has been selected, gradient optimisation is used to
%   minimise the cost function based on the selected elements.
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/thirdparty/sparsify/nonlin_gg.html}
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

% References: T. Blumensath, M. E. Davies; "Gradient Pursuit for Non-Linear
%            Sparse Signal Modelling", submitted to EUSIPCO, 2008.
%   

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
   display('x must be a vector.');
   return
end
    
sigsize         = x'*x/n;
initial_given   = 0;
do_plot         = 0;
err_cost        = [];
iter_time       = [];
STOPCRIT        = 'M';
STOPTOL         = ceil(n/4);
MAXITER         = n;
verbose         = false;
s_initial       = zeros(m,1);
w               = ones(m,1);
g_tol           = 1e-6;
step_size       = 1;
grad_tol        = 1e-3;
grad_given      = 0;
optimiser_given = 0;
Max_Grad        = 100;


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
OS=nargin-4;
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
            if (strmatch(Options{i+1},{'M'; 'corr'; 'cost'; 'cost_change'},'exact'));
                STOPCRIT    = Options{i+1};  
            else error('stopCrit must be char string [M, corr, cost, cost_change]. Exiting.'); end 
        case {'stopTol'}
            if isa(Options{i+1},'numeric') ; STOPTOL     = Options{i+1};   
            else error('stopTol must be number. Exiting.'); end
        case {'grad_pert'}
            if isa(Options{i+1},'numeric') ; g_tol     = Options{i+1};   
            else error('grad_pert must be number. Exiting.'); end
        case {'grad'}
            if isa(Options{i+1},'function_handle') ; grad_given = 1; Grad = Options{i+1};   
            else error('grad must be function handle. Exiting.'); end
        case {'grad_stop'}
            if isa(Options{i+1},'numeric') ; grad_tol     = Options{i+1};   
            else error('grad_stop must be number. Exiting.'); end
        case {'step_size'}
            if isa(Options{i+1},'numeric') ; step_size     = Options{i+1};   
            else error('step_size must be number. Exiting.'); end
        case {'weights'} 
            if isa(Options{i+1},'numeric') & length(Options{i+1}) == m ;
                w  = Options{i+1};   
            else error('weights must be a vector of length m. Exiting.'); end
        case {'max_grad'} 
            if isa(Options{i+1},'numeric') & length(Options{i+1}) == 1 ;
                Max_Grad  = Options{i+1};   
            else error('max_grad must be scalar. Exiting.'); end
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
        case {'optimiser'}
            if isa(Options{i+1},'function_handle'); OPT = Options{i+1}; optimiser_given=1;
            else error('optimiser must be function handle. Exiting.'); end 
        case {'PlotFunc'}
            if isa(Options{i+1},'function_handle'); PlotFunc = Options{i+1}; do_plot=1;
            else error('PlotFunc must be function handle. Exiting.'); end 
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
    err_cost = zeros(maxM,1);
end
if nargout ==3
    iter_time = zeros(maxM,1);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Do we start from zero or not?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if initial_given ==1;
    IND          = find(s_initial);
    s            = s_initial;
    
else
    IND         = [];
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

done = 0;
ne   = C(s,x);
iter = 1;

while ~done


    % Select element with largest derivative

        
    if grad_given
        if verbose
            display('Calculating gradient...') 
        end
        grad                    = Grad(s,x);
      else
        if verbose
            display('Estimating gradient...') 
            tt=toc;
        end
        grad                    = zeros(m,1);
        for cm=1:m
            DELTA               = zeros(m,1);
            DELTA(cm)           = 0.5*g_tol;
            grad(cm)            = (C(s+DELTA,x)-C(s-DELTA,x))/g_tol;
        end
        if verbose
            display(['Elapsed time: ' num2str(toc-tt)])
        end
    end

  

    [val ind]=max(abs(w.*grad));


    if ~sum(IND==ind)
        IND=[IND ind];
        if verbose
            display(sprintf('New coefficient selected.')) 
        end
    end


    N_IND=1:m;
    N_IND(IND)=[];

    
    
    if optimiser_given
        if verbose
            display(sprintf('Optimising using supplied function.')) 
        end
        s   = OPT(s,x,IND);
        ne  = C(s,x);
    else
        
        if verbose
            display(sprintf('Optimising using gradient optimisation.')) 
            tt=toc;
        end
        CHANGE=1;
        count=0;

        while norm(grad)>grad_tol && count<Max_Grad && abs(CHANGE)>1e-12 && ~isempty (find(grad, 1))
            count=count+1;
            

            % ESTIMATE GRADIENT
            if count==1
                grad(N_IND)=zeros(size(N_IND));
            else
                if grad_given
                    grad                    = Grad(s,x);
                    grad(N_IND)             = 0;
                else
                    grad                    = zeros(m,1);
                    for cm=1:length(IND)
                        DELTA               = zeros(m,1);
                        DELTA(IND(cm))      = 0.5*g_tol;
                        grad(IND(cm))       = (C(s+DELTA,x)-C(s-DELTA,x))/g_tol;
                    end
                end
            end
            if count == Max_Grad
               display(sprintf('Maximum number of gradient steps reached.')) 
            end
            

      
            % Update s

            it          = 0;
            as          = step_size*grad;
            nne         = C(s-as,x);
            count       = 0;
            while ne    <= nne && ~isempty (find(grad, 1)) && count < 15
                count   = count+1; 
                it      = it+1;
                as      = step_size*10^(-it)*grad;
                nne     = C(s-as,x);
            end
            s           = s-as;

            % Calculate error and change in error
            CHANGE      = ne-nne;
            ne          = nne;
    
            if verbose && toc-tt>10
                display(sprintf('Norm of gradient --- %i,',norm(grad)));
                tt=toc;
            end

        end
    end

    ERR=ne^2/n;

    if comp_err
         err_cost(iter)=ERR;
    end

    if comp_time
         iter_time(iter)=toc;
    end
        
        


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        Are we done yet?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
     if strcmp(STOPCRIT,'M')
         if length(IND) >= STOPTOL
             done =1;
         elseif verbose && toc-t>10
            display(sprintf('Nonzero elements %i --- %i iterations to go --- current cost %i',length(IND) ,STOPTOL-length(IND),ne)) 
            if do_plot
                    PlotFunc(s)
            end
            t=toc;
         elseif do_plot && toc-t>10
            PlotFunc(s)
            t=toc;
         end
    elseif strcmp(STOPCRIT,'cost')
         if comp_err
            if err_cost(iter)<STOPTOL;
                done = 1; 
            elseif verbose && toc-t>10 
                display(sprintf('Iteration %i. --- %i cost',iter ,err_cost(iter))) 
                if do_plot
                    PlotFunc(s)
                end
                t=toc;
            elseif do_plot && toc-t>10
                PlotFunc(s)
                t=toc;
            end
         else
             if ERR<STOPTOL;
                done = 1; 
             elseif verbose && toc-t>10 
                display(sprintf('Iteration %i. --- %i cost',iter ,ERR)) 
                if do_plot
                    PlotFunc(s)
                end
                t=toc;
            elseif do_plot && toc-t>10
                PlotFunc(s)
                t=toc;
             end
         end
     elseif strcmp(STOPCRIT,'cost_change') && iter >=2
         if comp_err && iter >=2
              if ((err_cost(iter-1)-err_cost(iter))/sigsize <STOPTOL);
                done = 1; 
             elseif verbose && toc-t>10 
                display(sprintf('Iteration %i. --- %i cost change',iter ,(err_cost(iter-1)-err_cost(iter))/sigsize )) 
                if do_plot
                    PlotFunc(s)
                end
                t=toc;
            elseif do_plot && toc-t>10
                PlotFunc(s)
                t=toc;
             end
         else
             if ((oldERR - ERR)/sigsize < STOPTOL);
                done = 1; 
             elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i cost change',iter ,(oldERR - ERR)/sigsize)) 
                if do_plot
                    PlotFunc(s)
                end
                t=toc;
            elseif do_plot && toc-t>10
                PlotFunc(s)
                t=toc;
             end
         end
     elseif strcmp(STOPCRIT,'corr') 
          if max(abs(DR)) < STOPTOL;
             done = 1; 
          elseif verbose && toc-t>10
                display(sprintf('Iteration %i. --- %i corr',iter ,max(abs(DR)))) 
                if do_plot
                    PlotFunc(s)
                end
                t=toc;
          elseif do_plot && toc-t>10
                PlotFunc(s)
                t=toc;
          end
     end
     
    % Also stop if residual gets too small or maxIter reached
     if comp_err
         if err_cost(iter)<1e-16
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
    err_cost = err_cost(1:iter);
end
if nargout ==3
    iter_time = iter_time(1:iter);
end
if verbose
   display('Done') 
end



