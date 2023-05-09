function [gd,relres,iter] = gabconvexopt(g,a,M,varargin)
%-*- texinfo -*-
%@deftypefn {Function} gabconvexopt
%@verbatim
%GABCONVEXOPT Compute a window using convex optimization
%   Usage: gout=gabconvexopt(g,a,M);
%          gout=gabconvexopt(g,a,M, varagin);
%
%   Input parameters:
%     g      : Window function /initial point (tight case)
%     a      : Time shift
%     M      : Number of Channels
%
%   Output parameters:
%     gout   : Output window
%     iter   : Number of iterations
%     relres : Reconstruction error
%
%   GABCONVEXOPT(g,a,M) computes a window gout which is the optimal
%   solution of the convex optimization problem below
%
%      gd  = argmin_x    || alpha x||_1 +  || beta Fx||_1  
%
%                      + || omega (x -g_l) ||_2^2 + delta || x ||_S0
%
%                      + gamma || nabla F x ||_2^2 + mu || nabla x ||_2^2
%
%          such that  x satifies the constraints
%
%   Three constraints are possible:
%   
%    x is dual with respect of g
%
%    x is tight
%
%    x is compactly supported on Ldual
%
%   *Note**: This function require the unlocbox. You can download it at
%   http://unlocbox.sourceforge.net
%
%   The function uses an iterative algorithm to compute the approximate.
%   The algorithm can be controlled by the following flags:
%
%     'alpha',alpha  Weight in time. If it is a scalar, it represent the
%                  weights of the entire L1 function in time. If it is a 
%                  vector, it is the associated weight assotiated to each
%                  component of the L1 norm (length: Ldual).
%                  Default value is alpha=0.
%                  *Warning**: this value should not be too big in order to
%                  avoid the the L1 norm proximal operator kill the signal.
%                  No L1-time constraint: alpha=0
%
%     'beta',beta  Weight in frequency. If it is a scalar, it represent the
%                  weights of the entire L1 function in frequency. If it is a 
%                  vector, it is the associated weight assotiated to each
%                  component of the L1 norm in frequency. (length: Ldual).
%                  Default value is beta=0.
%                  *Warning**: this value should not be too big in order to
%                  avoid the the L1 norm proximal operator kill the signal.
%                  No L1-frequency constraint: beta=0
%
%     'omega',omega  Weight in time of the L2-norm. If it is a scalar, it represent the
%                  weights of the entire L2 function in time. If it is a 
%                  vector, it is the associated weight assotiated to each
%                  component of the L2 norm (length: Ldual).
%                  Default value is omega=0.
%                  No L2-time constraint: omega=0
%
%     'glike',g_l  g_l is a windows in time. The algorithm try to shape
%                  the dual window like g_l. Normalization of g_l is done
%                  automatically. To use option omega should be different
%                  from 0. By default g_d=0.
%
%     'mu', mu     Weight of the smooth constraint Default value is 1. 
%                  No smooth constraint: mu=0
%   
%     'gamma', gamma  Weight of the smooth constraint in frequency. Default value is 1. 
%                  No smooth constraint: gamma=0
%   
%     'delta', delta  Weight of the S0-norm. Default value is 0. 
%                  No S0-norm: delta=0
%
%     'support' Ldual  Add a constraint on the support. The windows should
%                  be compactly supported on Ldual.
%
%     'tight'      Look for a tight windows
%
%     'dual'       Look for a dual windows (default)
%
%     'painless'   Construct a starting guess using a painless-case
%                  approximation. This is the default
%
%     'zero'       Choose a starting guess of zero.
%
%     'rand'       Choose a random starting phase.
%
%     'tol',t      Stop if relative residual error is less than the 
%                  specified tolerance.  
%
%     'maxit',n    Do at most n iterations. default 200
%
%     'print'      Display the progress.
%
%     'debug'      Display all the progresses.
%
%     'quiet'      Don't print anything, this is the default.
%
%     'fast'       Fast algorithm, this is the default.
%
%     'slow'       Safer algorithm, you can try this if the fast algorithm
%                  is not working. Before using this, try to iterate more.
%
%     'printstep',p  If 'print' is specified, then print every p'th
%                    iteration. Default value is p=10;
%
%     'hardconstraint' Force the projection at the end (default)
%
%     'softconstaint' Do not force the projection at the end
%
%@end verbatim
%@strong{Url}: @url{http://ltfat.github.io/doc/gabor/gabconvexopt.html}
%@seealso{gaboptdual, gabdual, gabtight, gabfirtight, gabopttight}
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
   


% Author: Nathanael Perraudin
% Date  : 18 Feb 2014


if nargin<4
  error('%s: Too few input parameters.',upper(mfilename));
end;

if numel(g)==1
  error('g must be a vector (you probably forgot to supply the window function as input parameter.)');
end;

definput.keyvals.L=[];
definput.keyvals.lt=[0 1];
definput.keyvals.tol=1e-6;
definput.keyvals.maxit=200;
definput.keyvals.printstep=10;
definput.flags.print={'quiet','print','debug'};
definput.flags.algo={'fast','slow'};
definput.flags.constraint={'hardconstraint','softconstaint'};
definput.flags.startphase={'painless','zero','rand'};
definput.flags.type={'dual','tight'};

definput.keyvals.alpha=0;
definput.keyvals.omega=0;
definput.keyvals.beta=0;
definput.keyvals.mu=1;
definput.keyvals.gamma=1;
definput.keyvals.vart=0;
definput.keyvals.varf=0;
definput.keyvals.var2t=0;
definput.keyvals.var2f=0;
definput.keyvals.support=0;
definput.keyvals.delta=0;
definput.keyvals.deltaw=0;
definput.keyvals.glike=zeros(size(g));

[flags,kv]=ltfatarghelper({'L','tol','maxit'},definput,varargin);

% Determine the window. The window /must/ be an FIR window, so it is
% perfectly legal to specify L=[] when calling gabwin
[g,info]=gabwin(g,a,M,[],kv.lt,'callfun',upper(mfilename));

if kv.support
    Ldual=kv.support;
    % Determine L. L must be longer than L+Ldual+1 to make sure that no convolutions are periodic
    L=dgtlength(info.gl+Ldual+1,a,M);
else
    L=length(g);
    Ldual=L;
end

b=L/M;

% Determine the initial guess
if flags.do_zero
  gd_initial=zeros(Ldual,1);
end;

if flags.do_rand
  gd_initial=rand(size(g));
end;

if flags.do_painless
  gsmall=long2fir(g,M);
  gdsmall=gabdual(gsmall,a,M);
  gd_initial=fir2long(gdsmall,Ldual);
end;

% -------- do the convex optimization stuff

% Define the long original window
glong=fir2long(g,L);




%gabframebounds(g,a,M)


% Initial point
xin=gd_initial;
xin=fir2long(xin,L);


% -- * Setting the different prox for ppxa *--
% ppxa will minimize all different proxes

% value test for the selection constraint
nb_priors=0;

% - variance -
    if kv.vart % constraint in time
        if flags.do_debug
            param_l1.verbose=1; % display the results
        else
            param_l1.verbose=0; % do not display anything
        end
        
         % alpha is a scalar
        if mod(L,2)
             w=[0:1:(L-1)/2,(L-1)/2:-1:1]';
        else
             w=[0:1:L/2-1,L/2:-1:1]';
        end
        w=w.^2/L;
        
        param_l1.weights=w;
        nb_priors=nb_priors+1;
        g11.prox= @(x,T) prox_l1(x,kv.vart*T,param_l1); % define the prox_l1 as operator
        g11.eval= @(x) kv.vart*norm(w.*x,1); % the objectiv function is the l1 norm
    else % no L1 in time constraint
        g11.prox= @(x,T) x; 
        g11.eval= @(x) 0; 
    end

% - variance -
    if kv.varf % constraint in time
        
        param_l1_fourier.A= @(x) 1/sqrt(L)*fft(x); % Fourier operator
        param_l1_fourier.At= @(x) sqrt(L)*ifft(x); % adjoint of the Fourier operator
        if flags.do_debug
            param_l1_fourier.verbose=1; % display the results
        else
            param_l1_fourier.verbose=0; % do not display anything
        end
        
        if mod(L,2)
             w=[0:1:(L-1)/2,(L-1)/2:-1:1]';
        else
             w=[0:1:L/2-1,L/2:-1:1]';
        end
        w=w.^2/L;
         
        param_l1_fourier.weights=w;
        nb_priors=nb_priors+1;
        g12.prox= @(x,T) prox_l1(x,kv.varf*T,param_l1_fourier); % define the prox_l1 as operator
        g12.eval= @(x) kv.varf*norm(w.*x,1); % the objectiv function is the l1 norm
    else % no L1 in time constraint
        g12.prox= @(x,T) x; 
        g12.eval= @(x) 0; 
    end 

% - variance2 -
    if kv.var2t % constraint in time
        if flags.do_debug
            param_l2.verbose=1; % display the results
        else
            param_l2.verbose=0; % do not display anything
        end
        
         % alpha is a scalar
        if mod(L,2)
             w=[0:1:(L-1)/2,(L-1)/2:-1:1]';
        else
             w=[0:1:L/2-1,L/2:-1:1]';
        end
        w=w/sqrt(L);
        
        param_l2.weights=w;
        nb_priors=nb_priors+1;
        g13.prox= @(x,T) prox_l2(x,kv.var2t*T,param_l2); % define the prox_l1 as operator
        g13.eval= @(x) kv.var2t*norm(w.*x,2)^2; % the objectiv function is the l1 norm
    else % no L1 in time constraint
        g13.prox= @(x,T) x; 
        g13.eval= @(x) 0; 
    end

% - variance2 -
    if kv.var2f % constraint in time
        
        param_l2_fourier.A= @(x) 1/sqrt(L)*fft(x); % Fourier operator
        param_l2_fourier.At= @(x) sqrt(L)*ifft(x); % adjoint of the Fourier operator
        if flags.do_debug
            param_l2_fourier.verbose=1; % display the results
        else
            param_l2_fourier.verbose=0; % do not display anything
        end
        
        if mod(L,2)
             w=[0:1:(L-1)/2,(L-1)/2:-1:1]';
        else
             w=[0:1:L/2-1,L/2:-1:1]';
        end
        w=w/sqrt(L);
         
        param_l2_fourier.weights=w;
        nb_priors=nb_priors+1;
        g14.prox= @(x,T) prox_l2(x,kv.var2f*T,param_l2_fourier); % define the prox_l1 as operator
        g14.eval= @(x) kv.var2f*norm(w.*x,2)^2; % the objectiv function is the l1 norm
    else % no L1 in time constraint
        g14.prox= @(x,T) x; 
        g14.eval= @(x) 0; 
    end    
    
% - small L1 norm in coefficient domain -
    if kv.alpha % constraint in time
        if flags.do_debug
            param_l1.verbose=1; % display the results
        else
            param_l1.verbose=0; % do not display anything
        end
        
        if length(kv.alpha)==1 % alpha is a scalar
            kv.alpha=ones(size(xin))*kv.alpha;
        end
        param_l1.weights=kv.alpha;
        nb_priors=nb_priors+1;
        g1.prox= @(x,T) prox_l1(x,T,param_l1); % define the prox_l1 as operator
        g1.eval= @(x) norm(kv.alpha.*x,1); % the objectiv function is the l1 norm
    else % no L1 in time constraint
        g1.prox= @(x,T) x; 
        g1.eval= @(x) 0; 
    end

% - small L1 norm in Fourier domain -
    if kv.beta %frequency constraint
        param_l1_fourier.A= @(x) 1/sqrt(L)*fft(x); % Fourier operator
        param_l1_fourier.At= @(x) sqrt(L)*ifft(x); % adjoint of the Fourier operator
        if flags.do_debug
            param_l1_fourier.verbose=1; % display the results
        else
            param_l1_fourier.verbose=0; % Do not display anything
        end
        
        

        if length(kv.beta)==1 % alpha is a scalar
            kv.beta=ones(size(xin))*kv.beta;
        end

        param_l1_fourier.weights=kv.beta;
        % Here are the step for the prox
        %   2) go into the Fourier domain (prox_l1)
        %   3) soft thresholding (prox_l1)
        %   4) back in the time domain (prox_l1)
        nb_priors=nb_priors+1;
        g3.prox= @(x,T) prox_l1(x,T,param_l1_fourier);   

        g3.eval= @(x) norm(kv.beta.*fft(x),1); % objectiv function
    else % no L1 in frequency constraint
        g3.prox= @(x,T) x;   
        g3.eval= @(x) 0; % objectiv function
        
    end


