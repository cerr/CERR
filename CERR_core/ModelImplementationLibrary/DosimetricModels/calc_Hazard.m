function H = calc_Hazard(H0,betaV,dkV)
%Hazard calculated using Cox model
%AI 04/20/22

H = H0*exp(sum(betaV.*dkV));

end