function Surf3DCallBack
%CallBack function for struct3Dvisualmenu
%CZ.
%Latest modifications: JOD; 20 feb 03: Transparency values are necessary; default is 1.
%                                      Also if the dose transparency value is blank it
%                                      defaults to 1.
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


global stateS planC

optS    = stateS.optS;

hSurf = stateS.handle.CERRSurf;

Surf =  get(hSurf,'userdata');

S = size(Surf);

Transp = [];
Structure = [];
DoL = [];
DoT = [];

c=1;
for i=1:S(2)
    if get(Surf(i).Box3D,'value')==1
        Structure(c) = i;
        str = get(Surf(i).Trans,'string');
        Transp(c) = 1;
        try
          if ~isempty(str)
            Transp(c) = str2num(str);
          end
        end
        c=c+1;
    end
end



FlagD = 0;
if str2num(get(Surf(S(2)).DoseL,'string')) >= 0
   FlagD = 1;
   DoL = str2num(get(Surf(S(2)).DoseL,'string'));
   TrD = str2num(get(Surf(S(2)).DoseT,'string'));
   DoT = 1;
   try
     if ~isempty(TrD)  
         DoT = str2num(get(Surf(S(2)).DoseT,'string'));
     end
   end
end


%Get 'skin' structnum
structNamesC = {planC{planC{end}.structures}.structureName};
test = cmp(structNamesC,'==','skin','nocase');
skinStructNum = find(test);


visualStruct3D(Structure,Transp,FlagD,DoL,DoT,skinStructNum)