% - DUAL OR TIGHT?-    
if flags.do_tight
    % tight windows
    g2.prox= @(x,T) gabtight(x,a,M); % set the prox
    g2.eval= @(x) norm(x-gabdual(x,a,M,L)); % objectiv function
else
% - projection on a B2 ball -
    % Frame-type matrix of the adjoint lattice
    %G=tfmat('dgt',glong,M,a);
    Fal=frame('dgt',glong,M,a);
    G=framematrix(Fal,L);
    d=[a/M;zeros(a*b-1,1)];
    
    % Using a B2 ball projection
    % || Gcut' x - b ||_2 < epsilon
%     param_proj.A = @(x) G'*x; % forward operator
%     param_proj.At = @(x) G*x; % adjoint operator
%     param_proj.y = d;            
%     param_proj.maxit = 200;      % maximum of iteration
%     param_proj.tight=0;         % not a tight frame
%     param_proj.nu=norm(G)^2; % frame bound on Gcut'
%     param_proj.verbose=0;       % diplay summary at the end
%     param_proj.epsilon=10*eps;       % radius of the B2 ball
%     g2.prox= @(x,T) fast_proj_b2(x,T,param_proj); % set the prox

    % Using a direct projection (better solution)
    param_proj.verbose=flags.do_debug;
    param_proj.y=d;
    param_proj.A=G';
    param_proj.AAtinv=(G'*G)^(-1);
    g2.prox= @(x,T) proj_dual(x,T,param_proj); % set the prox
    g2.eval= @(x) norm(G'*x-d); % objectiv function
end
    

% SUPPORT CONSTRAINT
if kv.support
% - set null coefficient    
    g4.prox = @(x,T) forceeven(fir2long(long2fir(x,Ldual),L));
    g4.eval = @(x) 0;

% - function apply the two projections thanks to a poc algorithm.
    if flags.do_tight

        G={g2,g4};
        paramPOCS.tol=20*eps;
        paramPOCS.maxit=5000;
        paramPOCS.verbose=flags.do_print+flags.do_debug;
        paramPOCS.abs_tol=1;
        g5.prox = @(x,T) pocs(x,G,paramPOCS);
        % g5.prox = @(x,T) ppxa(x,G,paramPOCS);
        % g5.prox = @(x,T) douglas_rachford(x,g2,g4,paramPOCS);
        % g5.prox = @(x,T) pocs2(x,g2,g4,20*eps,2000, flags.do_print+flags.do_debug);
        g5.eval = @(x) 0;

    else
        Fal=frame('dgt',glong,M,a);
        G=framematrix(Fal,L);
        d=[a/M;zeros(a*b-1,1)];
        Lfirst=ceil(Ldual/2);
        Llast=Ldual-Lfirst;
        Gcut=G([1:Lfirst,L-Llast+1:L],:);
        param_proj2.verbose=flags.do_debug;
        param_proj2.y=d;
        param_proj2.A=Gcut';
        param_proj2.AAtinv=pinv(Gcut'*Gcut);
        g5.prox= @(x,T) fir2long(proj_dual(long2fir(x,Ldual),T,param_proj2),L); % set the prox
        g5.eval= @(x) norm(G'*x-d); % objectiv function
    end
    
else
    g4.prox= @(x,T) x;   
    g4.eval= @(x) 0; % objectiv function
    g5=g2;
end
% - function apply the two projections thanks to a douglas rachford algorithm.
%     param_douglas.verbose=1;
%     param_douglas.abs_tol=1;
%     param_douglas.maxit=2000;
%     param_douglas.tol=20*eps;
%     g6.prox = @(x,T) douglas_rachford(x,g2,g4,param_douglas);
%     g6.eval = @(x) 0;



% - small gradient norm - 
% this is the smoothing parameter
    if kv.mu
        if flags.do_debug
            param_l2grad.verbose=1; % display the results
        else
            param_l2grad.verbose=0; % Do not display anything
        end
        nb_priors=nb_priors+1;
        g7.prox = @(x,T) prox_l2grad(fir2long(x,L),kv.mu*T,param_l2grad);
        g7.eval = @(x) norm(gradient(x))^2;
    else
        g7.prox = @(x,T) x;
        g7.eval = @(x) 0;
    end

    
    
% - small gradient norm in fourrier- 
% this is the smoothing parameter
    if kv.gamma
        if flags.do_debug
            param_l2grad.verbose=1; % display the results
        else
            param_l2grad.verbose=0; % Do not display anything
        end
        nb_priors=nb_priors+1;
        g9.prox = @(x,T) prox_l2gradfourier(fir2long(x,L),kv.gamma*T,param_l2grad);
        g9.eval = @(x) norm(gradient(1/sqrt(L)*fft(x)))^2;
    else
        g9.prox = @(x,T) x;
        g9.eval = @(x) 0;
    end
    
    
    
% - small L2 norm in coefficient domain -
    if kv.omega % constraint in time
        if flags.do_debug
            param_l2.verbose=1; % display the results
        else
            param_l2.verbose=0; % do not display anything
        end
        
        if length(kv.omega)==1 % alpha is a scalar
            kv.alpha=ones(size(xin))*kv.omega;
        end
        param_l2.weights=kv.omega;
        if sum(kv.glike)
           kv.glike=fir2long(kv.glike,L);

           glike=kv.glike/norm(kv.glike)*norm(gabdual(g,a,M));
           param_l2.y=fir2long(glike,L);
        end
        nb_priors=nb_priors+1;
        g8.prox= @(x,T) prox_l2(x,T,param_l2); % define the prox_l2 as operator
        g8.eval= @(x) norm(kv.omega.*x-kv.glike,'fro')^2; % the objectiv function is the l2 norm
    else % no L1 in time constraint
        g8.prox= @(x,T) x; 
        g8.eval= @(x) 0; 
    end    


    
    
% - small S0 norm -
    if kv.delta %frequency constraint
        gauss=pgauss(L,1);

        [A,B]=gabframebounds(gauss,1,L);
        AB=(A+B)/2;
        param_S0.A= @(x) dgt(x,gauss,1,L)/sqrt(AB);
        param_S0.At= @(x) idgt(x,gauss,1,L)/sqrt(AB);
        if flags.do_debug
            param_S0.verbose=1; % display the results
        else
            param_S0.verbose=0; % Do not display anything
        end
        
        nb_priors=nb_priors+1;
        g10.prox= @(x,T) prox_l1(x,T*kv.delta,param_S0);   

        g10.eval= @(x) kv.delta*norm(reshape(dgt(x,gauss,1,L),[],1),1); % objectiv function
    else % no L1 in frequency constraint
        g10.prox= @(x,T) x;   
        g10.eval= @(x) 0; % objectiv function
        
    end
    
% - small weighted S0 norm -
    if kv.deltaw %frequency constraint
        gauss=pgauss(L,1);

        [A,B]=gabframebounds(gauss,1,L);
        AB=(A+B)/2;
        param_S0.A= @(x) dgt(x,gauss,1,L)/sqrt(AB);
        param_S0.At= @(x) idgt(x,gauss,1,L)/sqrt(AB);
        if flags.do_debug
            param_S0.verbose=1; % display the results
        else
            param_S0.verbose=0; % Do not display anything
        end
        
        if mod(L,2)
             w=[0:1:(L-1)/2,(L-1)/2:-1:1]';
        else
             w=[0:1:L/2-1,L/2:-1:1]';
        end
        w=w/sqrt(L);
        
        %W=w*w';
        
        W=repmat(w,1,L).^2+repmat(w',L,1).^2;
        
        
        W=sqrt(W);
        
        param_S0.weights=W;
        nb_priors=nb_priors+1;
        g15.prox= @(x,T) prox_l1(x,T*kv.deltaw,param_S0);   

        g15.eval= @(x) kv.deltaw*norm(reshape(dgt(x,gauss,1,L),[],1),1); % objectiv function
    else % no L1 in frequency constraint
        g15.prox= @(x,T) x;   
        g15.eval= @(x) 0; % objectiv function
        
    end
    
    
    
% -- * PPXA function, the solver * --


% parameter for the solver
    param.maxit=kv.maxit; % maximum number of iteration
    param.tol=kv.tol;
    if flags.do_quiet
        param.verbose=0;
    end
    
    % Definition of the function f (the order is important)
    if flags.do_fast && flags.do_tight
        F={g1, g3,g7,g9,g8, g2, g4,g10,g11,g12,g13,g14,g15}; 
        
    else
        F={g1, g3,g7,g9,g8, g5,g10,g11,g12,g13,g14,g15};
    end

    
    % solving the problem
    
    if nb_priors
        [gd,iter,~]=ppxa(xin,F,param);
        
        % Force the hard constraint
        if flags.do_hardconstraint
            % In case of use of the douglas rachford algo instead of POCS
            %  gd=g6.prox(gd,0); % force the constraint

             gd=g5.prox(gd,0);
        end
    else
        fprintf( ' Warning!!! No prior selected! -- Only perform a projection. \n')
        gd=g5.prox(xin,0);
    end
    
    % compute the error
    if flags.do_tight
        relres=gabdualnorm(gd,gd,a,M,L);
    else
        relres=gabdualnorm(g,gd,a,M,L);
    end
    

   if kv.support
        % set the good size
        gd=long2fir(gd,Ldual);
   end

end


% function x=pocs2(x,g1,g2,tol,maxii,flagp)
% % this function implement a POCS algorithm, projection onto convex Set
% % using the differents projection of the algorithm.
% tola=1;
% ii=0;
% tola_old=tola;
% while (tola>tol)
%     x=g2.prox(g1.prox(x,0),0);
%     tola=g1.eval(x);
%     ii=ii+1;
%     if (logical(1-logical(mod(ii,50))) && flagp)
%        fprintf('      POCS sub-iteration: %i  -- Tol : %g\n',ii,tola)
%     end
%     if ii> maxii
%         break;
%     end
%     if abs(tola_old-tola)/tola<tol % avoid infinite loop
%         break;
%     end
%     tola_old=tola;
% end
% end

function x=forceeven(x)
% this function force the signal to be even
   x=  (x+involute(x))/2;
end

