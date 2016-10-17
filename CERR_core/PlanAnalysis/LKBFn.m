function ntcp = LKBFn(paramS,doseBinsV,volHistV)

%Get parameters
D50 = paramS.D50;
m = paramS.m;
a = paramS.a;

%EUD for selected struct/dose
EUD = calc_EUD(doseBinsV, volHistV, a);

%Compute NTCP
tmpv = (EUD - D50)/(m*D50);
ntcp = 1/2 * (1 + erf(tmpv/2^0.5));

end