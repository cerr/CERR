function LS = getDICOMLeafPositions(DICOMBeamSequence)
%"getDICOMLeafPositions"
%   Returns the leaf positions of this DICOM beam.
%
%JRA&KZ 2/8/05
%
%Usage:
%   function LS = getDICOMLeafPositions(DICOMBeamSequence)
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

bs = DICOMBeamSequence;

itemList = fieldnames(bs.BeamLimitingDeviceSequence);
controlPtFields = fieldnames(bs.ControlPointSequence);
nControlpoints = length(controlPtFields);

MLCX = 0;
MLCY = 0;

for i=1:nControlpoints
    
    if ~isfield(bs.ControlPointSequence.(controlPtFields{i}),'BeamLimitingDevicePositionSequence')
        continue
    end
    
    fieldNames = fieldnames(bs.ControlPointSequence.(controlPtFields{i}).BeamLimitingDevicePositionSequence);
    
    for j=1:length(fieldNames)
        
        item = bs.ControlPointSequence.(controlPtFields{i}).BeamLimitingDevicePositionSequence.(['Item_' num2str(j)]);
        
        switch item.RTBeamLimitingDeviceType
            case {'ASYMX', 'X'}
                LS.xLimits{i} = item.LeafJawPositions;                
            case {'ASYMY', 'Y'}
                LS.yLimits{i} = item.LeafJawPositions;
            case 'MLCX'
                MLCX = 1;         
                LS.xLeafPositions{i} = item.LeafJawPositions;
                % JC Aug 28, 2007
                % When only 2 controlPoint present, LS.meterSetWeight
                % should not be 0. Fix as follows.
                if (nControlpoints > 2)
                LS.meterSetWeight{i} = bs.ControlPointSequence.(controlPtFields{i}).CumulativeMetersetWeight;                
                else 
                LS.meterSetWeight{i} = bs.ControlPointSequence.(controlPtFields{i+1}).CumulativeMetersetWeight - ...
                    bs.ControlPointSequence.(controlPtFields{i}).CumulativeMetersetWeight;
                end                
            case 'MLCY'
                MLCY = 1;
                LS.yLeafPositions{i} = item.LeafJawPositions;
                % JC Aug 28, 2007
                if (nControlpoints > 2)
                LS.meterSetWeight{i} = bs.ControlPointSequence.(controlPtFields{i}).CumulativeMetersetWeight;                
                else 
                LS.meterSetWeight{i} = bs.ControlPointSequence.(controlPtFields{i+1}).CumulativeMetersetWeight - ...
                    bs.ControlPointSequence.(controlPtFields{i}).CumulativeMetersetWeight;
                end
            otherwise
                error('Unknown RTBeamLimitingDeviceType.')
        end
    end
        
end

if MLCX
    BLDS = fieldnames(bs.BeamLimitingDeviceSequence);
    for i=1:length(BLDS)
        type = bs.BeamLimitingDeviceSequence.(BLDS{i}).RTBeamLimitingDeviceType;
        switch type
            case 'MLCX'
                LS.yLeafPositions = bs.BeamLimitingDeviceSequence.(BLDS{i}).LeafPositionBoundaries;
        end
    end
end

if MLCY
    BLDS = fieldnames(bs.BeamLimitingDeviceSequence);
    for i=1:length(BLDS)
        type = bs.BeamLimitingDeviceSequence.(BLDS{i}).RTBeamLimitingDeviceType;
        switch type
            case 'MLCY'
                LS.xLeafPositions = bs.BeamLimitingDeviceSequence.(BLDS{i}).LeafPositionBoundaries;
        end
    end
end

% for i=1:length(itemList);
%     type = bs.BeamLimitingDeviceSequence.(itemList{i}).RTBeamLimitingDeviceType;
%     switch upper(type)
%         case {'ASYMX', 'X'}
%             if nControlpoints == 2
%                 positionSequences = fields(bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence);
%                 try
%                     LS.xLimits{1} = bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence.(positionSequences{1}).LeafJawPositions;
%                 end
%             else
%                 for j=1:nControlpoints
%                     positionSequences = fields(bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence);
%                     try
%                         LS.xLimits{j} = bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence.(positionSequences{i}).LeafJawPositions;
%                     end
%                 end
%             end
%         case {'ASYMY','Y'}
%             if nControlpoints == 2
%                 positionSequences = fields(bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence);
%                 try
%                     LS.yLimits{1} = bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence.(positionSequences{2}).LeafJawPositions;
%                 end                
%             else
%                 for j=1:nControlpoints
%                     positionSequences = fields(bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence);                
%                     try
%                         LS.yLimits{j} = bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence.(positionSequences{i}).LeafJawPositions;
%                     end
%                 end            
%             end
%         case 'MLCX'
%             LS.yLeafPositions = bs.BeamLimitingDeviceSequence.(itemList{i}).LeafPositionBoundaries;
% %             itemList = fields(bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence);
%             if nControlpoints == 2
%                 positionSequences = fields(bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence);
%                 try
%                         LS.xLeafPositions{1} = bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence.(positionSequences{3}).LeafJawPositions;
%                         LS.meterSetWeight{1} = 1;
%                 end                
%             else
%                 for j=1:nControlpoints
%                     positionSequences = fields(bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence);                
%                     try
%                         if j==1
%                             LS.xLeafPositions{j} = bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence.(positionSequences{3}).LeafJawPositions;
%                             LS.meterSetWeight{j} = bs.ControlPointSequence.(controlPtFields{j}).CumulativeMetersetWeight;
%                         else
%                             LS.xLeafPositions{j} = bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence.(positionSequences{1}).LeafJawPositions;
%                             LS.meterSetWeight{j} = bs.ControlPointSequence.(controlPtFields{j}).CumulativeMetersetWeight;
%                         end
%                     end
%                 end
%             end
%         case 'MLCY'
%             LS.xLeafPositions = bs.BeamLimitingDeviceSequence.(itemList{i}).LeafPositionBoundaries;
%             if nControlpoints == 2
%                 positionSequences = fields(bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence);
%                 try
%                         LS.yLeafPositions{1} = bs.ControlPointSequence.(controlPtFields{1}).BeamLimitingDevicePositionSequence.(positionSequences{3}).LeafJawPositions;
%                         LS.meterSetWeight{1} = 1;
%                 end           
%             else
%                 for j=1:nControlpoints
%                     positionSequences = fields(bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence);                
%                     try
%                         LS.yLeafPositions{j} = bs.ControlPointSequence.(controlPtFields{j}).BeamLimitingDevicePositionSequence.(positionSequences{i}).LeafJawPositions;
%                         LS.meterSetWeight{j} = bs.ControlPointSequence.(controlPtFields{j}).CumulativeMetersetWeight;
%                     end
%                 end            
%             end
%     end         
% end

%disp('congratulation you just have compiled me')