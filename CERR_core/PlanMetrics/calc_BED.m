function BED = calc_BED(paramS,varargin)
%BED = calc_BED(paramS)
%Ref: Comparison Between Mechanistic Radiobiological Modeling Vs. 
%Fowler BED Equation in Evaluating Lung Cancer Radiotherapy Outcome 
%for a Broad Range of Fractionation, J Jeong et al., AAPM 2017
%-----------------------------------------------------------------------
% INPUTS
% paramS : Parameter dictionary with fields:
%          d  - Fraction size
%          n  - No. fractions
%          T  - No. treatment days
%          alpha
%          abRatio
% Note : For a 3D dose distibution, calculate 3D BED by setting input 
%        paramS.frxSize.val = doseArray3M/numFrx
%-----------------------------------------------------------------------
% AI 12/4/17
% AI 07/30/18 Updated to handle 3D dose distibution
            

%Define constants  
Tk = paramS.Tk.val;         %Kick-off time of repopulation (days)
Tp =  paramS.Tp.val;        %Potential tumor doubling time (days)


alpha = paramS.alpha.val;    
abRatio = paramS.abRatio.val;  %alpha/beta for tumor
d = paramS.frxSize.val;
n = paramS.numFractions.val;
T = floor(n/5)*7 + mod(n,5);


%Compute BED
BED = n.* d .* (1 + d./abRatio);
if T > Tk
  BED = BED -  log(2) * (T-Tk)/(alpha*Tp);
end
   
    

end