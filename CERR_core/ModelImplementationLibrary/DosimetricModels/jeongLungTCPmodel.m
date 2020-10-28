function TCP = jeongLungTCPmodel(paramS,doseBinsV,volHistV)
% Usage: TCP = jeongLungTCPmodel(paramS);
% Lung TCP model
% Based on code by Jeho Jeong jeongj@mskcc.org
%------------------------------------------------------------------------------------
% INPUTS:
% paramS : Parameter dictionary with fields
%          -frxSize (Fraction size (Gy)), 
%          -treatmentSchedule(Vector indicating treatment days)
% Example: 
% paramS.frxSize.val = 2; 
% paramS.treatmentSchedule.val = [ 1  2  3  4  5 ...
%                           8  9 10 11 12 ...
%                           15 16 17 18 19 ...
%                           22 23 24 25 26];
% 
%----------------------------------------------------------------------------
% AI 8/30/18

%% Get frx size and treatment days
fx_in = paramS.frxSize.val;
schedule_in = paramS.treatmentSchedule.val; 
if ~isnumeric(schedule_in)
    schedule_in = str2num(schedule_in);
end

%TBD: Extending schedule ased on no. fractions

%% Input variables for the analysis
alpha_p_ori=0.305; 
a_over_b=2.8;
oer_i=1.7;
rho_t=10^6;
v_t_ref=3e4;
f_s=0.01;
t_c=2;
f_p_pro_in=0.5;
ht_loss=2; 
k_m=0.3;    
ht_lys=3; 
oer_h=1.37;
F_p_cyc=[0.56;0.24;0.2];
Alpha_ratio_p_cyc=[2;3];
   
d_t=15;       
clf_in=0.92; 
gf_in=0.25;

beta_p_ori=alpha_p_ori/a_over_b; 


%% EQD2 estimation for each cohort


EQD2=[]; 
n_pt=[];
v_t=3e4; 
alpha_p=alpha_p_ori;            
beta_p=beta_p_ori;
n_t=rho_t*v_t;                %No. cells
n_t_ref=rho_t*v_t_ref;
total_clono_cell=n_t*f_s;
delta_t=d_t/(60*24);          %dt in days
t_start=0;


IC=[];
GF=[];
TCP=[];
TD50=[];
BED=[];
Reox_time=[];
Reox_time2=[];
Treat_duration=[];
vec_leng=[];
comp_size(1)=0;       %Compartment size (P)
comp_size(2)=0;       %Compartment size (H)
comp_size(3)=0;       %Compartment size (I)
comp_size_ref(1)=0; 
comp_size_ref(2)=0;
comp_size_ref(3)=0;
p_pre=[]; 
i_pre=[];  
h_pre=[];
T_end=[]; 


clf=clf_in;
gf=gf_in;


%% Run sub-routine for specific CLF and GF
%---Variables for the initial st-st distribution--%
f_p_pro=f_p_pro_in;

comp_size(1)=gf/f_p_pro*n_t;
comp_size(2)=(1-gf*(1/f_p_pro_in+clf*ht_loss/t_c))*n_t;
comp_size(3)=clf*gf*ht_loss/t_c*n_t;

comp_size_ref(1)=gf/f_p_pro*n_t_ref;
comp_size_ref(2)=(1-gf*(1/f_p_pro_in+clf*ht_loss/t_c))*n_t_ref;
comp_size_ref(3)=clf*gf*ht_loss/t_c*n_t_ref;
%--- end ----%


%Record  number of cells
f_p=comp_size(1)/sum(comp_size);
f_i=comp_size(2)/sum(comp_size);
f_h=comp_size(3)/sum(comp_size);


