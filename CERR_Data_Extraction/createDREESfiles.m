% Script to create two drees files from ddbs stucture. 
%1st file consists of all trials.
%2nd file consists of expected dvhs and the confidence bounds for the expeced dvhs.

fileName1 = '';
filename2 = '';

%File containing all DVHs
ddbsOriginal = ddbs;
numOriginalPatients = length(ddbs);
for iPat = 1:numOriginalPatients
    for iTrial = 1:length(ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.allTrials)
        dvh_tmp = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.allTrials{iTrial};
        ddbs(end+1) = ddbs(iPat);
        ddbs(end).dvh_Rectum_shift_0pt25cm = dvh_tmp;
    end
end

ddbs(1:numOriginalPatients) = [];
ddbs = rmfield(ddbs,'dvh_Rectum_shift_0pt25cm_rectum');
save(fileName1,'ddbs');

%File containing expected DVHs and the confidence bounds
ddbs = ddbsOriginal;
numOriginalPatients = length(ddbs);
for iPat = 1:numOriginalPatients
    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Expected = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.meanM;

    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Minus1Sigma = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.Minus1SigmaM;
    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Minus2Sigma = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.Minus2SigmaM;
    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Minus3Sigma = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.Minus3SigmaM;

    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Plus1Sigma = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.Plus1SigmaM;
    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Plus2Sigma = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.Plus2SigmaM;
    ddbs(iPat).dvh_Rectum_shift_0pt25cm_Plus3Sigma = ddbs(iPat).dvh_Rectum_shift_0pt25cm_rectum.Plus3SigmaM;    
end

ddbs(1:numOriginalPatients) = [];
ddbs = rmfield(ddbs,'dvh_Rectum_shift_0pt25cm_rectum');
save(fileName2,'ddbs');

