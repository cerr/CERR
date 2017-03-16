function featuresS = ngldmToScalarFeatures(s)
% function featuresS = ngldmToScalarFeatures(s)
% 
% APA, 03/16/2017

% Coarseness
Ns = sum(s(:));
Nn = size(s,2);
Ng = size(s,1);

% Low dependence emphasis
sLdeM = bsxfun(@rdivide,s,(1:Nn).^2);
featuresS.lde = sum(sLdeM(:))/Ns;

% High dependence emphasis
sHdeM = bsxfun(@times,s,(1:Nn).^2);
featuresS.hde = sum(sHdeM(:))/Ns;

% Low grey level count emphasis
sLgceM = bsxfun(@rdivide,s',(1:Ng).^2);
featuresS.lgce = sum(sLgceM(:))/Ns;

% High grey level count emphasis
sHgceM = bsxfun(@times,s',(1:Ng).^2);
featuresS.hgce = sum(sHgceM(:))/Ns;

% Low dependence low grey level emphasis
sLdlgeM = bsxfun(@rdivide,bsxfun(@rdivide,s,(1:Nn).^2)',(1:Ng).^2);
featuresS.ldlge = sum(sLdlgeM(:))/Ns;

% Low dependence high grey level emphasis


% High dependence low grey level emphasis

% High dependence high grey level emphasis

% Grey level non-uniformity

% Grey level non-uniformity normalised

% Dependence count non-uniformity

% Dependence count non-uniformity normalised

% Dependence count percentage

% Grey level variance

% Dependence count variance

% Dependence count entropy

% Dependence count energy







