function [SurvivingFraction,SurvivingFraction_t,t_vec,trt_points] = surviving_fraction_model(DosePerFx,...
    TreatmentSchedule,AlphaVal,AlphaBetaVal,EmptyDVHs,minSF)
%
% AF
% AI 9/6/17  , Set GrowthFraction = 0.25 and CellLossFactor = 0.92 (Jeho’s values) 
% AI 9/18/17 , Updated to include weekend breaks

if ~exist('minSF','var')
    minSF = inf;
end
EmptyDVHs = logical(EmptyDVHs);

%% farctionation scheme

% fractionation schedule
% TreatmentSchedule = 
%   [ 1  2  3  4  5 ...
%   8  9 10 11 12 ...
%   15 16 17 18 19 ...
%   22 23 24 25 26 ...
%   29 30 31 32 33 ...
%   36 37 38 39 40 ...
%   43 44 45 46 47 ...
%   50 51];

%% Time Variables  

t_interval = 1; %Hours
CellLossHalftime = 2*24; %Hours
LysisHalftime = 3*24; %Hours
CellCycleTime = 2*24; %Hours

TreatmentSchedule = (TreatmentSchedule - 1)*24; 
t_vec = 0:t_interval:max(TreatmentSchedule);
t_vec = t_vec';

trt_points = zeros(size(t_vec));

UsedDosePerFx = DosePerFx(~EmptyDVHs);
SurvivingFraction_t = zeros(length(t_vec),length(DosePerFx));

%  ------- AI 9/6/17 Set GrowthFraction = 0.25 and CellLossFactor = 0.92(Jeho’s values) ------
% CellLossFactor = 0.92;
% Td = 50*24;
% GrowthFraction = CellCycleTime/((1-CellLossFactor)*Td);
% if GrowthFraction > 0.25
%     GrowthFraction = 0.25;
%     CellLossFactor = 1-CellCycleTime/(GrowthFraction*Td);
% end
GrowthFraction = 0.25;
CellLossFactor = 0.92; 
% ----------------------  END CHANGE -------------------------------------------

%% Tumor Variables
TumorVol = 10;
CellDensity = 10^9;
NumCells = CellDensity*TumorVol;
InitialNumCells = CellDensity*TumorVol;

InitProliferativeFraction = 0.5;
SurvivingFractionPostMitosis = 0.3;


%% Radiosensitivity Variable
BetaVal = AlphaVal/AlphaBetaVal;   

OER_iComp = 1.55;
OER_hComp = 1.37;


%% Correct for cell cycle effects


