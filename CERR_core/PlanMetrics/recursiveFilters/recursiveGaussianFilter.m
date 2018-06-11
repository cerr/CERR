% recursiveGaussianFilter
%
% APA, 6/8/2018

%%
sigma = 3;
spacing = 1;

coeffS.sigmad = sigma / spacing;
coeffS.across_scale_normalization = 1.0;


coeffS.A1(1) = 1.3530;
coeffS.B1(1) = 1.8151;
coeffS.W1    = 0.6681;
coeffS.L1    = -1.3932;
coeffS.A2(1) = -0.3531;
coeffS.B2(1) = 0.0902;
coeffS.W2    = 2.0787;
coeffS.L2    = -1.3732;

coeffS.A1(2) = -0.6724;
coeffS.B1(2) = -3.4327;
coeffS.A2(2) = 0.6724;
coeffS.B2(2) = 0.6100;

coeffS.A1(3) = -1.3563;
coeffS.B1(3) = 5.2318;
coeffS.A2(3) = 0.3446;
coeffS.B2(3) = -2.2355;

% Zero'th order
coeffS = computeDcoeffs(coeffS);

coeffS.A1 = coeffS.A1(1);
coeffS.B1 = coeffS.B1(1);
coeffS.A2 = coeffS.A2(1);
coeffS.B2 = coeffS.B2(1);
coeffS = computeNcoeffs(coeffS);
coeffS.alpha0 = 2 * coeffS.SN / coeffS.SD - coeffS.N0;
coeffS.N0 = coeffS.N0 * coeffS.across_scale_normalization / coeffS.alpha0;
coeffS.N1 = coeffS.N1 * across_scale_normalization / coeffS.alpha0;
coeffS.N2 = coeffS.N2 * across_scale_normalization / coeffS.alpha0;
coeffS.N3 = coeffS.N3 * across_scale_normalization / coeffS.alpha0;
symmetric = true;
coeffS = computeMcoeffs(coeffS,symmetric);


xV = sin(linspace(0,5*2*pi,200));

% xV = zeros(61, 1);
% xV(31) = 10;
ykPlusV = xV*0;
ykMinusV = xV*0;


% Causal
ykPlusV(1) = coeffS.N0 * xV(1) + coeffS.N1 * xV(1) + coeffS.N2 * xV(1)...
    + coeffS.N3 * xV(1);
ykPlusV(2) = coeffS.N0 * xV(2) + coeffS.N1 * xV(1) + coeffS.N2 * xV(1)...
    + coeffS.N3 * xV(1);
ykPlusV(3) = coeffS.N0 * xV(3) + coeffS.N1 * xV(2) + coeffS.N2 * xV(1)...
    + coeffS.N3 * xV(1);
ykPlusV(4) = coeffS.N0 * xV(4) + coeffS.N1 * xV(3) + coeffS.N2 * xV(2)...
    + coeffS.N3 * xV(1);

ykPlusV(1) = coeffS.BN1 * xV(1) + coeffS.BN2 * xV(1) + coeffS.BN3 * xV(1)...
    + coeffS.BN4 * xV(1);
ykPlusV(2) = -coeffS.D1 * ykPlusV(1) + coeffS.BN2 * xV(1) + coeffS.BN3 * xV(1)...
    + coeffS.BN4 * xV(1);
ykPlusV(3) = -coeffS.D1 * ykPlusV(1) -+ coeffS.D2 * ykPlusV(2) + coeffS.BN3 * xV(1)...
    + coeffS.BN4 * xV(1);
ykPlusV(4) = -coeffS.D1 * ykPlusV(1) -+ coeffS.D2 * ykPlusV(2) -+ coeffS.D3 * ykPlusV(3)...
    + coeffS.BN4 * xV(1);

for ind = 5:length(xV)
    ykPlusV(ind) = coeffS.N0 * xV(ind) + coeffS.N1 * xV(ind-1) + coeffS.N2 * xV(ind-2)...
        + coeffS.N3 * xV(ind-3) -+ coeffS.D1 * ykPlusV(ind-1) -+ coeffS.D2 * ykPlusV(ind-2) ...
        -+ coeffS.D3 * ykPlusV(ind-3) -+ coeffS.D4 * ykPlusV(ind-4);
end

% Anticausal
ykMinusV(end) = coeffS.M1 * xV(end) + coeffS.M2 * xV(end) + coeffS.M3 * xV(end)...
    + coeffS.M4 * xV(end);
ykMinusV(end-1) = coeffS.M1 * xV(end) + coeffS.M2 * xV(end) + coeffS.M3 * xV(end)...
    + coeffS.M4 * xV(end);
ykMinusV(end-2) = coeffS.M1 * xV(end-1) + coeffS.M2 * xV(end-1) + coeffS.M3 * xV(end)...
    + coeffS.M4 * xV(end);
ykMinusV(end-3) = coeffS.M1 * xV(end-2) + coeffS.M2 * xV(end-2) + coeffS.M3 * xV(end-1)...
    + coeffS.M4 * xV(end);

ykMinusV(end) = coeffS.BM1 * xV(end) + coeffS.BM2 * xV(end) + coeffS.BM3 * xV(end)...
    + coeffS.BM4 * xV(end);
ykMinusV(end-1) = -coeffS.D1 * ykMinusV(end) + coeffS.BM2 * xV(end) + coeffS.BM3 * xV(end)...
    + coeffS.BM4 * xV(end);
ykMinusV(end-2) = -coeffS.D1 * ykMinusV(end-1) +- coeffS.D2 * ykMinusV(end) + coeffS.BM3 * xV(end)...
    + coeffS.BM4 * xV(end);
ykMinusV(end-3) = -coeffS.D1 * ykMinusV(end-2) +- coeffS.D2 * ykMinusV(end-1) +- coeffS.D3 * ykMinusV(end)...
    + coeffS.BM4 * xV(end);

for ind = length(xV)-4:-1:1
    ykMinusV(ind) = coeffS.M1 * xV(ind+1) + coeffS.M2 * xV(ind+2) + coeffS.M3 * xV(ind+3)...
    + coeffS.M4 * xV(ind+4) - coeffS.D1 * ykMinusV(ind+1) - coeffS.D2 * ykMinusV(ind+2) ...
     - coeffS.D3 * ykMinusV(ind+3) - coeffS.D4 * ykMinusV(ind+4);
end

yV = ykPlusV + ykMinusV;


figure, plot([xV(:) yV(:)])

