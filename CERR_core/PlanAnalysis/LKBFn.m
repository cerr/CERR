function ntcp = LKBFn(paramS,doseBinsV,volHistV)

%Get parameters
D50 = paramS.D50.val;
m = paramS.m.val;
n = paramS.n.val;

%EUD for selected struct/dose
EUD = calc_EUD(doseBinsV, volHistV, 1/n);

%Compute NTCP
tmpv = (EUD - D50)/(m*D50);
ntcp = 1/2 * (1 + erf(tmpv/2^0.5));

end