% if sum(TreatmentSchedule) == 1 && ~continuous
% 
%     F_p_cyc = [0.56;0.24;0.2];
%     Alpha_ratio_p_cyc = [2;3];
% 
%     f = @(alpha_s)F_p_cyc(1)*exp(-Alpha_ratio_p_cyc(1)*alpha_s*2-...
%         Alpha_ratio_p_cyc(1)*(alpha_s/AlphaBetaVal)*4)+F_p_cyc(2)*...
%         exp(-alpha_s*2-(alpha_s/AlphaBetaVal)*4)+F_p_cyc(3)*...
%         exp(-Alpha_ratio_p_cyc(2)*alpha_s*2-...
%         Alpha_ratio_p_cyc(2)*(alpha_s/AlphaBetaVal)*4)-exp(-AlphaVal*2-...
%         (AlphaVal/AlphaBetaVal)*4);
%     
%     Alpha_p_cyc(2) = fzero(f,0.3);
%     Alpha_p_cyc(1) = Alpha_p_cyc(2)*Alpha_ratio_p_cyc(1);
%     Alpha_p_cyc(3) = Alpha_p_cyc(2)*Alpha_ratio_p_cyc(2);
%     
%     Su_p = F_p_cyc(1)*exp(-Alpha_p_cyc(1)*MeanDose-(Alpha_p_cyc(1)/AlphaBetaVal)*MeanDose^2)...
%         +F_p_cyc(2)*exp(-Alpha_p_cyc(2)*MeanDose-(Alpha_p_cyc(2)/AlphaBetaVal)*MeanDose^2)...
%         +F_p_cyc(3)*exp(-Alpha_p_cyc(3)*MeanDose-(Alpha_p_cyc(3)/AlphaBetaVal)*MeanDose^2);
% 
%     alpha_p_eff = -log(Su_p)./(MeanDose.*(1+(MeanDose/AlphaBetaVal)));
%     
%     beta_p_eff = (alpha_p_eff/AlphaBetaVal);
%     
%     Su_i_2gy = exp(-AlphaVal/OER_iComp*2-(AlphaVal/AlphaBetaVal)/(OER_iComp^2)*2^2);
%     oer_i_g1 = (-(Alpha_p_cyc(1)*2)-sqrt((Alpha_p_cyc(1)*2)^2-...
%         4*log(Su_i_2gy)*(Alpha_p_cyc(1)/AlphaBetaVal)*2^2))/(2*log(Su_i_2gy));
%     
%     Su_h_2gy = exp(-AlphaVal/OER_hComp*2-(AlphaVal/AlphaBetaVal)/(OER_hComp^2)*2^2);
%     oer_h_g1 = (-(Alpha_p_cyc(1)*2)-sqrt((Alpha_p_cyc(1)*2)^2-...
%         4*log(Su_h_2gy)*(Alpha_p_cyc(1)/AlphaBetaVal)*2^2))/(2*log(Su_h_2gy));
%     
%     
%     Alpha_iComp = Alpha_p_cyc(1)/oer_i_g1;
%     Beta_iComp = (Alpha_p_cyc(1)/AlphaBetaVal)/(oer_i_g1^2);
%     
%     Alpha_hComp = Alpha_p_cyc(1)/oer_h_g1;
%     Beta_hComp = (Alpha_p_cyc(1)/AlphaBetaVal)/(oer_h_g1^2);
%     
%     Alpha_pComp = alpha_p_eff;
%     Beta_pComp = beta_p_eff;
% 
% else
    
    Alpha_pComp = AlphaVal;
    Beta_pComp = BetaVal;

    Alpha_iComp = AlphaVal/OER_iComp;
    Beta_iComp = BetaVal/(OER_iComp)^2;

    Alpha_hComp = AlphaVal/OER_hComp;
    Beta_hComp = BetaVal/(OER_hComp)^2;
    
% end


%%





%% Calculate compartment sizes

vlength = length(UsedDosePerFx);

P_CompSize = NumCells*(GrowthFraction/InitProliferativeFraction)*ones(1,vlength);
I_CompSize = NumCells*(1 - GrowthFraction*((1/InitProliferativeFraction)...
    + CellLossFactor*(CellLossHalftime/CellCycleTime)))*ones(1,vlength);
H_CompSize = NumCells*(CellLossFactor*GrowthFraction*(CellLossHalftime/CellCycleTime))...
    *ones(1,vlength);

if any(I_CompSize < 0)
    I_CompSize = zeros(1,vlength);
    H_CompSize = (NumCells - NumCells*(GrowthFraction/InitProliferativeFraction))*ones(1,vlength);
end

%% Cell distribution in each compartment (Initially all compartments fully filled with viable cells)

P_Viable = P_CompSize;
P_Doomed = zeros(1,vlength);
I_Viable = I_CompSize;
I_Doomed = zeros(1,vlength);
H_Viable = H_CompSize;
H_Doomed = zeros(1,vlength);
DeadComp = zeros(1,vlength);

ProliferativeFraction = InitProliferativeFraction*ones(1,vlength);

ProliferativeFraction_0 = ProliferativeFraction;


%% Begin model

% for m = 1:length(t_vec)
m = 1;
TotSurv = 1;
while m <= length(t_vec) || minSF <= min(TotSurv(:))
    
    
    TotSurv = zeros(1,length(DosePerFx));
    if m <= length(t_vec)
        t = t_vec(m);
    else
        t = t + t_interval;
    end

