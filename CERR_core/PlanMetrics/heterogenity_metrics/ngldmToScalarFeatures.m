function featuresS = ngldmToScalarFeatures(s,numVoxels)
% function featuresS = ngldmToScalarFeatures(s,numVoxels)
% 
% APA, 03/16/2017

% Coarseness
Ns = sum(s(:));
Nn = size(s,2);
Ng = size(s,1);
lenV = 1:Nn;
levV = 1:Ng;

% Low dependence emphasis
sLdeM = bsxfun(@rdivide,s,lenV.^2);
featuresS.lde = sum(sLdeM(:))/Ns;

% High dependence emphasis
sHdeM = bsxfun(@times,s,lenV.^2);
featuresS.hde = sum(sHdeM(:))/Ns;

% Low grey level count emphasis
sLgceM = bsxfun(@rdivide,s',(1:Ng).^2);
featuresS.lgce = sum(sLgceM(:))/Ns;

% High grey level count emphasis
sHgceM = bsxfun(@times,s',(1:Ng).^2);
featuresS.hgce = sum(sHgceM(:))/Ns;

% Low dependence low grey level emphasis
sLdlgeM = bsxfun(@rdivide,bsxfun(@rdivide,s,lenV.^2)',(1:Ng).^2);
featuresS.ldlge = sum(sLdlgeM(:))/Ns;

% Low dependence high grey level emphasis
sLdhgeM = bsxfun(@times,bsxfun(@rdivide,s,lenV.^2)',(1:Ng).^2);
featuresS.ldhge = sum(sLdhgeM(:))/Ns;

% High dependence low grey level emphasis
sHdlgeM = bsxfun(@rdivide,bsxfun(@times,s,lenV.^2)',(1:Ng).^2);
featuresS.hdlge = sum(sHdlgeM(:))/Ns;

% High dependence high grey level emphasis
sHdhgeM = bsxfun(@times,bsxfun(@times,s,lenV.^2)',(1:Ng).^2);
featuresS.hdhge = sum(sHdhgeM(:))/Ns;

% Grey level non-uniformity
featuresS.gln = sum(sum(s,2).^2)/Ns;

% Grey level non-uniformity normalised
featuresS.glnNorm = sum(sum(s,2).^2)/Ns^2;

% Dependence count non-uniformity
featuresS.dcn = sum(sum(s,1).^2)/Ns;

% Dependence count non-uniformity normalised
featuresS.dcnNorm = sum(sum(s,1).^2)/Ns^2;

% Dependence count percentage
featuresS.dcp = Ns/numVoxels;

% Grey level variance
iPij = bsxfun(@times,s'/sum(s(:)),levV);
mu = sum(iPij(:));
iMinusMuPij = bsxfun(@times,s'/sum(s(:)),(levV-mu).^2);
featuresS.glv = sum(iMinusMuPij(:));

% Dependence count variance
jPij = bsxfun(@times,s/sum(s(:)),lenV);
mu = sum(jPij(:));
jMinusMuPij = bsxfun(@times,s/sum(s(:)),(lenV-mu).^2);
featuresS.dcv = sum(jMinusMuPij(:));

% Dependence count entropy
p = s(:)/sum(s(:));
featuresS.entropy = -sum(p .* log2(p+eps));

% Dependence count energy
p = s(:)/sum(s(:));
featuresS.energy = sum(p .^2);







