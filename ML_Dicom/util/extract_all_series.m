function [seriesC, typeC] = extract_all_series(dcmdir_PATIENT)
%"extract_all_series"
%   Returns a cell array of all series contained within a dcmdir.PATIENT
%   datastructure, regardless of parent study.  Also returns an optional
%   type cell, containing strings describing the type of each series in
%   seriesC.
%
%JRA 06/15/06
%YWU modified 03/03/08
% 
%Usage:
%   seriesC = extract_all_scan_series(dcmdir_PATIENT);
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

seriesC     = {};
typeC       = {};

for studyNum = 1:length(dcmdir_PATIENT.STUDY)
    
    study = dcmdir_PATIENT.STUDY(studyNum); %wy {} --> ()
        
    for seriesNum = 1:length(study.SERIES)
        
        seriesC{end+1} = study.SERIES(seriesNum); %wy {} --> ()
        
        %Remove the info field, leaving only the field describing what type
        %of series this is.
        tmp = rmfield(study.SERIES(seriesNum), 'info'); %wy {} --> ()
        tmpFields = fields(tmp);
        
        if length(tmpFields) == 2; %wy 1-->2
            imgModality = tmp.Modality;
            imgModality = parseModality(imgModality);
            typeC{end+1} = imgModality;
            %typeC{end+1} = tmp.Modality; % wy tmpFields{:};                
        else
           error('Improperly formed dcmdir_PATIENT structure passed to extract_all_series.'); 
        end
        
    end
    
end

return;


function imgModality = parseModality(imgModality)
%function imgModality = parseModality(imgModality)
%
% This function parses image modality and returns valid DICOM modality. For
% example, "CT SCAN", "M_CT" will be considered as belonging to modality "CT"

imgModality = upper(imgModality);

indStruct = strfind(imgModality,'STRUCT');
indDose = strfind(imgModality,'DOSE');
indPlan = strfind(imgModality,'PLAN');

if ~isempty([indStruct indDose indPlan])
    return;
end

indCT = strfind(imgModality,'CT');
indPT = strfind(imgModality,'PT');
indPET = strfind(imgModality,'PET');

if ~isempty(indCT) && isempty([indPT indPET])
    imgModality = 'CT';
elseif ~isempty(indPT) && isempty([indCT indPET])
    imgModality = 'PT';
elseif ~isempty(indPET) && isempty([indCT indPT])
    imgModality = 'PT';
end

return;