%% Change in f_p_pro (k_p) as blood supply improves
%     ProliferativeFraction = 1 - ProliferativeFraction.*(P_Viable + P_Doomed)./P_CompSize; 
    ProliferativeFraction = 1 - (1 - ProliferativeFraction_0).*(P_Viable + P_Doomed)./P_CompSize;   
    trt_points(m) = 0;
    if (m <= length(t_vec) && any(t == TreatmentSchedule)) || (m > length(t_vec) && mod(t,24) == 0 ...
        && ~mod(t-120,7*24) == 0 && ~mod(t-144,7*24) == 0)                                          %AI 9/21/17
     
        trt_points(m) = 1;
        
        P_RemFraction = exp(-Alpha_pComp*UsedDosePerFx-Beta_pComp*UsedDosePerFx.^2);
        P_Doomed = P_Doomed + P_Viable.*(1 - P_RemFraction);
        P_Viable = P_Viable.*P_RemFraction;
        
        I_RemFraction = exp(-Alpha_iComp*UsedDosePerFx-Beta_iComp*UsedDosePerFx.^2);
        I_Doomed = I_Doomed + I_Viable.*(1 - I_RemFraction);
        I_Viable = I_Viable.*I_RemFraction;
        
        H_RemFraction = exp(-Alpha_hComp*UsedDosePerFx-Beta_hComp*UsedDosePerFx.^2);
        H_Doomed = H_Doomed + H_Viable.*(1 - H_RemFraction);
        H_Viable = H_Viable.*H_RemFraction;

    end    
    
%% Cell Proliferation & Death  
    P_Doomed_pre = P_Doomed;
    H_Total_pre = H_Viable + H_Doomed;
    
    P_Viable = P_Viable.*exp(log(2)*ProliferativeFraction*t_interval/CellCycleTime);                                             
    P_Doomed = P_Doomed.*exp(log(2)*ProliferativeFraction*(2*SurvivingFractionPostMitosis-1)*t_interval/CellCycleTime);
    
    H_Viable = H_Viable*(2)^(-t_interval/CellLossHalftime); 
    H_Doomed = H_Doomed*(2)^(-t_interval/CellLossHalftime); 
    
%% Mitotically dead cell in 1 time step
    MitoticDeath = (P_Doomed_pre - P_Doomed) + (H_Total_pre - (H_Viable + H_Doomed));
    DeadComp = DeadComp + MitoticDeath;
    DeadComp = DeadComp*(2)^(-t_interval/LysisHalftime);
    
    
%% Recompartmentalization of the cell
%%
    i1_1 = (P_Viable + P_Doomed >= P_CompSize);
    
        p_CompSize = P_CompSize(i1_1);
        p_Viable = P_Viable(i1_1);
        p_Doomed = P_Doomed(i1_1);
        i_Viable = I_Viable(i1_1);
        i_Doomed = I_Doomed(i1_1);
    
        p_Comp_Overflow = (p_Viable + p_Doomed) - p_CompSize;
        p_ViableFraction = p_Viable./(p_Viable + p_Doomed);
        p_Viable = p_CompSize.*p_ViableFraction;
        p_Doomed = p_CompSize - p_Viable;
        i_Viable = i_Viable + p_Comp_Overflow.*p_ViableFraction;
        i_Doomed = i_Doomed + p_Comp_Overflow.*(1-p_ViableFraction);
        
        P_Viable(i1_1) = p_Viable;
        P_Doomed(i1_1) = p_Doomed;
        I_Viable(i1_1) = i_Viable;
        I_Doomed(i1_1) = i_Doomed;
    
    
%%    
%     i1_011 = ~(P_Viable + P_Doomed >= P_CompSize) & logical(I_Viable + I_Doomed)...
%         & ((I_Viable + I_Doomed) > P_CompSize - (P_Viable + P_Doomed));
    i1_01 = ~i1_1 & logical(I_Viable + I_Doomed);
    i1_xx1 = ((I_Viable + I_Doomed) > P_CompSize - (P_Viable + P_Doomed));
    i1_011 = i1_01 & i1_xx1;

        p_CompSize = P_CompSize(i1_011);
        p_Viable = P_Viable(i1_011);
        p_Doomed = P_Doomed(i1_011);
        i_Viable = I_Viable(i1_011);
        i_Doomed = I_Doomed(i1_011);

        p_Comp_Empty = p_CompSize - (p_Viable + p_Doomed);
        i_ViableFraction = i_Viable./(i_Viable + i_Doomed);
        p_Viable = p_Viable + p_Comp_Empty.*i_ViableFraction;
        p_Doomed = p_CompSize - p_Viable;
        i_Viable = i_Viable - p_Comp_Empty.*i_ViableFraction;
        i_Doomed = i_Doomed - p_Comp_Empty.*(1-i_ViableFraction);

        P_Viable(i1_011) = p_Viable;
        P_Doomed(i1_011) = p_Doomed;
        I_Viable(i1_011) = i_Viable;
        I_Doomed(i1_011) = i_Doomed;
                   

