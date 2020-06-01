function PaV = calc_Pa(H0,betaV,dkV)
%Actuarial probability of complication using Cox model 

PaV = 1 - exp(-H0 .* exp(betaV.*dkV));


%Test-1:
% tol = 10^-5;
% expectedp10 = 0.1;
% H0=0.01;
% B = 0.05;
% d10 = 47.096;
% p10 = calc_Pa(H0,B,d10);
% assertAlmostEqual(p10,expectedp10,tol);

end