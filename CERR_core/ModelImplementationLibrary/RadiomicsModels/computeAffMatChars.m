function[cvar, ckurt, cskew, aseg, levelSizeMat] = computeAffMatChars(im)
% function[cvar, ckurt, cskew, aseg, levelSizeMat] = computeAffMatChars(im)
%
% APA, 4/5/2019
% based on H. Veeraraghavan 2018.

numLevels = 10;
minAThresh = 1;

ulabels = 1:numLevels;
aseg = imquantize_cerr(im,numLevels);
aseg(im < eps) = 0;

clusters = cell(numel(ulabels),1);
maxA = 0;
minA = 10000;

%% compute the different cluster and their characteristics
for n = 1 : numel(ulabels)
    bw = bwconncomp(single(aseg==ulabels(n)), 8);
    s = regionprops(bw, 'Area');
    if(isempty(s))
        clusters{n} = zeros(1,10);
    else
        clusters{n} = cell2mat(struct2cell(s));
        maxA = max(maxA, max(clusters{n}));
        minA = min(minA, min(clusters{n}));
    end
end

minA = max(minAThresh,minA); % atleast 3x3 neighborhood
if(minA == maxA)
    minA = maxA-5;
end

r = (maxA-minA)/10;
levels = minA+1: r: maxA;
%% compute the level by cluster size matrix
levelSizeMat = zeros(numel(ulabels), numel(levels));
for n = 1 : numel(ulabels)

    c = clusters{n};
    I = find(c >= minA);
    if(isempty(I))
       continue;
    end

    [f,v] = hist(c(I), levels);

    levelSizeMat(n,:) = f;
end

ulabels1 = ulabels./sum(ulabels);
levels1 = levels./sum(levels);
meanLevel = 0.0;
meanSize = 0.0;


%% now compute the cluster statistics
meanLevel = mean(ulabels1);
meanSize = mean(levels1); 
cvar = std(std(levelSizeMat));
ckurt = 0.0;
cskew = 0.0;


for i = 1 : numel(ulabels)
    for j = 1 : numel(levels)
        ckurt = ckurt + (i+j - meanLevel - meanSize).^3*levelSizeMat(i,j);
        cskew = cskew + ((i+j - meanLevel - meanSize).^4*levelSizeMat(i,j));
    end
end
ckurt = ckurt./(numel(levelSizeMat));
cskew = cskew./(numel(levelSizeMat));
disp(ckurt);
disp(cskew);
 