%%        
%     i1_010 = ~(P_Viable + P_Doomed >= P_CompSize) & logical(I_Viable + I_Doomed)...
%         & ~((I_Viable + I_Doomed) > P_CompSize - (P_Viable + P_Doomed));
    i1_010 = i1_01 & ~i1_xx1;

        p_Viable = P_Viable(i1_010);
        p_Doomed = P_Doomed(i1_010);
        i_Viable = I_Viable(i1_010);
        i_Doomed = I_Doomed(i1_010);    
    
        p_Viable = p_Viable + i_Viable;
        p_Doomed = p_Doomed + i_Doomed;
        i_Viable = zeros(size(i_Viable));
        i_Doomed = zeros(size(i_Doomed));
    
        P_Viable(i1_010) = p_Viable;
        P_Doomed(i1_010) = p_Doomed;
        I_Viable(i1_010) = i_Viable;
        I_Doomed(i1_010) = i_Doomed;
        
    
%%        
%     i1_01011 = ~(P_Viable + P_Doomed >= P_CompSize) & logical(I_Viable + I_Doomed)...
%         & ~((I_Viable + I_Doomed) > P_CompSize - (P_Viable + P_Doomed))...
%         & logical(H_Viable + H_Doomed) & ((H_Viable + H_Doomed) > P_CompSize - (P_Viable+P_Doomed));
    i1_0101 = i1_010 & logical(H_Viable + H_Doomed);
    i1_xxxx1 = ((H_Viable + H_Doomed) > P_CompSize - (P_Viable+P_Doomed));
    i1_01011 = i1_0101 & i1_xxxx1;
 
        p_CompSize = P_CompSize(i1_01011);
        p_Viable = P_Viable(i1_01011);
        p_Doomed = P_Doomed(i1_01011);
        h_Viable = H_Viable(i1_01011);
        h_Doomed = H_Doomed(i1_01011);
    
        p_Comp_Empty = p_CompSize - (p_Viable + p_Doomed);
        h_ViableFraction = h_Viable./(h_Viable + h_Doomed);
        p_Viable = p_Viable + p_Comp_Empty.*h_ViableFraction;
        p_Doomed = p_CompSize - p_Viable;
        h_Viable = h_Viable - p_Comp_Empty.*h_ViableFraction;
        h_Doomed = h_Doomed - p_Comp_Empty.*(1 - h_ViableFraction);
        
        P_Viable(i1_01011) = p_Viable;
        P_Doomed(i1_01011) = p_Doomed;
        H_Viable(i1_01011) = h_Viable;
        H_Doomed(i1_01011) = h_Doomed;
        
    
 
%%    
%     i1_01010 = ~(P_Viable + P_Doomed >= P_CompSize) & logical(I_Viable + I_Doomed)...
%         & ~((I_Viable + I_Doomed) > P_CompSize - (P_Viable + P_Doomed))...
%         & logical(H_Viable + H_Doomed) & ~((H_Viable + H_Doomed) > P_CompSize - (P_Viable+P_Doomed));
    i1_01010 = i1_0101 & ~i1_xxxx1;
  
        p_Viable = P_Viable(i1_01010);
        p_Doomed = P_Doomed(i1_01010);
        h_Viable = H_Viable(i1_01010);
        h_Doomed = H_Doomed(i1_01010);
    
        p_Viable = p_Viable + h_Viable;
        p_Doomed = p_Doomed + h_Doomed;
        h_Viable = zeros(size(h_Viable));
        h_Doomed = zeros(size(h_Doomed));
        
        P_Viable(i1_01010) = p_Viable;
        P_Doomed(i1_01010) = p_Doomed;
        H_Viable(i1_01010) = h_Viable;
        H_Doomed(i1_01010) = h_Doomed;
    

