function ntcp = biexpFn(paramS,doseBinsC,volHistC)

%Get parameters
A = paramS.A.val;

%Mean dose to selected structures
meanDose1 = calc_meanDose(doseBinsC{1}, volHistC{1}); 
meanDose2 = calc_meanDose(doseBinsC{2}, volHistC{2}); 

%Compute NTCP
ntcp = 0.5*(exp(-A*meanDose1) + exp(-A*meanDose2));

end