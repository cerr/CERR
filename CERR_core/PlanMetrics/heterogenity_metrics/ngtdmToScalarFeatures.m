function featuresS = ngtdmToScalarFeatures(s,p,numVoxels)
% function featuresS = ngtdmToScalarFeatures(s,p,numVoxels)
% 
% APA, 3/15/2017

% Coarseness
featuresS.coarseness = 1/(sum(s .* p) + 1e-6);

% Contrast
Ng = sum(p > 0);
numLevels = length(p);
indV = (1:numLevels)';
term1 = 0;
term2 = 0;
for lev = 1:numLevels
    term1 = term1 + ...
        sum(p .* circshift(p,lev) .* (indV-circshift(indV,lev)).^2);
    term2 = term2 + s(lev);
end
featuresS.contrast = 1/Ng/(Ng-1) * term1 * term2 / numVoxels;

% Busyness
denom = 0;
for lev = 1:numLevels
    pShiftV = circshift(p,lev);
    indShiftV = circshift(indV,lev);    
    usePv = p > 0;
    usePshiftV = pShiftV > 0;
    denom = denom + ...
        sum(usePv .* usePshiftV .* abs(p .* indV - pShiftV .* indShiftV));
end
featuresS.busyness = sum(p .* s) / denom;

% Complexity
complxty = 0;
for lev = 1:numLevels
    pShiftV = circshift(p,lev);
    sShiftV = circshift(s,lev);
    indShiftV = circshift(indV,lev);
    usePv = p > 0;
    usePshiftV = pShiftV > 0;    
    term1 = abs(indV - indShiftV);
    term2 = usePv .* usePshiftV .* (p .* s + pShiftV .* sShiftV)...
        ./ (p + pShiftV + eps);
    complxty = complxty + sum(term1 .* term2);
end
featuresS.complexity = complxty / numVoxels;

% Texture strength
strength = 0;
for lev = 1:numLevels
    pShiftV = circshift(p,lev);
    indShiftV = circshift(indV,lev);
    usePv = p > 0;
    usePshiftV = pShiftV > 0;        
    term = sum(usePv .* usePshiftV .* (p + pShiftV) .* (indV - indShiftV).^2);
    strength = strength + term;
end
featuresS.strength = strength / sum(s);

