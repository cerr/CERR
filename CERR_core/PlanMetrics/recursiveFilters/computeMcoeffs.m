function coeffS = computeMcoeffs(coeffS,symmetric)
% function coeffS = computeMcoeffs(coeffS,symmetric)
%
% APA, 6/11/2018

if ~exist('symmetric','var')
    symmetric = true;
end

%% ComputeRemainingCoefficients(bool symmetric)

if symmetric
    
    coeffS.M1 = coeffS.N1 - coeffS.D1 * coeffS.N0;
    coeffS.M2 = coeffS.N2 - coeffS.D2 * coeffS.N0;
    coeffS.M3 = coeffS.N3 - coeffS.D3 * coeffS.N0;
    coeffS.M4 = -coeffS.D4 * coeffS.N0;
        
else
    
   coeffS.M1 = -( coeffS.N1 - coeffS.D1 * coeffS.N0 );
   coeffS.M2 = -( coeffS.N2 - coeffS.D2 * coeffS.N0 );
   coeffS.M3 = -( coeffS.N3 - coeffS.D3 * coeffS.N0 );
   coeffS.M4 = coeffS.D4 * coeffS.N0;
end
    
% Compute coefficients to be used at the boundaries ...
% in order to simulate edge extension boundary conditions.
coeffS.SN = coeffS.N0 + coeffS.N1 + coeffS.N2 + coeffS.N3;
coeffS.SM = coeffS.M1 + coeffS.M2 + coeffS.M3 + coeffS.M4;
coeffS.SD = 1.0 + coeffS.D1 + coeffS.D2 + coeffS.D3 + coeffS.D4;
    
coeffS.BN1 = coeffS.D1 * coeffS.SN / coeffS.SD;
coeffS.BN2 = coeffS.D2 * coeffS.SN / coeffS.SD;
coeffS.BN3 = coeffS.D3 * coeffS.SN / coeffS.SD;
coeffS.BN4 = coeffS.D4 * coeffS.SN / coeffS.SD;
    
coeffS.BM1 = coeffS.D1 * coeffS.SM / coeffS.SD;
coeffS.BM2 = coeffS.D2 * coeffS.SM / coeffS.SD;
coeffS.BM3 = coeffS.D3 * coeffS.SM / coeffS.SD;
coeffS.BM4 = coeffS.D4 * coeffS.SM / coeffS.SD;
