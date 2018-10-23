function coeffS = computeNcoeffs(coeffS)
% function computeNcoeffs(coeffS)
%
% APA, 6/11/2018

%% Compute the N coefficients
Sin1 = sin(coeffS.W1 / coeffS.sigmad);
Sin2 = sin(coeffS.W2 / coeffS.sigmad);
Cos1 = cos(coeffS.W1 / coeffS.sigmad);
Cos2 = cos(coeffS.W2 / coeffS.sigmad);
Exp1 = exp(coeffS.L1 / coeffS.sigmad);
Exp2 = exp(coeffS.L2 / coeffS.sigmad);

coeffS.N0  = coeffS.A1 + coeffS.A2;
coeffS.N1  = Exp2 * ( coeffS.B2 * Sin2 - ( coeffS.A2 + 2 * coeffS.A1 ) * Cos2 );
coeffS.N1 = coeffS.N1 + Exp1 * ( coeffS.B1 * Sin1 - ( coeffS.A1 + 2 * coeffS.A2 ) * Cos1 );
coeffS.N2  = ( coeffS.A1 + coeffS.A2 ) * Cos2 * Cos1;
coeffS.N2 = coeffS.N2 - (coeffS.B1 * Cos2 * Sin1 + coeffS.B2 * Cos1 * Sin2);
coeffS.N2 = coeffS.N2 * (2 * Exp1 * Exp2);
coeffS.N2 = coeffS.N2 + coeffS.A2 * Exp1 * Exp1 + coeffS.A1 * Exp2 * Exp2;
coeffS.N3  = Exp2 * Exp1 * Exp1 * ( coeffS.B2 * Sin2 - coeffS.A2 * Cos2 );
coeffS.N3 = coeffS.N3 + Exp1 * Exp2 * Exp2 * ( coeffS.B1 * Sin1 - coeffS.A1 * Cos1 );

coeffS.SN = coeffS.N0 + coeffS.N1 + coeffS.N2 + coeffS.N3;
coeffS.DN = coeffS.N1 + 2 * coeffS.N2 + 3 * coeffS.N3;
coeffS.EN = coeffS.N1 + 4 * coeffS.N2 + 9 * coeffS.N3;
