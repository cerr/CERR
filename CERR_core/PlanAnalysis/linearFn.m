function ntcp = linearFn(paramS,doseBinsV,volHistV)

%Get parameters
intercept = paramS.intercept.val;
slope = paramS.slope.val;

%mean dose for selected struct/dose
meanDoseCalc = calc_meanDose(doseBinsV, volHistV);

%Compute NTCP
ntcp = intercept + slope*meanDoseCalc;

end