function [dH,meanSurfDist] = hausdorff( A, B) 
%% Hausdorff Distance: Compute the Hausdorff distance between two point clouds.
% Let A and B be subsets of a metric space (Z,dZ), 
% The Hausdorff distance between A and B, denoted by dH (A, B), is defined by:
% dH (A, B)=max{sup dz(a,B), sup dz(b,A)}, for all a in A, b in B,
% dH(A, B) = max(h(A, B),h(B, A)),  
% where h(A, B) = max(min(d(a, b))),  
% and d(a, b) is a L2 norm. 
% dist_H = hausdorff( A, B ) 
% A: First point sets. 
% B: Second point sets. 
% ** A and B may have different number of rows, but must have the same number of columns. ** 
% Hassan RADVAR-ESFAHLAN; Universit du Qubec; TS; Montral; CANADA 
% 15.06.2010

%%
if(size(A,2) ~= size(B,2)) 
    fprintf( 'WARNING: dimensionality must be the same\n' ); 
    dH = []; 
    return; 
end
% dH = max(compute_dist(A, B), compute_dist(B, A));
[distAb95,sumDistAb] = compute_dist(A, B);
[distBa95,sumDistBa] = compute_dist(B, A);
dH = max(distAb95, distBa95);
meanSurfDist = (sumDistAb + sumDistBa)/(size(A,1)+size(B,1));

%% Compute distance
function [dist,sumDist] = compute_dist(A, B) 
m = size(A, 1); 
n = size(B, 1); 
dim= size(A, 2); 
for k = 1:m 
    C = ones(n, 1) * A(k, :); 
    D = (C-B) .* (C-B); 
    D = sqrt(D * ones(dim,1)); 
    dist(k) = min(D); 
end
sumDist = sum(dist);
%dist = max(dist);
dist = quantile(dist,0.95);
