function outC = anonymize(inC,sensitiveString,replacement)
%outC = anonymize(inC,sensitiveString,replacement)
%Replace all field values in the cell array inC (usually a CERR planC archive)
%which contains the strings in 'sensitiveString' with the replacement string 'replacement'.
%This anonymizer function is useful for removing protected health information from CERR archives.
%Note:  *No warranty is expressed or implied*.  Use at your own risk.
%Created Dec 02, JOD.
%Example of use:
%str = '12383_4dec02'
%
%planC = anonymize(planC,'studyNumberOfOrigin',str)
%Normally one should loop over all cells with potential protected health information.
%The following fields should always be viewed suspiciously:
%PHI = {'studyNumberOfOrigin','patientName','caseNumber','archive'}.
%Last modified:  20 May 03, JOD, corrected loss of CERROptions cell.
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


%Loop over all the cells

for i = 1 : length(inC)

    if i ~= inC{end}.CERROptions
        if length(inC{i})~= 0
            entry = inC{i}(1);

            if ~isempty(entry)
                %Get all struct field names
                fields = subfieldnames(entry);
                %which have the string sensitiveString

                for j = 1 : length(fields)
                    name = fields{j};
                    indV = strfind(lower(name),lower(sensitiveString));
                    if ~isempty(indV)
                        if length(indV) ~= 1
                            error(['On field name:  ' name])
                        end
                        %anonymize!
                        disp(['Found Patient Name in ' num2str(name)])
                        %eval([ ['[' name ']'] '= deal(replacement);']);
                        for k = 1:2
                            [nameCell{k} name] = strtok(name,'.');
                        end
                        for k = 1 : length(inC{i})
                            if isempty(name(2:end))
                                eval(['inC{i}' '(',num2str(k),').' nameCell{2} '= deal(replacement);' ])
                            else
                                for l = 1 : length(eval([nameCell{1} '.' nameCell{2}]))
                                    eval(['inC{i}' '(',num2str(k),').' nameCell{2} '(',num2str(l),').' name(2:end) '= deal(replacement);' ])
                                end

                            end
                        end
                    end

                end
            end
        end
        outC{i} =inC{i};
    end
end
outC{inC{end}.CERROptions} = inC{inC{end}.CERROptions};  %Put in options