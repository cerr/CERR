function BED = getBED(d,n,paramS)
%Ref: Comparison Between Mechanistic Radiobiological Modeling Vs. 
%Fowler BED Equation in Evaluating Lung Cancer Radiotherapy Outcome 
%for a Broad Range of Fractionation, J Jeong et al., AAPM 2017
%-----------------------------------------------------------------------
% INPUTS:
% n : No. fractions
% d : 
% paramS  : d,n read from paramS if empty
% AI 12/4/17

%Define constants
alpha = 0.35;  
Tk = 28;         %Kick-off time of repopulation (days)
Tp = 3;          %Potential tumor doubling time (days)
abRatio = 10;    %alpha/beta for tumor

%Get n, T from parameter dictionary
if isempty(n)
n = paramS.numFractions.val;
elseif isempty(d)
d = paramS.frxSize.val;
end
%T = paramS.T;
T = floor(n/5)*7 + mod(n,5);
%end

%Compute BED
BED = n*d*(1 + d/abRatio);
if T > Tk
  BED = BED -  log(2) * (T-Tk)/(alpha*Tp);
end
   
    

end