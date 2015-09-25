function m = metricName(arg, m) 
%A non-functional template to show how to make a new metric.
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

if(strcmp(arg,'getNewMetric')) %Customize this function for each new metric.
    m.name = 'MyName';                         %String that identifies the generic metric
    m.valueV = [];                             %Where metric values will be stored, leave blank here.
    m.description = 'My Description';          %Description to be displayed to users.
    m.functionName = @MyName;                  %FunctionHandle to this metric.
    m.note = '';                               %A note that will be displayed in graphicalComparison, set in 'evaluate'.
    
    m.params(1).name = 'MyFirstParameterName'; %Currently two types of parameters, Edit and DropDown.  First set the name of the
    m.params(1).type = 'Edit';                 %parameter, the type, 'Edit' or 'DropDown'.  If edit, remember all values are strings.
    m.params(1).value = '1';                   %.value is the default value for this parameter.
    
    m.params(2).name = 'MySecondParameterName';%DropDown parameters take an additional field, list.  List is a list of strings to be
    m.params(2).type = 'DropDown';             %displayed in a dropdown box, indexed by .value.  
    m.params(2).list = {'Item1' 'Item2'};
    m.params(2).value = 1;    
    %   .
    %   . Add as many parameters as needed.
    %   .
    m.units = [];         %units to be displayed in graphicalComparison.  Set in 'evaluate' if wanted.
    
    m.range = [-inf inf]; %[min max], -inf takes the smallest calculated value, inf takes the largest.
                               %range is used to determine what values are good, high or low.  May be dependant on 
                               %a parameter, so modify in 'evaluate' if needed.
                               
    m.doseSets = [];      %List of doses to evaluate over... is set by metricSelection
return;
end

%Call to evaluate the function.  Access parameters defined above if needed.
if(strcmp(arg,'evaluate'))
    
    MyFirstParameter = str2num(m.params(1).value); %Keep in mind that parameters are stored as strings, change them if necessary.
    MySecondParameter = m.params(2).value;
    %   .
    %   .
    %   .    
    MyDoses = metric.doseSets; %This is the plan list to calculate values over... can be ignored if it is not relevant.
    
    %Make some calculations, do whatever.  If multiple results are expected over many doses, be sure to return array of results.
    %If wanted, modify range, note or other fields in the metric struct before returning.
    
    m.value = [m.value ResultOfCalculations];
end
return;