function testIBSI2Features
% testIBSI2Features.m This script compares first order statistical features
% computed using sample images and test configurations from IBSI-2.
%-------------------------------------------------------------------------
% AI 12/12/22

%Read "gold standard" features
CERRPath = getCERRPath;
CERRPathSlashes = strfind(getCERRPath,filesep);
topLevelCERRDir = CERRPath(1:CERRPathSlashes(end-1));
stdResult = fullfile(topLevelCERRDir,'Unit_Testing','data_for_cerr_tests',...
    'IBSI2_CT_phantom','IBSIphase2-2_CERR_features.csv');
rawC = csv2cell(stdResult);
rawSubC = rawC(2:end,5:16);
stdM = cell2mat(rawSubC);
stdM = stdM(:,1:6);%temp

%Create temp output dir
testDir = fullfile(topLevelCERRDir,'Unit_Testing','tests_for_cerr');
tmpDir = fullfile(testDir,'IBSI2');
mkdir(tmpDir)

%Compute filter response maps (IBSI 2 -phase1)
runIBSI2benchmarkStatistics(tmpDir,2);
outFileName = fullfile(tmpDir,'IBSIphase2-2.csv');
testC = csv2cell(outFileName);
featM = testC(:,2);
configM = rawC(1,5:16);
testValC = testC(2:end,5:16);
testValC = cellfun(@double,testValC,'un',0);
testM = cell2mat(testValC);

diffM = testM - stdM;
pctM = diffM*100./stdM;
assertTOL = 1e-5;
%disp(['========= Maximum difference for IBSI2-2 features. =========='])
for nConf = 1:size(diffM,2)
    [maxDiff,idx] = max(diffM(:,nConf));
    %errIdxV = find(diffM(:,nConf)>assertTOL);
    assertAlmostEqual(testM(:,nConf),stdM(:,nConf),assertTOL);
%     if ~isempty(errIdxV)
%         for n = 1:length(errIdxV)
%             disp([configC{nConf},' ',featC{errIdxV(n)},': ',...
%                 sprintf('%0.1g',diffM(errIdxV(n),nConf))]);
%             disp([configC{nConf},' ',featC{errIdxV(n)},': ',...
%                 sprintf('%0.1g',pctM(errIdxV(n),nConf))]);
%         end
%         pctV = pctM(errIdxV,nConf);
%         [maxPct,maxIdx] = max(abs(pctV));
%         disp(['Max diff: ',featC{errIdxV(maxIdx)},': ',...
%             sprintf('%0.1g',maxPct)]);
%     end
%     disp([configC{nConf},' ',featC{idx},': ',sprintf('%0.1g',maxDiff)]);
end
rmdir(tmpDir,'s')

end
