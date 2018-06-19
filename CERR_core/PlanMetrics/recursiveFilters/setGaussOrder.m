function coeffS = setGaussOrder(coeffS,derivativeOrder)
% function coeffS = setOrder(coeffS,derivativeOrder)
%
% APA, 6/13/2018

A1(1) = 1.3530;
B1(1) = 1.8151;
coeffS.W1    = 0.6681;
coeffS.L1    = -1.3932;
A2(1) = -0.3531;
B2(1) = 0.0902;
coeffS.W2    = 2.0787;
coeffS.L2    = -1.3732;

A1(2) = -0.6724;
B1(2) = -3.4327;
A2(2) = 0.6724;
B2(2) = 0.6100;

A1(3) = -1.3563;
B1(3) = 5.2318;
A2(3) = 0.3446;
B2(3) = -2.2355;


switch derivativeOrder
    
    case 'zero'
        % Zero'th order (Gaussian)
        coeffS.across_scale_normalization = 1.0;
        
        coeffS = computeDcoeffs(coeffS);
        
        coeffS.A1 = A1(1);
        coeffS.B1 = B1(1);
        coeffS.A2 = A2(1);
        coeffS.B2 = B2(1);
        coeffS = computeNcoeffs(coeffS);
        coeffS.alpha0 = 2 * coeffS.SN / coeffS.SD - coeffS.N0;
        coeffS.N0 = coeffS.N0 * coeffS.across_scale_normalization / coeffS.alpha0;
        coeffS.N1 = coeffS.N1 * coeffS.across_scale_normalization / coeffS.alpha0;
        coeffS.N2 = coeffS.N2 * coeffS.across_scale_normalization / coeffS.alpha0;
        coeffS.N3 = coeffS.N3 * coeffS.across_scale_normalization / coeffS.alpha0;
        symmetric = true;
        coeffS = computeMcoeffs(coeffS,symmetric);
                
        
    case 'second'
        
       
        % Second order (Laplacian Of Gaussian)
        %coeffS.across_scale_normalization = coeffS.sigma^2;
        coeffS.across_scale_normalization = 1.0;
        
        coeffS = computeDcoeffs(coeffS);
        
        coeffS.A1 = A1(1);
        coeffS.B1 = B1(1);
        coeffS.A2 = A2(1);
        coeffS.B2 = B2(1);
        coeffS.N0 = 0;
        coeffS.N1 = 0;
        coeffS.N2 = 0;
        coeffS.N3 = 0;
        coeffS.SN = 0;
        coeffS.DN = 0;
        coeffS.EN = 0;
        coeffS = computeNcoeffs(coeffS);
        coeffS.N0_0 = coeffS.N0;
        coeffS.N1_0 = coeffS.N1;
        coeffS.N2_0 = coeffS.N2;
        coeffS.N3_0 = coeffS.N3;
        coeffS.SN0 = coeffS.SN;
        coeffS.DN0 = coeffS.DN;
        coeffS.EN0 = coeffS.EN;
        
        coeffS.A1 = A1(3);
        coeffS.B1 = B1(3);
        coeffS.A2 = A2(3);
        coeffS.B2 = B2(3);
        coeffS.N0 = 0;
        coeffS.N1 = 0;
        coeffS.N2 = 0;
        coeffS.N3 = 0;
        coeffS.SN = 0;
        coeffS.DN = 0;
        coeffS.EN = 0;
        coeffS = computeNcoeffs(coeffS);
        coeffS.N0_2 = coeffS.N0;
        coeffS.N1_2 = coeffS.N1;
        coeffS.N2_2 = coeffS.N2;
        coeffS.N3_2 = coeffS.N3;
        coeffS.SN2 = coeffS.SN;
        coeffS.DN2 = coeffS.DN;
        coeffS.EN2 = coeffS.EN;
        
        
        coeffS.beta = -( 2 * coeffS.SN2 - coeffS.SD * coeffS.N0_2 ) / ( 2 * coeffS.SN0 - coeffS.SD * coeffS.N0_0 );
        coeffS.N0 = coeffS.N0_2 + coeffS.beta * coeffS.N0_0;
        coeffS.N1 = coeffS.N1_2 + coeffS.beta * coeffS.N1_0;
        coeffS.N2 = coeffS.N2_2 + coeffS.beta * coeffS.N2_0;
        coeffS.N3 = coeffS.N3_2 + coeffS.beta * coeffS.N3_0;
        coeffS.SN = coeffS.SN2 + coeffS.beta * coeffS.SN0;
        coeffS.DN = coeffS.DN2 + coeffS.beta * coeffS.DN0;
        coeffS.EN = coeffS.EN2 + coeffS.beta * coeffS.EN0;
        
        coeffS.alpha2  = coeffS.EN * coeffS.SD * coeffS.SD - ...
            coeffS.ED * coeffS.SN * coeffS.SD - ...
            2 * coeffS.DN * coeffS.DD * coeffS.SD + ...
            2 * coeffS.DD * coeffS.DD * coeffS.SN;
        
        coeffS.alpha2 = coeffS.alpha2 / (coeffS.SD * coeffS.SD * coeffS.SD);
        
        coeffS.N0 = coeffS.N0 * coeffS.across_scale_normalization / coeffS.alpha2;
        coeffS.N1 = coeffS.N1 * coeffS.across_scale_normalization / coeffS.alpha2;
        coeffS.N2 = coeffS.N2 * coeffS.across_scale_normalization / coeffS.alpha2;
        coeffS.N3 = coeffS.N3 * coeffS.across_scale_normalization / coeffS.alpha2;
        
        symmetric = true;
        coeffS = computeMcoeffs(coeffS,symmetric);
                
end


