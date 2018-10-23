function planC = createStapleStruct(structNumV,probCutoff,structureName,planC)
% function planC = createStapleStruct(structNumV,probCutoff,structureName,planC)
%
% Function to create STAPLE agreement structure at the passed probability
% probCutoff.
%
% APA, 11/13/2017

if ~exist('planC','var')
    global planC
end
indexS = planC{end};

scanNum = getStructureAssociatedScan(structNumV(1),planC);
numObs = length(structNumV);
siz = getUniformScanSize(planC{indexS.scan}(scanNum));
rateMatM = false(prod(siz),numObs);
for i=1:numObs
    mask3M = getUniformStr(structNumV(i),planC);
    rateMatM(:,i) = mask3M(:);
end
indV = sum(rateMatM,2) > 0;
rateMatM = rateMatM(indV,:);

iterlim=100;
senstart=0.9999*ones(1,numObs);
specstart=0.9999*ones(1,numObs);
[stapleV, sen, spec, Sall] = staple(rateMatM,iterlim, single(senstart), single(specstart));

staple3M = zeros(siz);
staple3M(indV) = stapleV;
newStrMask3M = staple3M >= probCutoff;

planC = maskToCERRStructure(newStrMask3M, 1, scanNum, structureName, planC);
