function [planC, planMetricsS] = generateReport(planC, planMetricsS, outfilename, outfilepath, doseNamesC)  %optS?
%Generates a report (structure and HTML file) based on metric criteria.
%VHC 2/13/06

%copied:
%global gRState;
%uicolor              = [.9 .9 .9];
%units = 'normalized';
%nargout = 0;
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

%first initialize everything

if ~exist('doseNamesC') %plans.names in orig.
    doseNamesC = [];
end

%calculate the criteria, see if it passed/failed/marginal, compute scoring function.


%eval metric functions, takes cell array of metrics
numMetrics = length(planMetricsS);

%Evaluate metrics, data is stored in metric's valueV field.
statusBar = waitbar(0,'Calculating/Retrieving Metric & Criteria Data');

for i=1:numMetrics
    %calculate metric
    [planC, planMetricsS(i)] = feval(planMetricsS(i).functionName, planC, planMetricsS(i), 'evaluate');

    %calculate passStatus

    m = planMetricsS(i); %for ease of coding
    passDirection = m.criteria.passDirectionList{m.criteria.passDirectionIndex}; %'above' or 'below'
    if      strcmp(passDirection,'above')    passFxn = 'ge';
    elseif  strcmp(passDirection,'below')    passFxn = 'le';
    else error('GenerateReport: Unknown pass direction');
    end
    marginalDirection = m.criteria.marginalDirectionList{m.criteria.marginalDirectionIndex}; %'above' or 'below'
    if      strcmp(marginalDirection,'above')    marginalFxn = 'ge';
    elseif  strcmp(marginalDirection,'below')    marginalFxn = 'le';
    else error('GenerateReport: Unknown marginal direction');
    end

    m.criteria.passStatus = {};

    for j=1:length(m.doseSets) %for ea dose dist
        if feval(passFxn, m.valueV(j), m.criteria.passValue) %criteria passed
            m.criteria.passStatus{j} = 'passed';
        elseif feval(marginalFxn, m.valueV(j), m.criteria.marginalValue) %marginally passed
            m.criteria.passStatus{j} = 'marginal';
        else
            m.criteria.passStatus{j} = 'failed';
        end
    end

    planMetricsS(i) = m; %make sure this happens

    waitbar(i/numMetrics,statusBar)
end
close(statusBar)

%compute scoring function
%(strict priorities)
c = 10; %max num of criteria within any priority
p = 10; %max num of priority levels
numDoseSets = length(m.doseSets);

n = zeros(numDoseSets,p); %number of criteria passing at priority i (passing times 2, plus marginal times 1)

for nm=1:numMetrics
    for nd=1:numDoseSets
        i = planMetricsS(nm).criteria.priority;
        if strcmp(planMetricsS(nm).criteria.passStatus{nd},'passed')
            n(nd,i) = n(nd,i) + 2;
        elseif strcmp(planMetricsS(nm).criteria.passStatus{nd},'marginal')
            n(nd,i) = n(nd,i) + 1;
        end %do nothing if it failed
    end
end

consts = c.^(p-(1:p))';

scoreV = n * consts;

%now put the data into an html file
fn = [outfilepath outfilename]; %whole file name
%open the html file for writing
fid = fopen(fn, 'w'); %open for writing
%write to the html file
count = fprintf(fid,'Report'); %put arguments after the string

fprintf(fid,'<TABLE>\n');

for i=0:numMetrics+1
    %print criteria
    if (i==0)
        fprintf(fid,'<TR><TH NOWRAP></TH> '); %if 0  %could write "Criteria" here
    elseif (i==numMetrics+1)
        fprintf(fid,'<TR><TH NOWRAP> Score </TH> ');
    else
        fprintf(fid,'<TR><TD NOWRAP> %s %s (priority %d) </TD> ', planMetricsS(i).name, planMetricsS(i).note, planMetricsS(i).criteria.priority); %alternatively, could have each metric have a "toString" option.
    end

    for j=1:length(m.doseSets) %for ea dose dist
        %print pass/fail/marginal
        if (i==0)
            fprintf(fid,'<TH NOWRAP> %s </TH> ', doseNamesC{j}); %name of dose dist
        elseif (i==numMetrics+1)
            fprintf(fid,'<TD NOWRAP> %d </TD> ', scoreV(j));
        else
            fprintf(fid,'<TD NOWRAP> %s </TD>', planMetricsS(i).criteria.passStatus{j});
        end
    end
    fprintf(fid,'</TR>\n');
end
fprintf(fid,'</TABLE>\n');

fclose(fid);