%%        
    i2_1 = (I_Viable + I_Doomed >= I_CompSize);
    
        i_CompSize = I_CompSize(i2_1);
        i_Viable = I_Viable(i2_1);
        i_Doomed = I_Doomed(i2_1);
        h_Viable = H_Viable(i2_1);
        h_Doomed = H_Doomed(i2_1);
    
        i_Comp_Overflow = (i_Viable + i_Doomed) - i_CompSize;
        i_ViableFraction = i_Viable./(i_Viable + i_Doomed);
        i_Viable = i_CompSize.*i_ViableFraction;
        i_Doomed = i_CompSize - i_Viable;
        h_Viable = h_Viable + i_Comp_Overflow.*i_ViableFraction;
        h_Doomed = h_Doomed + i_Comp_Overflow.*(1 - i_ViableFraction);
        
        I_Viable(i2_1) = i_Viable;
        I_Doomed(i2_1) = i_Doomed;
        H_Viable(i2_1) = h_Viable;
        H_Doomed(i2_1) = h_Doomed;


%%        
%     i2_011 = ~(I_Viable + I_Doomed >= I_CompSize) & logical(H_Viable + H_Doomed)...
%         & ((H_Viable + H_Doomed) > (I_CompSize - (I_Viable + I_Doomed)));
    i2_01 = ~i2_1 & logical(H_Viable + H_Doomed);
    i2_xx1 = ((H_Viable + H_Doomed) > (I_CompSize - (I_Viable + I_Doomed)));
    i2_011 = i2_01 & i2_xx1;  
    
        i_CompSize = I_CompSize(i2_011);
        i_Viable = I_Viable(i2_011);
        i_Doomed = I_Doomed(i2_011);
        h_Viable = H_Viable(i2_011);
        h_Doomed = H_Doomed(i2_011);    
    
        i_Comp_Empty = i_CompSize - (i_Viable + i_Doomed);
        h_ViableFraction = h_Viable./(h_Viable + h_Doomed);
        i_Viable = i_Viable + i_Comp_Empty.*h_ViableFraction;
        i_Doomed = i_CompSize - i_Viable;  
        h_Viable = h_Viable - i_Comp_Empty.*h_ViableFraction;
        h_Doomed = h_Doomed - i_Comp_Empty.*(1 - h_ViableFraction);
        
        I_Viable(i2_011) = i_Viable;
        I_Doomed(i2_011) = i_Doomed;
        H_Viable(i2_011) = h_Viable;
        H_Doomed(i2_011) = h_Doomed;
    

%%        
%     i2_010 = ~(I_Viable + I_Doomed >= I_CompSize) & logical(H_Viable + H_Doomed)...
%         & ~((H_Viable + H_Doomed) > (I_CompSize - (I_Viable + I_Doomed)));
    i2_010 = i2_01 & ~i2_xx1;
    
        i_Viable = I_Viable(i2_010);
        i_Doomed = I_Doomed(i2_010);
        h_Viable = H_Viable(i2_010);
        h_Doomed = H_Doomed(i2_010);
    
        i_Viable = i_Viable + h_Viable;
        i_Doomed = i_Doomed + h_Doomed;
        h_Viable = zeros(size(h_Viable));
        h_Doomed = zeros(size(h_Doomed));
  
        I_Viable(i2_010) = i_Viable;
        I_Doomed(i2_010) = i_Doomed;
        H_Viable(i2_010) = h_Viable;
        H_Doomed(i2_010) = h_Doomed;
        
        

%%

%% Sum Check
%     if any(((P_Viable + P_Doomed) < P_CompSize) & (((I_Viable + I_Doomed) > 0) | ((H_Viable + H_Doomed) > 0)))
%     if any((P_CompSize - (P_Viable + P_Doomed) > 1) & (((I_Viable + I_Doomed) > 0) | ((H_Viable + H_Doomed) > 0)))
%         disp('hi')
%         error('P Compartment mismatch')
%     end
%     if any((I_CompSize - (I_Viable + I_Doomed) > 1) & (H_Viable + H_Doomed) > 0)
%         error('I Compartment mismatch')
%     end
%%
    
    UsedTotSurv = P_Viable + I_Viable + H_Viable;
    TotSurv(~EmptyDVHs) = UsedTotSurv;
    TotSurv = TotSurv/InitialNumCells;
    SurvivingFraction_t(m,:) = TotSurv;
    
    m = m + 1;

end

if (m-1) > length(t_vec)
    t_vec = 0:t_interval:t_interval*(m-2); %AI 9/18/17
    t_vec = t_vec';
end

SurvivingFraction = SurvivingFraction_t(end,:);
