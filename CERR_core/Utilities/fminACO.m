function [minconpos, mincon, Xhis] = fminACO(fun1,LB,UB,Ninit,NumAnts,Nmoves,LocalMoves,nonlinfun,rpmax,varargin)

%  fminACO Finds a unconstrained or constrained minimum of a function of several variables.
%     fminACO solves problems of the form:
%         min F(X)  subject to:  g(x) <= 0,  h(x) = Beq (inequality & equality constraints)
%          X                     LB <= X <= UB (boundary constraints)
%                                              
%     X = fminACO(FUN,LB,UB,NumAnts,Nmoves,LocalMoves,NONLNCON,rpmax) minimizes FUN
%     subject to inequality and equality constraints in NONLINCON. (Set NONLINCON=[] 
%     and rpmax=[] if no inequality and equality constraints exist).
%     NumAnts    = Number of Ants to be used.
%     Nmoves     = Number of Nest Moves.
%     LocalMoves = Number of Local Moves for fminACO Ants.
%     rpmax      = Augmented Lagrangian parameter.
% 
%     X=fminACO(FUN,LB,UB,NumAnts,Nmoves,LocalMoves,NONLNCON,rpmax,P1,P2,...) passes the 
%     problem-dependent parameters P1,P2,... directly to the functions FUN 
%     and NONLCON: feval(FUN,X,P1,P2,...) and feval(NONLCON,X,P1,P2,...).
%
% Example:
% FUN='testbanana';LB=[-5 -5];UB=[3 3];NumAnts=20;Nmoves=15;LocalMoves=25;
% NONLNCON='nonlinbanana';rpmax=5;
% X=fminACO(FUN,LB,UB,NumAnts,Nmoves,LocalMoves,NONLNCON,rpmax)
% 
% Listing of Objective and Constraint for the above exxample
% 
% function f=testbanana(x)
% f=100*(x(1)^2-x(2))^2 + (1-x(1))^2;
% 
% function [g,h]=nonlinbanana(x)
% x1=x(1); x2=x(2);
% %%% Equality Constraints %%%%%%%%
% h=0;
% %%% Inequality Constraints %%%%%%
% g(1,:)=-(x1.^2+x2.^2-1.2);
% g(2,:)=-(1.5-(x1-.2)^2-x2.^2);
%
% APA, Spring'04

