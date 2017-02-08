function ntcp = logitFn(paramS,doseBinsV,volHistV)

%Get parameters
D50 = paramS.D50;
gamma50 = paramS.gamma50;

%mean dose for selected struct/dose
meanDoseCalc = calc_meanDose(doseBinsV, volHistV);

%Compute NTCP
ntcp = 1./(1+exp(4*gamma50*(1-meanDoseCalc/D50)));

end