% Sean Walsh TCP model for prostate
% http://dx.doi.org/10.1118/1.4939260
%
% APA, 07/20/2016

alpha = 0.25;
beta = 0.1008;
sigmaAlpha = alpha*11.3/100;
sigmaBeta = beta*12.9/100;
dilVolume = 10; %percent,
hypoxicFraction = 0.15; %percent,
OER = 1.75; % Oxygen Enhancement Ratio
pCTV = 10^5; % Prostate density
pDIL = 10^6; % DIL density
ctvVolume = 36; % cm^3 for intermediate risk patients
%ctvVolume = 72; % cm^3 for high risk patients
dProst = 2; % dose per fraction to the prostate
dDIL = 2; % dose per fraction to the dominant lesion
n = 39; % number of fractions
numSimulations = 100000; % number of (alpha,beta) simulations

% vary fractional dose to the DIL from 2 to 3.
dDILv = linspace(2,3,100);

% seed the random generator
rng(now,'twister')

% Loop over DIL dose
for i = 1:100
    
    % dose per fraction for the DIL
    dDIL = dDILv(i);
    
    % generate normally distributed, positive aplha and beta
    alphaV = alpha + randn(numSimulations*2, 1) * sigmaAlpha;
    betaV = beta + randn(numSimulations*2, 1) * sigmaBeta;
    alphaV = alphaV(alphaV > 0);
    betaV = betaV(betaV > 0);
    alphaV = alphaV(1:numSimulations);
    betaV = betaV(1:numSimulations);
    
    % hypoxic cells alpha,beta
    alphaPO2 = alphaV / OER;
    betaPO2 = betaV / OER^2;
    
    % total initial clonogen number
    N0 = ((100-dilVolume)*pCTV + dilVolume*pDIL) / 100 * ctvVolume;
    
    % initial number of clonogens in prostate
    Nprost = (100-dilVolume)*pCTV / 100 * ctvVolume;
    
    % initial number of clonogens in DIL
    Ndil = dilVolume*pDIL / 100 * ctvVolume;    
    
    % surviving fraction for Prostate
    SProstateV = exp(-alphaV*n*dProst -betaV*n*dProst^2);
    
    % surviving fraction for hypoxic Prostate
    ShypoxicProstateV = exp(-alphaPO2*n*dProst -betaPO2*n*dProst^2);
    
    % surviving fraction for DIL
    SdilV = exp(-alphaV*n*dDIL -betaV*n*dDIL^2);
    
    % surviving fraction for hypoxic DIL
    ShypoxicDilV = exp(-alphaPO2*n*dDIL -betaPO2*n*dDIL^2);
    
    % total surviving clonogens
    NumSurvivingV = Nprost*(1-hypoxicFraction)*SProstateV + ...
        Nprost*hypoxicFraction*ShypoxicProstateV + ...
        Ndil*(1-hypoxicFraction)*SdilV +  ...
        Ndil*hypoxicFraction*ShypoxicDilV;
        
    % TCP
    TCPv = exp(-NumSurvivingV);
    
    % record the TCP for this DIL dose
    tcpWithBoostV(i) = mean(TCPv);
    
end

figure, plot(dDILv,tcpWithBoostV)
xlabel('dose per fraction to the dominant lesion')
ylabel('TCP')
title('Effect of simultaneous boosting the dominant lesion')
set(gca,'fontsize',14)

