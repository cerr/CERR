function LabBookEmail(varargin)
%"LabbookEmail"
%   GUI to handle emailing CERR Labbook image captures.
%
%JRA 5/31/05
%
%Usage:
%   LabBookEmail('init', image, annotation);
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

screenSize = get(0,'ScreenSize');   
y = 300;
x = 519;
units = 'normalized';

%If no arguments default to init.
if(nargin == 0)
    varargin{1} = 'init';
end   

%Command for callback switch statement.
command = varargin{1};

hFig = findobj('tag', 'CERR_LabBookEmail');

%If asking for INIT, and already initialized, return.
if ~isempty(hFig) & strcmpi(command, 'init');
    figure(hFig);
    return;
end

switch upper(command)
    case 'INIT'
        hFig = figure('visible', 'on', 'Name','Email Dialogue', 'units', 'pixels', 'position',[(screenSize(3)-x)/2 (screenSize(4)-y)/2 x y], 'MenuBar', 'none', 'NumberTitle', 'off', 'resize', 'off', 'Tag', 'CERR_LabBookEmail');    
        uicontrol('units',units,'Position',[.01 .03 .54 .94],'style', 'frame');
        uicontrol('units',units,'Position',[.56 .82 .43 .15],'style', 'frame');
        uicontrol('units',units,'Position',[.56 .03 .43 .76],'style', 'frame');        
        
        uicontrol('units',units,'Position',[.03 .9 .5 .05],'String','To:', 'style', 'text', 'HorizontalAlignment', 'left');
        uicontrol('units',units,'Position',[.03 .76 .5 .14],'String','', 'style', 'edit','HorizontalAlignment', 'left', 'Tag', 'LabBookEmailToField');
        
        uicontrol('units',units,'Position',[.03 .69 .5 .05],'String','Subject:', 'style', 'text', 'HorizontalAlignment', 'left');
        uicontrol('units',units,'Position',[.03 .62 .5 .07],'String','', 'style', 'edit','HorizontalAlignment', 'left', 'Tag', 'LabBookEmailSubjectField');        
        
        uicontrol('units',units,'Position',[.03 .55 .5 .05],'String','Body:', 'style', 'text', 'HorizontalAlignment', 'left');
        uicontrol('units',units,'Position',[.03 .05 .5 .5],'String','', 'style', 'edit','HorizontalAlignment', 'left', 'Tag', 'LabBookEmailBodyField');
        
        uicontrol('units',units,'Position',[.59 .85 .17 .08],'String','Send', 'callback','LabBookEmail(''SEND'');', 'Tag', 'LabBookEmailSend');
        uicontrol('units',units,'Position',[.8 .85 .17 .08],'String','Cancel', 'callback','LabBookEmail(''CANCEL'');', 'Tag', 'LabBookEmailCancel');        
        
        addresses = getEmailAddresses;
        optEmails = addresses.optionsEmails;
        cachedEmails = addresses.cachedEmails;
        
        uicontrol('units',units,'Position',[.57 .04 .41 .74],'style', 'listbox', 'string', {optEmails{:}, cachedEmails{:}}, 'callback', 'LabBookEmail(''ADDRESSCLICKED'')');    
        
    case 'MESSAGE'
        saveFile = varargin{2};
        annotation = varargin{3};
        
        subjectField = findobj(hFig, 'Tag', 'LabBookEmailSubjectField');        
        bodyField    = findobj(hFig, 'Tag', 'LabBookEmailBodyField');        
        
        [pathstr,name,ext] = fileparts(saveFile);
        
        set(subjectField, 'String', [name ext]);
        set(bodyField, 'string', annotation);
        
        set(hFig, 'userdata', saveFile);

        
    case 'ADDRESSCLICKED'
        emails = get(gcbo, 'string');
        value  = get(gcbo, 'value');
        emailToAdd = emails{value};
        
        toBox = findobj(hFig, 'Tag', 'LabBookEmailToField');
        
        oldEmails = get(toBox, 'string');
        
        if ~isempty(oldEmails)
            set(toBox, 'string', [oldEmails emailToAdd ';']);       
        else
            set(toBox, 'string', [emailToAdd ';']);       
        end
        
    case 'CANCEL'
        delete(hFig);
        
    case 'SEND'
        CERROptions;
        toField = findobj(hFig, 'Tag', 'LabBookEmailToField');
        subjectField = findobj(hFig, 'Tag', 'LabBookEmailSubjectField');
        bodyField    = findobj(hFig, 'Tag', 'LabBookEmailBodyField');
        
        subject = get(subjectField, 'string');
        toAddys = get(toField, 'string');
        saveFile = get(hFig, 'userdata');
        body = get(bodyField, 'string');
        
        toAddys = parseEmailString(toAddys);
        
        delete(hFig);       
        pause(.1);
        sendmail(toAddys, subject, body, {saveFile});
        setEmailAddresses(toAddys);
        
end



function addresses = getEmailAddresses
%"getEmailAddresses"
%   Returns a list of stored and cached email addresses.

	optS = CERROptions;
	optionsEmails = optS.emailAddresses;
	
	try
        cachedEmails  = load(fullfile(getCERRPath, 'Labbook', 'cachedEmails'));
        cachedEmails = cachedEmails.cachedEmails;
	catch
        cachedEmails = {};
	end
	
	cachedEmails = setdiff(cachedEmails, optionsEmails);
	addresses.optionsEmails = optionsEmails;
	addresses.cachedEmails  = cachedEmails;

function setEmailAddresses(newAddresses)
%"setEmailAddresses"
%   Adds the passed addresses to the email cache.

	optS = CERROptions;
	optionsEmails = optS.emailAddresses;
	
	try
        cachedEmails  = load(fullfile(getCERRPath, 'Labbook', 'cachedEmails'));
	catch
        cachedEmails = [];
	end
	
	cachedEmails = union(cachedEmails, newAddresses);
	cachedEmails = setdiff(cachedEmails, optionsEmails);
    saveOpt = getSaveInfo;
    try
        if ~isempty(saveOpt);
        	save(fullfile(getCERRPath, 'Labbook', 'cachedEmails'), 'cachedEmails', saveOpt);
        else
        	save(fullfile(getCERRPath, 'Labbook', 'cachedEmails'), 'cachedEmails');        
        end
    catch
        warning('Could not save cached email addresses.');    
    end
    
function strings = parseEmailString(emailString)
%"parseEmailString"
%   Convert from a string of emails seperated by ; , and blanks to a cell
%   array of email addresses.

dividers = [0 length(emailString)+1];
dividers = union(dividers, strfind(emailString, ','));
dividers = union(dividers, strfind(emailString, ' '));
dividers = union(dividers, strfind(emailString, ';'));
dividers = unique(dividers);

dividerEnd = dividers(2:end) - 1;
dividers = dividers(1:end-1);

for i=1:length(dividers)
    strings{i} = emailString(dividers(i)+1:dividerEnd(i));
end