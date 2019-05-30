function aifC = fGenerateParkerAIF(tsecV, coefFile)
% fGenerateParkerAIF.m
%
% INPUTS
% coefFile : .txt file with Parker AIF coefficients that the user has generated previously
%            from patient AIF data (parameters are per minute).
% tsecV    : Vector of time points at which Parker AIF values will be generated
% ----------------------------------------------------------------------------------------- 
% Ref : Parker et al MRM 2006;56:993-1000
% The AIF curve consists of the sum of two gaussian functions plus the
% product of a decaying exponential and a sigmoid function
% a1 and a2 are the scaling constants for the Gaussians: units mmol-min
% T1 and T2 are the centers of the Gaussians
% sigma1 and sigma2 are the widths of the Gaussians in minutes
% alpha and beta are the amplitude and decay constant of the exponential
% alpha units are mmol
% s and tau are the width and center of the sigmoid function
% -----------------------------------------------------------------------------------------
% 
% Kristen Zakian

%Generate time array in minutes
t = tsecV/60;                                    

%Read in Parker coefs
celRange = [0 0 9 0];                           % cel range uses array convention that 1st cel is 0 0
                                                % so Row 2, col 3 is (1,2), etc.
                                
pCoefs = dlmread(coefFile,'\t', celRange);      % read in Parker coefs

%Get AIF
aifC = parkerAIF(pCoefs,t);

%% AIF curve function
function y = parkerAIF(p,t)

a1 = p(1);
T1 = p(2);
sigma1 = p(3);
a2 = p(4);
T2 = p(5);
sigma2 = p(6);
alpha = p(7);
beta = p(8);
s = p(9);
tau = p(10);


y = (a1/sigma1/sqrt(2*pi))*exp(-(t-T1).*(t-T1)/(2*sigma1*sigma1))+...
    (a2/sigma2/sqrt(2*pi))*exp(-(t-T2).*(t-T2)/(2*sigma2*sigma2))+...
    alpha*exp(-beta*t)./(1+exp(-s*(t-tau)));

%plot (t,y);
%title('Parker function at current time points in minutes');
end

end