for d=fx_in
    Treat_day=schedule_in;
    
    %Cell cycle and dose-dependent radiosensitivity
    f = @(alpha_s)F_p_cyc(1)*exp(-Alpha_ratio_p_cyc(1)*alpha_s*2-...
        Alpha_ratio_p_cyc(1)*(alpha_s/a_over_b)*4)+F_p_cyc(2)*...
        exp(-alpha_s*2-(alpha_s/a_over_b)*4)+F_p_cyc(3)*...
        exp(-Alpha_ratio_p_cyc(2)*alpha_s*2-...
        Alpha_ratio_p_cyc(2)*(alpha_s/a_over_b)*4)-exp(-alpha_p*2-...
        (alpha_p/a_over_b)*4);
    
    alpha_s=0.3; grid=0.1; pre_f=f(alpha_s);
    while abs(f(alpha_s)) >= eps
        if pre_f*f(alpha_s)<0
            grid=grid*0.1;
        end
        pre_f = f(alpha_s);
        if f(alpha_s)>0
            alpha_s=alpha_s+grid;
        else
            alpha_s=alpha_s-grid;
        end
    end
    Alpha_p_cyc(2)= alpha_s;


    Alpha_p_cyc(1)=Alpha_p_cyc(2)*Alpha_ratio_p_cyc(1);
    Alpha_p_cyc(3)=Alpha_p_cyc(2)*Alpha_ratio_p_cyc(2);

    %Effective alpha, beta from survival fractions 
    Su_p=F_p_cyc(1)*exp(-Alpha_p_cyc(1)*d-(Alpha_p_cyc(1)/a_over_b)*d^2)...
        +F_p_cyc(2)*exp(-Alpha_p_cyc(2)*d-(Alpha_p_cyc(2)/a_over_b)*d^2)...
        +F_p_cyc(3)*exp(-Alpha_p_cyc(3)*d-(Alpha_p_cyc(3)/a_over_b)*d^2);
    alpha_p_eff=-log(Su_p)/(d*(1+(d/a_over_b)));
    beta_p_eff=(alpha_p_eff/a_over_b);

    Su_i_2gy=exp(-alpha_p/oer_i*2-(alpha_p/a_over_b)/(oer_i^2)*2^2);
    oer_i_g1=(-(Alpha_p_cyc(1)*2)-sqrt((Alpha_p_cyc(1)*2)^2-...
        4*log(Su_i_2gy)*(Alpha_p_cyc(1)/a_over_b)*2^2))/(2*log(Su_i_2gy));
    Su_h_2gy=exp(-alpha_p/oer_h*2-(alpha_p/a_over_b)/(oer_h^2)*2^2);
    oer_h_g1=(-(Alpha_p_cyc(1)*2)-sqrt((Alpha_p_cyc(1)*2)^2-...
        4*log(Su_h_2gy)*(Alpha_p_cyc(1)/a_over_b)*2^2))/(2*log(Su_h_2gy));
    alpha_i=Alpha_p_cyc(1)/oer_i_g1;
    beta_i=(Alpha_p_cyc(1)/a_over_b)/(oer_i_g1^2);
    alpha_h=Alpha_p_cyc(1)/oer_h_g1;
    beta_h=(Alpha_p_cyc(1)/a_over_b)/(oer_h_g1^2);

    alpha_p=alpha_p_eff;
    beta_p=beta_p_eff;

    % Run sub-routine for a specific CLF and GF
    %--- RT fractional dose for SBRT schedule ---%

    % Assign proliferating fraction to the initial value
    f_p_pro=f_p_pro_in;

    % Cell distribution in each compartment 
    % (1:Pv, 2:Pd, 3:Iv, 4:Id, 5:Hv, 6:Hd, 7:lysis)
    % Initially all compartments are fully filled with viable cells
    % "comp_size" is the size of each compartment (1:P, 2:I, 3:H)

    cell_dist=[];
    cell_dist(1)=comp_size(1);
    cell_dist(2)=0;
    cell_dist(3)=comp_size(2);
    cell_dist(4)=0;
    cell_dist(5)=comp_size(3);
    cell_dist(6)=0;
    cell_dist(7)=0;

    % variables (t:time(day), j:# of fraction, add_time:additional time for
    %           weekend break, cum_cell_dist: cumulative cell distribution for
    %           each time increment)
    t=0;       
    j=0;
    cum_cell_dist_sbrt=[];


    % Treat for specific SBRT schedule
    while t<t_start+(max(Treat_day)-1)+delta_t/2

        % Change in f_p_pro (k_p) as blood supply improves
        f_p_pro=1-0.5*(cell_dist(1)+cell_dist(2))/comp_size(1);

        % RT fraction
        if  t>(t_start+(Treat_day(j+1)-1)-delta_t/2) &&...
                t<(t_start+(Treat_day(j+1)-1)+delta_t/2)

            cell_dist(2)=cell_dist(2)+cell_dist(1)*(1-exp(-alpha_p*d-beta_p*d^2));
            cell_dist(1)=cell_dist(1)*exp(-alpha_p*d-beta_p*d^2);
            cell_dist(4)=cell_dist(4)+cell_dist(3)*(1-exp(-alpha_i*d-beta_i*d^2));
            cell_dist(3)=cell_dist(3)*exp(-alpha_i*d-beta_i*d^2);
            cell_dist(6)=cell_dist(6)+cell_dist(5)*(1-exp(-alpha_h*d-beta_h*d^2));
            cell_dist(5)=cell_dist(5)*exp(-alpha_h*d-beta_h*d^2);

            j=j+1;
        end

        % Cell Proliferation & Death  
        cell_dist(1)=cell_dist(1)*(2)^(f_p_pro*delta_t/t_c);                      
        h_pre=cell_dist(5)+cell_dist(6);
        cell_dist(5)=cell_dist(5)*(0.5)^(delta_t/ht_loss);  
        cell_dist(6)=cell_dist(6)*(0.5)^(delta_t/ht_loss); 
        p_d_pre=cell_dist(2);
        cell_dist(2)=cell_dist(2)*(2)^(f_p_pro*(2*k_m-1)*delta_t/t_c);                      


        % Mitotically dead cell in 1 time step
        md=p_d_pre-cell_dist(2)+(h_pre-cell_dist(5)-cell_dist(6));
        cell_dist(7)=cell_dist(7)+md;
        cell_dist(7)=cell_dist(7)*(0.5)^(delta_t/ht_lys);


        % Recompartmentalization of the cell                      
        if cell_dist(1)+cell_dist(2)>=comp_size(1)                                         
            p_ex=(cell_dist(1)+cell_dist(2))-comp_size(1);                                 
            p_ratio=cell_dist(1)/(cell_dist(1)+cell_dist(2));                                
            cell_dist(1)=comp_size(1)*p_ratio;                                    
            cell_dist(2)=comp_size(1)*(1-p_ratio);                                
            cell_dist(3)=cell_dist(3)+p_ex*p_ratio;                               
            cell_dist(4)=cell_dist(4)+p_ex*(1-p_ratio);                           
        else                                                      
            if cell_dist(3)+cell_dist(4)>0                                        
                if cell_dist(3)+cell_dist(4)>comp_size(1)-...
                        (cell_dist(1)+cell_dist(2))                      
                    p_def=comp_size(1)-(cell_dist(1)+cell_dist(2));                        
                    i_ratio=cell_dist(3)/(cell_dist(3)+cell_dist(4));                    
                    cell_dist(1)=cell_dist(1)+p_def*i_ratio;                       
                    cell_dist(2)=cell_dist(2)+p_def*(1-i_ratio);                   
                    cell_dist(3)=cell_dist(3)-p_def*i_ratio;                     
                    cell_dist(4)=cell_dist(4)-p_def*(1-i_ratio);                 
                else                                              
                    cell_dist(1)=cell_dist(1)+cell_dist(3);                                 
                    cell_dist(2)=cell_dist(2)+cell_dist(4);                                 
                    cell_dist(3)=0; cell_dist(4)=0;                               
                    if cell_dist(5)+cell_dist(6)>0                                
                        if cell_dist(5)+cell_dist(6)>comp_size(1)-...
                                (cell_dist(1)+cell_dist(2))             
                            p_def=comp_size(1)-(cell_dist(1)+cell_dist(2));                
                            h_ratio=cell_dist(5)/(cell_dist(5)+cell_dist(6));            
                            cell_dist(1)=cell_dist(1)+p_def*h_ratio;               
                            cell_dist(2)=cell_dist(2)+p_def*(1-h_ratio);           
                            cell_dist(5)=cell_dist(5)-p_def*h_ratio;             
                            cell_dist(6)=cell_dist(6)-p_def*(1-h_ratio);         
                        else                                      
                            cell_dist(1)=cell_dist(1)+cell_dist(5);                         
                            cell_dist(2)=cell_dist(2)+cell_dist(6);                         
                            cell_dist(5)=0; cell_dist(6)=0;                       
                        end                                       
                    end                                           
                end                                               
            end                                                   
        end                                                       
        if cell_dist(3)+cell_dist(4)>=comp_size(2)                                      
            i_ex=(cell_dist(3)+cell_dist(4))-comp_size(2);                             
            i_ratio=cell_dist(3)/(cell_dist(3)+cell_dist(4));                            
            cell_dist(3)=comp_size(2)*i_ratio;                                 
            cell_dist(4)=comp_size(2)*(1-i_ratio);                             
            cell_dist(5)=cell_dist(5)+i_ex*i_ratio;                             
            cell_dist(6)=cell_dist(6)+i_ex*(1-i_ratio);                         
        else                                                      
            if cell_dist(5)+cell_dist(6)>0                                        
                if cell_dist(5)+cell_dist(6)>comp_size(2)-...
                        (cell_dist(3)+cell_dist(4))                   
                    i_def=comp_size(2)-(cell_dist(3)+cell_dist(4));                    
                    h_ratio=cell_dist(5)/(cell_dist(5)+cell_dist(6));                    
                    cell_dist(3)=cell_dist(3)+i_def*h_ratio;                    
                    cell_dist(4)=cell_dist(4)+i_def*(1-h_ratio);                
                    cell_dist(5)=cell_dist(5)-i_def*h_ratio;                    
                    cell_dist(6)=cell_dist(6)-i_def*(1-h_ratio);                
                else                                              
                    cell_dist(3)=cell_dist(3)+cell_dist(5);                               
                    cell_dist(4)=cell_dist(4)+cell_dist(6);                               
                    cell_dist(5)=0; cell_dist(6)=0;                               
                end                                               
            end                                                   
        end                                                      


        % time step increase and store the number of cells in each compartment
        t=t+delta_t;                                              
        cum_cell_dist_sbrt=[cum_cell_dist_sbrt cell_dist'];

    end
   
 
    s_sbrt=cell_dist(1)+cell_dist(3)+cell_dist(5);
    sf_sbrt=s_sbrt/sum(comp_size);
    ntd2=length(Treat_day)*d*(1+(d/a_over_b))/(1+(2/a_over_b));
    d_sbrt=d;
    n_frac_sbrt=length(Treat_day);
    duration_sbrt=max(Treat_day);
    t_sbrt=t;
    %-------------------------------------------------------------------------------%

    
    %% EQD2 calculation
    d=2;
    alpha_p=alpha_p_ori;            beta_p=beta_p_ori;
    alpha_i=alpha_p_ori/oer_i;      beta_i=beta_p_ori/(oer_i^2);
    alpha_h=alpha_p_ori/oer_h;      beta_h=beta_p_ori/(oer_h^2);
    s_eqd2=0;       sf_eqd2=0;      eqd2=0;  
    

    %----- RT fractional dose for EQD2 estimation ----%

    % Assign proliferating fraction to the initial value

    f_p_pro=f_p_pro_in;

    % Cell distribution in each compartment 
    % (1:Pv, 2:Pd, 3:Iv, 4:Id, 5:Hv, 6:Hd, 7:lysis)
    % Initially all compartments are fully filled with viable cells
    % "comp_size" is the size of each compartment (1:P, 2:I, 3:H)

    cell_dist=[];
    cell_dist(1)=comp_size_ref(1);
    cell_dist(2)=0;
    cell_dist(3)=comp_size_ref(2);
    cell_dist(4)=0;
    cell_dist(5)=comp_size_ref(3);
    cell_dist(6)=0;
    cell_dist(7)=0;

    % variables (t:time(day), j:# of fraction, add_time:additional time for
    %           weekend break, cum_cell_dist: cumulative cell distribution for
    %           each time increment)
    t=0;       
    j=0;
    add_time=0;
    cum_cell_dist=[];




    % Treat until the SF becomes equivalent to SBRT regime
    while (cell_dist(1)+cell_dist(3)+cell_dist(5))>s_sbrt  

        % Change in f_p_pro (k_p) as blood supply improves
        f_p_pro=1-0.5*(cell_dist(1)+cell_dist(2))/comp_size(1);


        % RT fraction
        if  t>(t_start+j+add_time-delta_t/2) && t<(t_start+j+add_time+delta_t/2)

            cell_dist(2)=cell_dist(2)+cell_dist(1)*(1-exp(-alpha_p*d-beta_p*d^2));
            cell_dist(1)=cell_dist(1)*exp(-alpha_p*d-beta_p*d^2);
            cell_dist(4)=cell_dist(4)+cell_dist(3)*(1-exp(-alpha_i*d-beta_i*d^2));
            cell_dist(3)=cell_dist(3)*exp(-alpha_i*d-beta_i*d^2);
            cell_dist(6)=cell_dist(6)+cell_dist(5)*(1-exp(-alpha_h*d-beta_h*d^2));
            cell_dist(5)=cell_dist(5)*exp(-alpha_h*d-beta_h*d^2);

            j=j+1;

            % Week-end break
            if rem(j,5)==0
                add_time=add_time+2;
            end

        end

        % Cell Proliferation & Death  
        cell_dist(1)=cell_dist(1)*(2)^(f_p_pro*delta_t/t_c);
        h_pre=cell_dist(5)+cell_dist(6);
        cell_dist(5)=cell_dist(5)*(0.5)^(delta_t/ht_loss);  
        cell_dist(6)=cell_dist(6)*(0.5)^(delta_t/ht_loss); 
        p_d_pre=cell_dist(2);
        cell_dist(2)=cell_dist(2)*(2)^(f_p_pro*(2*k_m-1)*delta_t/t_c);                      


        % Mitotically dead cell in 1 time step
        md=p_d_pre-cell_dist(2)+(h_pre-cell_dist(5)-cell_dist(6));
        cell_dist(7)=cell_dist(7)+md;
        cell_dist(7)=cell_dist(7)*(0.5)^(delta_t/ht_lys);


        % Recompartmentalization of the cell                      
        if cell_dist(1)+cell_dist(2)>=comp_size(1)                                         
            p_ex=(cell_dist(1)+cell_dist(2))-comp_size(1);                                 
            p_ratio=cell_dist(1)/(cell_dist(1)+cell_dist(2));                                
            cell_dist(1)=comp_size(1)*p_ratio;                                    
            cell_dist(2)=comp_size(1)*(1-p_ratio);                                
            cell_dist(3)=cell_dist(3)+p_ex*p_ratio;                               
            cell_dist(4)=cell_dist(4)+p_ex*(1-p_ratio);                           
        else                                                      
            if cell_dist(3)+cell_dist(4)>0                                        
                if cell_dist(3)+cell_dist(4)>comp_size(1)-...
                        (cell_dist(1)+cell_dist(2))                      
                    p_def=comp_size(1)-(cell_dist(1)+cell_dist(2));                        
                    i_ratio=cell_dist(3)/(cell_dist(3)+cell_dist(4));                    
                    cell_dist(1)=cell_dist(1)+p_def*i_ratio;                       
                    cell_dist(2)=cell_dist(2)+p_def*(1-i_ratio);                   
                    cell_dist(3)=cell_dist(3)-p_def*i_ratio;                     
                    cell_dist(4)=cell_dist(4)-p_def*(1-i_ratio);                 
                else                                              
                    cell_dist(1)=cell_dist(1)+cell_dist(3);                                 
                    cell_dist(2)=cell_dist(2)+cell_dist(4);                                 
                    cell_dist(3)=0; cell_dist(4)=0;                               
                    if cell_dist(5)+cell_dist(6)>0                                
                        if cell_dist(5)+cell_dist(6)>comp_size(1)-...
                                (cell_dist(1)+cell_dist(2))             
                            p_def=comp_size(1)-(cell_dist(1)+cell_dist(2));                
                            h_ratio=cell_dist(5)/(cell_dist(5)+cell_dist(6));            
                            cell_dist(1)=cell_dist(1)+p_def*h_ratio;               
                            cell_dist(2)=cell_dist(2)+p_def*(1-h_ratio);           
                            cell_dist(5)=cell_dist(5)-p_def*h_ratio;             
                            cell_dist(6)=cell_dist(6)-p_def*(1-h_ratio);         
                        else                                      
                            cell_dist(1)=cell_dist(1)+cell_dist(5);                         
                            cell_dist(2)=cell_dist(2)+cell_dist(6);                         
                            cell_dist(5)=0; cell_dist(6)=0;                       
                        end                                       
                    end                                           
                end                                               
            end                                                   
        end                                                       
        if cell_dist(3)+cell_dist(4)>=comp_size(2)                                      
            i_ex=(cell_dist(3)+cell_dist(4))-comp_size(2);                             
            i_ratio=cell_dist(3)/(cell_dist(3)+cell_dist(4));                            
            cell_dist(3)=comp_size(2)*i_ratio;                                 
            cell_dist(4)=comp_size(2)*(1-i_ratio);                             
            cell_dist(5)=cell_dist(5)+i_ex*i_ratio;                             
            cell_dist(6)=cell_dist(6)+i_ex*(1-i_ratio);                         
        else                                                      
            if cell_dist(5)+cell_dist(6)>0                                        
                if cell_dist(5)+cell_dist(6)>comp_size(2)-...
                        (cell_dist(3)+cell_dist(4))                   
                    i_def=comp_size(2)-(cell_dist(3)+cell_dist(4));                    
                    h_ratio=cell_dist(5)/(cell_dist(5)+cell_dist(6));                    
                    cell_dist(3)=cell_dist(3)+i_def*h_ratio;                    
                    cell_dist(4)=cell_dist(4)+i_def*(1-h_ratio);                
                    cell_dist(5)=cell_dist(5)-i_def*h_ratio;                    
                    cell_dist(6)=cell_dist(6)-i_def*(1-h_ratio);                
                else                                              
                    cell_dist(3)=cell_dist(3)+cell_dist(5);                               
                    cell_dist(4)=cell_dist(4)+cell_dist(6);                               
                    cell_dist(5)=0; cell_dist(6)=0;                               
                end                                               
            end                                                   
        end                                                      


        % time step increase and store the number of cells in each compartment
        t=t+delta_t;                                              
        cum_cell_dist=[cum_cell_dist cell_dist'];

        s_eqd2_pre=s_eqd2;
        sf_eqd2_pre=sf_eqd2;
        eqd2_pre=eqd2;

        s_eqd2=cell_dist(1)+cell_dist(3)+cell_dist(5);
        sf_eqd2=s_eqd2/sum(comp_size);
        tcp=exp(-s_eqd2*f_s);
        eqd2=j*d;


    end
    
 
    %----------------------------------------------------------------------%


    eqd2=eqd2_pre+((eqd2-eqd2_pre)/(s_eqd2_pre-s_eqd2))*(s_eqd2_pre-s_sbrt);

    
end

%% Compute TCP
TD_50 = 62.1;
gamma_50 = 1.5;
TCP_upper_bound = 0.95;

TCP=TCP_upper_bound/(1+(TD_50/eqd2)^(4*gamma_50));
