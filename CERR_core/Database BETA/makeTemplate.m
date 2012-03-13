function template = makeTemplate
%"makeTemplate"
%   Return a cell array of strings that contains a list of planC fields.
%   Intended for use by getExtract to specify fields to retain for 'lite'
%   version of planC.
%
%   planC{indexS.indexS} should always be in the "keeper" list.
%
%JRA 11/28/03
%
%Usage: template = makeTemplate
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


template = {...
        
        %Fields we want to keep... but minus the fields we surely DONT want
        %which are listed further below and are preceeded by '~'.
        'planC{indexS.header}'
        'planC{indexS.comment}'
        'planC{indexS.scan}'        
        'planC{indexS.structures}'                
%       'planC{indexS.structureArray}' Unusual behavior here.
        'planC{indexS.beamGeometry}'                
        'planC{indexS.beams}'              
        'planC{indexS.dose}'                
        'planC{indexS.DVH}'                
        'planC{indexS.digitalFilm}'                
        'planC{indexS.RTTreatment}'                
        'planC{indexS.CERROptions}'                
        'planC{indexS.indexS}'     %Should always be present           
                
        %Unwanted vars. NO children of these fields will survive the
        %pruning process, even if specified in the above list. Typically
        %these are the large data values that we want to throw out.
        '~planC{indexS.scan}.scanArray'
        '~planC{indexS.scan}.scanInfo'
        '~planC{indexS.scan}.scanArraySuperior'
        '~planC{indexS.scan}.scanArrayInferior'
        '~planC{indexS.scan}.thumbnails'        
        '~planC{indexS.structures}.DICOMHeaders'
        '~planC{indexS.scan}.uniformScanInfo.DICOMHeaders'
        '~planC{indexS.beams}.BeamSequence'
        '~planC{indexS.dose}.DICOMHeaders'
        '~planC{indexS.structures}.contour'
        '~planC{indexS.structures}.rasterSegments'
        '~planC{indexS.dose}.doseArray' 
        '~planC{indexS.dose}.zValues' 
};