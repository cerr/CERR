function [apparent3M,staple3M,reliability3M] = calcConsensus(structAll, planC)
% function [apparent3M,staple3M,reliability3M] = calcConsensus(structAll, planC)
%
% This function returns the consesus between the passed structures with 
% three different methods: Apparent, Staple and Kappa-statistics
%
% Example Usage:
%
% global planC
% strNumsV = [1,4,7,10,13];
% [apparent3M,staple3M,reliability3M] = calcConsensus(strNumsV, planC);
% mask3M = staple3M >= 0.7;
% isUniform = 1;
% scanNum = getStructureAssociatedScan(strNumsV(1),planC);
% strname = 'STAPLE At 0.7 conf';
% planC = maskToCERRStructure(mask3M, isUniform, scanNum, strname, planC);

% APA, 07/30/2015

if ~ exist('planC','var')
    global planC
end

indexS = planC{end};

bigMask=zeros(getUniformScanSize(planC{indexS.scan}(1)),'int8');
for i=1:length(structAll)
    mask3M = getUniformStr(structAll(i));
    bigMask=bigMask | mask3M;
end
[iV,jV,kV]=find3d(bigMask);
iMin = min(iV);
iMax = max(iV);
jMin = min(jV);
jMax = max(jV);
kMin = min(kV);
kMax = max(kV);
clear iV kV jV bigMask

%averageMask3M = single(zeros([length(iMin:iMax) length(jMin:jMax) length(kMin:kMax)]));
averageMask3M = zeros([length(iMin:iMax) length(jMin:jMax) length(kMin:kMax)],'single');
%get clipped average mask for each volume
rateMat = logical([]);
for i=1:length(structAll)
    mask3M = getUniformStr(structAll(i));
    averageMask3M = averageMask3M + mask3M(iMin:iMax,jMin:jMax,kMin:kMax);
    temp=mask3M(iMin:iMax,jMin:jMax,kMin:kMax);
    rateMat=[rateMat,temp(:)];
end
clear mask3M
averageMask3M = averageMask3M/length(structAll);

scanNum = getStructureAssociatedScan(structAll(1), planC);

iterlim = 100;
senstart = 0.9999*ones(1,length(structAll));
specstart = 0.9999*ones(1,length(structAll));
[stapleV, sen, spec, Sall] = staple(rateMat,iterlim, single(senstart), single(specstart));
mean_sen = mean(sen);
std_sen = std(sen);
mean_spec = mean(spec);
std_spec = std(spec);
%get volume of an uniformized voxel
[xUnifV,yUnifV,zUnifV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
vol = (xUnifV(2)-xUnifV(1)) * (yUnifV(1)-yUnifV(2)) * (zUnifV(2)-zUnifV(1));
numBins = 20;
obsAgree = linspace(0.001,1,numBins);
rater_prob = mean(rateMat,1);
chance_prob = sqrt(rater_prob.*(1-rater_prob));
chance_prob_mat = repmat(chance_prob,size(rateMat,1),single(1));
reliabilityV = mean((rateMat-chance_prob_mat)./(1-chance_prob_mat),2);
%mean_chance_prob=mean(chance_prob);
clear rater_prob chance_prob chance_prob_mat

for i=1:length(obsAgree)
    %volV(i) = vol * length(find(averageMask3M(:) >= percentV(i)));
    %indAvg = find(averageMask3M(:) < obsAgree(i));
    volV(i)         = sum((averageMask3M(:) >= obsAgree(i))*vol);
    volStapleV(i)   = sum((stapleV(:) >= obsAgree(i))*vol);
    %kappa(i)=(obsAgree(i)-mean_chance_prob)/(1-mean_chance_prob);
    volKappaV(i)   = sum((reliabilityV(:) >= obsAgree(i))*vol);
end

%calculate overall kappa
[kappa,pval,k, pk]=kappa_stats(rateMat,[0 1]); % agreement
%%  calculations
min_vol=min(sum(rateMat,1))*vol;
max_vol=max(sum(rateMat,1))*vol;
mean_vol=mean(sum(rateMat,1))*vol;
sd_vol=std(sum(rateMat,1))*vol;


disp('-------------------------------------------')
disp(['Overall kappa: ',num2str(kappa)])
disp(['p-value: ',num2str(pval)])
disp(['Mean Sensitivity: ',num2str(mean_sen)])
disp(['Std. Sensitivity: ',num2str(std_sen)])
disp(['Mean Specificity: ',num2str(mean_spec)])
disp(['Std. Specificity: ',num2str(std_spec)])
disp(['Min. volume: ',num2str(min_vol)])
disp(['Max. volume: ',num2str(max_vol)])
disp(['Mean volume: ',num2str(mean_vol)])
disp(['Std. volume: ',num2str(sd_vol)])
disp(['Intersection volume: ',num2str(volV(end))])
disp(['Union volume: ',num2str(volV(1))])
disp('-------------------------------------------')

staple3M = zeros(getUniformScanSize(planC{indexS.scan}(scanNum)),'single');
staple3M(iMin:iMax,jMin:jMax,kMin:kMax) = reshape(stapleV,length(iMin:iMax),length(jMin:jMax),length(kMin:kMax));
clear stapleV;
reliability3M = zeros(getUniformScanSize(planC{indexS.scan}(scanNum)),'single');
reliability3M(iMin:iMax,jMin:jMax,kMin:kMax) = reshape(reliabilityV,length(iMin:iMax),length(jMin:jMax),length(kMin:kMax));
clear reliabilityV;
apparent3M = zeros(getUniformScanSize(planC{indexS.scan}(scanNum)),'single');
apparent3M(iMin:iMax,jMin:jMax,kMin:kMax) = averageMask3M;
            