%warning off
Xhis = [];
if isempty(nonlinfun)
    
    xb=[LB(:) UB(:)];
    
    % Specify the starting point
    %Ninit = (LB+UB)/2;
    
    n=length(Ninit);
    
    %%% **************--- Unconstrained Loop ---****************
    
    N=Ninit;% Initial Nest Location
    min1=inf;
    disp('Nest Move    Objective')
    for ii=1:Nmoves   % Number of Nest Moves 
        
        Smem=[];    
        for num=1:NumAnts       
            if(num==1)
                Asite=0.01;
            else
                Asite=0.01*(1/0.01)^(num/NumAnts);
            end
            for i=1:2
                for j=1:n
                    r=rand;
                    S(j)=N(j)+((-0.5+r)*Asite*(xb(j,2)-xb(j,1)));
                    while(~((xb(j,1)<=S(j))&(xb(j,2)>=S(j))))
                        r=rand;
                        S(j)=N(j)+((-0.5+r)*Asite*(xb(j,2)-xb(j,1)));
                    end
                end
                Smem=[Smem;S];            
            end            
        end        
        % Fun1='fun';
        %%%%%%%%%%%% Tandem Running %%%%%%%%%%%%%%%
        a1=1+floor(NumAnts*rand);
        a2=1+floor(NumAnts*rand);
        f1=feval(fun1,Smem(2*a1-1,:),varargin{:});
        f2=feval(fun1,Smem(2*a1,:),varargin{:});
        f3=feval(fun1,Smem(2*a2-1,:),varargin{:});
        f4=feval(fun1,Smem(2*a2,:),varargin{:});
        
        if(f1<f2)
            fpos1=2*a1-1;
            fmin1=f1;
        else
            fpos1=2*a1;
            fmin1=f2;
        end
        if(f3<f4)
            fpos2=2*a2-1;
            fmin2=f3;
        else
            fpos2=2*a2;
            fmin2=f4;
        end
        if(fmin1<fmin2)
            Smem(fpos2,:)=Smem(fpos1,:);
        else
            Smem(fpos1,:)=Smem(fpos2,:);
        end  
        %%%%%%%%%%%%%%tandem running loop ends%%%%%%%%%%%%%%%%%%
        
        for num=1:2:(2*NumAnts-1)
            
            if(num==1)
                Alocal=0.1*0.01;
            else           
                Alocal=(1/10)*0.01*(1/0.01)^(((num+1)/2)/NumAnts);
            end
            pos1=num;
            pos2=num+1;
            
            for i=1:LocalMoves   % Number of Local Sites % Local Search Loop Starts here
                
                Spos=Smem(num,:);        
                for j=1:n
                    r=rand;
                    Sloc(j)=Spos(j)+(-0.5+r)*Alocal*(xb(j,2)-xb(j,1));
                    while(~((xb(j,1)<=Sloc(j))&(xb(j,2)>=Sloc(j))))
                        r=rand;
                        Sloc(j)=Spos(j)+(-0.5+r)*Alocal*(xb(j,2)-xb(j,1));
                    end
                end
                
                V1=feval(fun1,Spos,varargin{:});
                V2=feval(fun1,Sloc,varargin{:});
                if(V1>V2)
                    Smem(pos1,:)=Sloc;
                    if(min1>V2)
                        minpos=Sloc;  
                        min1=V2;
                    end
                else
                    temppos=Smem(pos1,:);
                    Smem(pos1,:)=Smem(pos2,:);
                    Smem(pos2,:)=temppos;
                    if(min1>V1)
                        minpos=Spos;
                        min1=V1;
                    end
                end
                
            end
            
        end
        
        N=minpos;
        % disp('[Nest Move    Objective]')
        disp(['    ',num2str(ii),'        ',num2str(min1)])
        
        Xhis = [Xhis; minpos(:)' min1];
        
        save 'C:\Projects\ASTRO2010\StomachGTV\aco_result.mat' Xhis
        
    end
    
    %%%***********--- Unconstrained Loop Ends ---***************
    minconpos=minpos;
    mincon=min1;
    
else
    
    %fminACO1Gen.m
    ftemp=fun1;nonlinfuntemp=nonlinfun;
    global rp mu1 si1 fun1 nonlinfun
    fun1=ftemp;nonlinfun=nonlinfuntemp;
    xb=[LB(:) UB(:)];
    
    % Specify the starting point
    Ninit = (LB+UB)/2;
    
    n=length(Ninit);
    rp=1;
    [g1, h1]=feval('nonlinfminACO',Ninit,varargin{:});
    mu1=zeros(length(g1),1);
    si1=zeros(length(h1),1);
    
    mincon=inf;
    NITER=0;
    while(rp<rpmax)
        
        NITER=NITER+1;
        
        %%% **************--- Unconstrained Loop ---****************
        
        N=Ninit;% Initial Nest Location
        min1=inf;
        
        for ii=1:Nmoves   % Number of Nest Moves 
            
            Smem=[];    
            for num=1:NumAnts       
                if(num==1)
                    Asite=0.01;
                else
                    Asite=0.01*(1/0.01)^(num/NumAnts);
                end
                for i=1:2
                    for j=1:n
                        r=rand;
                        S(j)=N(j)+((-0.5+r)*Asite*(xb(j,2)-xb(j,1)));
                        while(~((xb(j,1)<=S(j))&(xb(j,2)>=S(j))))
                            r=rand;
                            S(j)=N(j)+((-0.5+r)*Asite*(xb(j,2)-xb(j,1)));
                        end
                    end
                    Smem=[Smem;S];            
                end            
            end        
            %%%%%%%%%%%% Tandem Running %%%%%%%%%%%%%%%
            a1=1+floor(NumAnts*rand);
            a2=1+floor(NumAnts*rand);
            f1=feval(@funfminACO,Smem(2*a1-1,:),varargin{:});
            f2=feval(@funfminACO,Smem(2*a1,:),varargin{:});
            f3=feval(@funfminACO,Smem(2*a2-1,:),varargin{:});
            f4=feval(@funfminACO,Smem(2*a2,:),varargin{:});
            
            if(f1<f2)
                fpos1=2*a1-1;
                fmin1=f1;
            else
                fpos1=2*a1;
                fmin1=f2;
            end
            if(f3<f4)
                fpos2=2*a2-1;
                fmin2=f3;
            else
                fpos2=2*a2;
                fmin2=f4;
            end
            if(fmin1<fmin2)
                Smem(fpos2,:)=Smem(fpos1,:);
            else
                Smem(fpos1,:)=Smem(fpos2,:);
            end  
            %%%%%%%%%%%%%%tandem running loop ends%%%%%%%%%%%%%%%%%%
            
            for num=1:2:(2*NumAnts-1)
                
                if(num==1)
                    Alocal=0.1*0.01;
                else           
                    Alocal=(1/10)*0.01*(1/0.01)^(((num+1)/2)/NumAnts);
                end
                pos1=num;
                pos2=num+1;
                
                for i=1:LocalMoves   % Number of Local Sites % Local Search Loop Starts here
                    
                    Spos=Smem(num,:);        
                    for j=1:n
                        r=rand;
                        Sloc(j)=Spos(j)+(-0.5+r)*Alocal*(xb(j,2)-xb(j,1));
                        while(~((xb(j,1)<=Sloc(j))&(xb(j,2)>=Sloc(j))))
                            r=rand;
                            Sloc(j)=Spos(j)+(-0.5+r)*Alocal*(xb(j,2)-xb(j,1));
                        end
                    end
                    
                    V1=feval(@funfminACO,Spos,varargin{:});
                    V2=feval(@funfminACO,Sloc,varargin{:});
                    if(V1>V2)
                        Smem(pos1,:)=Sloc;
                        if(min1>V2)
                            minpos=Sloc;  
                            min1=V2;
                        end
                    else
                        temppos=Smem(pos1,:);
                        Smem(pos1,:)=Smem(pos2,:);
                        Smem(pos2,:)=temppos;
                        if(min1>V1)
                            minpos=Spos;
                            min1=V1;
                        end
                    end
                    
                end
                
            end
            
            N=minpos;
            
        end
        
        %%%***********--- Unconstrained Loop Ends ---***************
        
        %%% --- Augmented Lagrangian Method ---
        if(rp>1)
            mincon=feval(@funfminACO,minconpos,varargin{:});
        end
        if(min1<mincon)
            minconpos=minpos;
            mincon=min1;
        end
        
        [temp1, temp2]=feval(nonlinfun, minconpos,varargin{:});
        mu1 = mu1 + rp.*temp1(:);
        si1 = si1 + rp.*temp2(:);
        %%% ------ End of Augmented Lagrangian -----
        
        rp=rp*1.15;
        if NITER==1
            disp('Iteration     Objective    Maximum Constraint')
            disp(['     ',num2str(NITER),'         ',num2str(mincon),'         ',num2str(max(temp1))])
        else
            disp(['     ',num2str(NITER),'         ',num2str(mincon),'         ',num2str(max(temp1))])
        end
        
    end %%% End of Constrained Loop (i.e. rp)
    
    %%%% function fminACO1gen(fun1,nonlinfminACO) ends
    
end




function Faug=funfminACO(x,varargin)

global mu1 si1 rp nonlinfun fun1
if ~isempty(varargin)
    f=feval(fun1,x,varargin{:});
else
    f=feval(fun1,x);
end
if ~isempty(varargin)
    [zeta1, h1]=feval(nonlinfun,x,varargin{:});
else
    [zeta1, h1]=feval(nonlinfun,x);
end
Fp = f + rp/2*(sum(zeta1.^2) + sum(h1.^2));
Faug = Fp + sum(mu1(:).*zeta1(:)) + sum(si1(:).*h1(:));

%%%%% fun1(x) ends %%%%

function [zeta1, h1]=nonlinfminACO(x,varargin)
global mu1 si1 rp h1 nonlinfun

if ~isempty(varargin)
    [g1, h1]=feval(nonlinfun,x,varargin{:});
else
    [g1, h1]=feval(nonlinfun,x);
end
if(rp==1)
    zeta1=g1;
else
    zeta1=max(g1,-mu1/rp);
end

%%%%% function nonlinfminACO(x) ends