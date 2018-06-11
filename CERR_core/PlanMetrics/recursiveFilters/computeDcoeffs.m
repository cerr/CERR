function coeffS = computeDcoeffs(coeffS)
% function coeffS = computeDcoeffs(coeffS)
%
% APA, 6/11/2018


%% Compute the D coefficients
Cos1 = cos(coeffS.W1 / coeffS.sigmad);
Cos2 = cos(coeffS.W2 / coeffS.sigmad);
Exp1 = exp(coeffS.L1 / coeffS.sigmad);
Exp2 = exp(coeffS.L2 / coeffS.sigmad);

coeffS.D4 = Exp1 * Exp1 * Exp2 * Exp2;
coeffS.D3 = -2 * Cos1 * Exp1 * Exp2 * Exp2;
coeffS.D3 = coeffS.D3 + -2 * Cos2 * Exp2 * Exp1 * Exp1;
coeffS.D2 = 4 * Cos2 * Cos1 * Exp1 * Exp2;
coeffS.D2 = coeffS.D2 + Exp1 * Exp1 + Exp2 * Exp2;
coeffS.D1 = -2 * ( Exp2 * Cos2 + Exp1 * Cos1 );

coeffS.SD = 1.0 + coeffS.D1 + coeffS.D2 + coeffS.D3 + coeffS.D4;
coeffS.DD = coeffS.D1 + 2 * coeffS.D2 + 3 * coeffS.D3 + 4 * coeffS.D4;
coeffS.ED = coeffS.D1 + 4 * coeffS.D2 + 9 * coeffS.D3 + 16 * coeffS.D4;

