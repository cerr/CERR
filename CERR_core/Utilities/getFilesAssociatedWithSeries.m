function matchingFileC = getFilesAssociatedWithSeries(seriesUID,ptDir)
% function matchingFileC = getFilesAssociatedWithSeries(seriesUID,ptDir)
%
% This function returns CT, RTDOSE, RTSTRUCT, RTPLAN and REG files
% associated with the passed seriesUID
%
% APA 7/7/2022

ctDirS = rdir(ptDir);
ctDirS([ctDirS.isdir]) = [];
numFiles = length(ctDirS);
refRtstructC = {};
rtstructFnameC = {};
rtstructSopInstanceUIDc = {};
ctSeriesUIDc = {};
ctFnameC = {};
regSeriesUIDc = {};
regFnameC = {};
rtdoseRefRtplanSOPInstanceUIDc = {};
rtdoseFnameC = {};
rtplanSopInstanceUIDc = {};
rtplanFnameC = {};
rtplanReferencedRtstructSopInstanceUIDc = {};

matchingCtV = [];
matchingRtstructV = [];
matchingRegV = [];
matchingRtplanV = [];
matchingRtdoseV = [];

init_ML_DICOM;

for iFile = 1:numFiles
    %fname = fullfile(ptDir,ctDirS(iFile).name);
    fname = ctDirS(iFile).fullpath;
    try
        %infoS = dicominfo(fname);
        [attr,isDcm] = scanfile_mldcm(fname,true);
        if ~isDcm
            continue;
        end
    catch
        continue;
    end    
    modality = char(attr.getString(524384));
    if strcmp(modality,'RTSTRUCT')
        %refRtstructC{end+1} = infoS.ReferencedFrameOfReferenceSequence.Item_1.RTReferencedStudySequence.Item_1.RTReferencedSeriesSequence.Item_1.SeriesInstanceUID;
        referencedFrameOfReferenceSequence = attr.getValue(805699600); %(3006,0010)
        rtReferencedStudySequence = referencedFrameOfReferenceSequence.get(0).getValue(805699602); %(3006,0012)
        referencedSeriesSequence = rtReferencedStudySequence.get(0).getValue(805699604); % (3006,0014)
        refRtstructC{end+1} = char(referencedSeriesSequence.get(0).getString(2097166)); %(0020,000E)
        rtstructSopInstanceUIDc{end+1} = char(attr.getString(524312,0));
        rtstructFnameC{end+1} = fname;
    end
    if strcmp(modality,'CT')
        %ctSeriesUIDc{end+1} = infoS.SeriesInstanceUID;
        ctSeriesUIDc{end+1} = char(attr.getString(2097166,0)); %(0020,000E)
        ctFnameC{end+1} = fname;
    end
    if strcmp(modality,'REG')
        %fnamC = fieldnames(infoS.ReferencedSeriesSequence);
        referencedSeriesSequence = attr.getValue(805699604); % (3006,0014)
        numRefSeries = referencedSeriesSequence.length();
        for iRefSeries = 1:numRefSeries
            regSeriesUIDc{end+1} = char(referencedSeriesSequence.get(iRefSeries-1).getString(2097166)); %(0020,000E)
            %regSeriesUIDc{end+1} =  infoS.ReferencedSeriesSequence.(fnamC{iField}).SeriesInstanceUID;
            regFnameC{end+1} = fname; 
        end
        if isfield(infoS,'StudiesContainingOtherReferencedInstancesSequence')
            %fnamC = fieldnames(infoS.StudiesContainingOtherReferencedInstancesSequence);
            studiesContainingOtherReferencedInstancesSequence = attr.getValue(528896); %(0008,1200)
            numStudies = studiesContainingOtherReferencedInstancesSequence.length;
            for iRefStudy = 1:numStudies
                %regSeriesUIDc{end+1} = infoS.StudiesContainingOtherReferencedInstancesSequence.(fnamC{iField}).ReferencedSeriesSequence.Item_1.SeriesInstanceUID;
                regSeriesUIDc{end+1} = char(attr.get(iRefStudy-1).getValue(805699604).get(0).getString(2097166));
                regFnameC{end+1} = fname;
            end
        end
    end
    if strcmp(modality,'RTPLAN')
        referencedRtStructSeq = attr.getValue(806092896);
        numRefStructSets = referencedRtStructSeq.length;
        for iRefStruct = 1:numRefStructSets
            rtplanReferencedRtstructSopInstanceUIDc{end+1} = char(referencedRtStructSeq.get(0).getString(528725));
            rtplanSopInstanceUIDc{end+1} = char(attr.getString(524312,0));
            rtplanFnameC{end+1} = fname;
        end
    end
    if strcmp(modality,'RTDOSE')
        %rtdoseRefRrplanSOPInstanceUIDc{end+1} = infoS.ReferencedRTPlanSequence.Item_1.ReferencedSOPInstanceUID;
        rtdoseRefRtplanSOPInstanceUIDc{end+1} = char(attr.getValue(806092802).get(0).getString(528725));
        rtdoseFnameC{end+1} = fname;
    end
end

% Find images, rtstructs and reg that match seriesUID
matchingCtV = strncmp(ctSeriesUIDc,seriesUID,length(seriesUID));
matchingRtstructV = strncmp(refRtstructC,seriesUID,length(seriesUID));
matchingRegV = strncmp(regSeriesUIDc,seriesUID,length(seriesUID));

% Find RTPLANs that match referenced RTSTRUCT
matchedRtStructSopInstanceUIDC = rtstructSopInstanceUIDc(matchingRtstructV);
matchingRtplanV = false(1,length(rtplanReferencedRtstructSopInstanceUIDc));
for iStr = 1:length(matchedRtStructSopInstanceUIDC)
    matchingRtplanV = matchingRtplanV | strncmp(rtplanReferencedRtstructSopInstanceUIDc,...
        matchedRtStructSopInstanceUIDC{iStr},length(matchedRtStructSopInstanceUIDC{iStr}));
end

% Find RTDOSEs that match referenced RTPLAN
matchedRtPlanSopInstanceUIDC = rtplanSopInstanceUIDc(matchingRtplanV);
matchingRtdoseV = false(1,length(rtdoseRefRtplanSOPInstanceUIDc));
for iPlan = 1:length(matchedRtPlanSopInstanceUIDC)
    matchingRtdoseV = matchingRtdoseV | strncmp(rtdoseRefRtplanSOPInstanceUIDc,...
        matchedRtPlanSopInstanceUIDC{iPlan},length(matchedRtPlanSopInstanceUIDC{iPlan}));
end

matchingFileC = [ctFnameC(matchingCtV),rtstructFnameC(matchingRtstructV),...
    regFnameC(matchingRegV), rtplanFnameC(matchingRtplanV),...
    rtdoseFnameC(matchingRtdoseV)];
    