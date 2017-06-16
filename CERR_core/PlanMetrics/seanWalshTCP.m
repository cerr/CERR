function tcpWithBoost = seanWalshTCP(paramS,doseBinsV,volHistV)
% Sean Walsh TCP model for prostate
% http://dx.doi.org/10.1118/1.4939260
%
% APA, 07/20/2016
% AI, 09/12/16 Modified for use with outcomeModelsGUI


% Get parameters
alpha = paramS.alpha.val;
beta = paramS.beta.val;
sigmaAlpha = alpha*11.3/100;
sigmaBeta = beta*12.9/100;
dilVolume = paramS.dilVolume.val;             % percent
hypoxicFraction = paramS.hypoxicFraction.val; % percent
OER = paramS.OER.val;                         % Oxygen Enhancement Ratio
pCTV = paramS.pCTV.val;                       % Prostate density
pDIL = paramS.pDIL.val;                       % DIL density
ctvVolume = paramS.ctvVolume.val;             % 36 cm^3 for intermediate risk patients
                                              % ctvVolume = 72; % cm^3 for high risk patients
dDIL = paramS.dDIL.val;                       % dose per fraction to the DIL
n = paramS.numFractions.val;                  % number of fractions
numSimulations = paramS.numSimulations.val;   % number of (alpha,beta) simulations

%Compute mean dose to prostate
prost = calc_meanDose(doseBinsV,volHistV,1);
%Dose per fraction to the prostate
dProst = prost/n;

% Compute TCP
%Seed the random generator
rng(now,'twister');


%Generate normally distributed, positive aplha and beta
alphaV = alpha + randn(numSimulations*2, 1) * sigmaAlpha;
betaV = beta + randn(numSimulations*2, 1) * sigmaBeta;
alphaV = alphaV(alphaV > 0);
betaV = betaV(betaV > 0);
alphaV = alphaV(1:numSimulations);
betaV = betaV(1:numSimulations);

%Hypoxic cells alpha,beta
alphaPO2 = alphaV / OER;
betaPO2 = betaV / OER^2;

% Total initial clonogen number
N0 = ((100-dilVolume)*pCTV + dilVolume*pDIL) / 100 * ctvVolume;

%Initial number of clonogens in prostate
Nprost = (100-dilVolume)*pCTV / 100 * ctvVolume;

%Initial number of clonogens in DIL
Ndil = dilVolume*pDIL / 100 * ctvVolume;

%Surviving fraction for Prostate
SProstateV = exp(-alphaV*n*dProst -betaV*n*dProst^2);

%Surviving fraction for hypoxic Prostate
ShypoxicProstateV = exp(-alphaPO2*n*dProst -betaPO2*n*dProst^2);

%Surviving fraction for DIL
SdilV = exp(-alphaV*n*dDIL -betaV*n*dDIL^2);

%Surviving fraction for hypoxic DIL
ShypoxicDilV = exp(-alphaPO2*n*dDIL -betaPO2*n*dDIL^2);

%Total surviving clonogens
NumSurvivingV = Nprost*(1-hypoxicFraction)*SProstateV + ...
    Nprost*hypoxicFraction*ShypoxicProstateV + ...
    Ndil*(1-hypoxicFraction)*SdilV +  ...
    Ndil*hypoxicFraction*ShypoxicDilV;

% TCP
TCPv = exp(-NumSurvivingV);

%Record the TCP for this DIL dose
tcpWithBoost = mean(TCPv);

end

