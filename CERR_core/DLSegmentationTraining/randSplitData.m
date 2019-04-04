function [trainIdxV,valIdxV,testIdxV] = randSplitData(srcDir,dataSplitV)
% randSplitData.m
%
% Partition data randomly into train/val/test sets according to user-specified split
%
% AI 3/12/19
%
% -------------------------------------------------------------------------
% INPUTS
%  srcDir      : Path to available data
%  dataSplitV  : [%train %val] Train/Val/Test split (%test = 100-%train-%val).
% -------------------------------------------------------------------------
               
%Get indices to random split

fprintf('\nSplitting data...');
rng('default');

%Compute no. of training/val/test samples
dirS = dir(srcDir);
dirS(1:2) = [];
N = length(dirS);
allDataIdx = 1:N;
Ntrain = ceil(dataSplitV(1)*N/100);
pctTest = 100-sum(dataSplitV(1:2));
frTest = pctTest/(pctTest+dataSplitV(2)+eps);

%Random partitioning
trainIdxV = randperm(N,Ntrain);
remV = allDataIdx(~ismember(1:N,trainIdxV));
Nrem = length(remV);
Ntest = ceil(frTest*Nrem);
testIdxV = remV(randperm(Nrem,Ntest));
valIdxV = remV(~ismember(remV,testIdxV));

fprintf('\nComplete.\n');


end
