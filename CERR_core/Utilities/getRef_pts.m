function hfig = getRef_pts(command)
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

global stateS
persistent profile

switch lower(command)
    case 'init'
        [profile prfName]= readRPCProfile;
        hfig = figure('menubar','none','resize','off','position',[100, 100, 300, 250],'tag','RPCFig','CloseRequestFcn','getRef_pts(''closeFig'')');
        uicontrol(hfig,'style','text','position',[10, 220, 100, 20],'string','Select Profile','FontWeight','Bold');
        uicontrol(hfig,'style','popupmenu','position',[150, 220, 120, 20],'string',prfName,'Callback','getRef_pts(''profileSelect'')','Tag','profileSelect');

        uicontrol(hfig,'style','text','position',[80, 190, 50, 20],'string','X','FontWeight','Bold');
        uicontrol(hfig,'style','text','position',[160, 190, 50, 20],'string','Y','FontWeight','Bold');
        uicontrol(hfig,'style','text','position',[240, 190, 50, 20],'string','Z','FontWeight','Bold');

        uicontrol(hfig,'style','text','position',[5, 160, 50, 20],'string','Pin 1');
        x1 = uicontrol(hfig,'style','Edit','position',[ 70, 160, 60, 20],'tag','x1');
        y1 = uicontrol(hfig,'style','Edit','position',[150, 160, 60, 20],'tag','y1');
        z1 = uicontrol(hfig,'style','Edit','position',[230, 160, 60, 20],'tag','z1');

        uicontrol(hfig,'style','text','position',[5, 100, 50, 20],'string','Pin 2');
        x2 = uicontrol(hfig,'style','Edit','position',[ 70, 100, 60, 20],'tag','x2');
        y2 = uicontrol(hfig,'style','Edit','position',[150, 100, 60, 20],'tag','y2');
        z2 = uicontrol(hfig,'style','Edit','position',[230, 100, 60, 20],'tag','z2');

        uicontrol(hfig,'style','text','position',[5, 40, 50, 20],'string','Pin 3');
        x3 = uicontrol(hfig,'style','Edit','position',[70, 40, 60, 20],'tag','x3');
        y3 = uicontrol(hfig,'style','Edit','position',[150, 40, 60, 20],'tag','y3');
        z3 = uicontrol(hfig,'style','Edit','position',[230, 40, 60, 20],'tag','z3');

        goBtn = uicontrol(hfig,'style','pushbutton','position',[120, 10, 60, 20],'string','go','callback','getRef_pts(''getpoints'')');

    case 'getpoints'
        value=get(findobj('Tag','profileSelect'),'value');
        if value == 1
            warndlg('please select a profile');
            return
        end
        x1 = str2num(get(findobj('tag','x1'),'string')); y1 = str2double(get(findobj('tag','y1'),'string')); z1 = str2double(get(findobj('tag','z1'),'string'));
        x2 = str2num(get(findobj('tag','x2'),'string')); y2 = str2double(get(findobj('tag','y2'),'string')); z2 = str2double(get(findobj('tag','z2'),'string'));
        x3 = str2num(get(findobj('tag','x3'),'string')); y3 = str2double(get(findobj('tag','y3'),'string')); z3 = (get(findobj('tag','z3'),'string'));
        ref_pts = [x1 y1 z1;...
            x2 y2 z2;...
            x3 y3 z3;...
            ];
        stateS.RPCfilm.ref_pts = ref_pts;
        RPCFilmRegister('init');
        figure(stateS.handle.CERRSliceViewer)

    case 'profileselect'
        value=get(findobj('Tag','profileSelect'),'value');
        if value == 1
            set(findobj('tag','x1'),'string','');set(findobj('tag','y1'),'string',''); set(findobj('tag','z1'),'string','');
            set(findobj('tag','x2'),'string','');set(findobj('tag','y2'),'string',''); set(findobj('tag','z2'),'string','');
            set(findobj('tag','x3'),'string','');set(findobj('tag','y3'),'string',''); set(findobj('tag','z3'),'string','');

        else
            value = value-1;
            set(findobj('tag','x1'),'string',profile(value).filmpts(1).x);set(findobj('tag','y1'),'string',profile(value).filmpts(1).y); set(findobj('tag','z1'),'string',profile(value).filmpts(1).z);
            set(findobj('tag','x2'),'string',profile(value).filmpts(2).x);set(findobj('tag','y2'),'string',profile(value).filmpts(2).y); set(findobj('tag','z2'),'string',profile(value).filmpts(2).z);
            set(findobj('tag','x3'),'string',profile(value).filmpts(3).x);set(findobj('tag','y3'),'string',profile(value).filmpts(3).y); set(findobj('tag','z3'),'string',profile(value).filmpts(3).z);
        end

    case 'closefig'
        clear persistent profile
        delete(findobj('tag','RPCFig'));
end

function [profile prfName]= readRPCProfile

profile = initProfile;

fid=fopen('RPC_profile.txt');
prfNum = 0;
while ~feof(fid)
    tline = fgetl(fid);
    if any(strfind(tline,'profile')) | any(strfind(tline,'Profile'))
        prfNum = prfNum + 1;
        ind = strfind(tline,':');
        profile(prfNum).name = deblank(tline(ind+1:end));
        
        fgetl(fid); % Axial Film
        % Read x
        tline = fgetl(fid);
        x = str2num(tline(2:end));
        profile(prfNum).filmpts(1).x = x(1);
        profile(prfNum).filmpts(2).x = x(2);
        profile(prfNum).filmpts(3).x = x(3);
        % Read y
        tline = fgetl(fid);
        y = str2num(tline(2:end));
        profile(prfNum).filmpts(1).y = y(1);
        profile(prfNum).filmpts(2).y = y(2);
        profile(prfNum).filmpts(3).y = y(3);
        % Read z
        tline = fgetl(fid);
        z = str2num(tline(2:end));
        profile(prfNum).filmpts(1).z = z(1);
        profile(prfNum).filmpts(2).z = z(2);
        profile(prfNum).filmpts(3).z = z(3);

        fgetl(fid); % Read TLD
        tline = fgetl(fid);
        x = str2num(tline(2:end));
        point = 0;
        lenx = length(x);
        for i = 1:lenx
            point = point+1;
            profile(prfNum).tld(point).x = x(point);
        end

        tline = fgetl(fid);
        y = str2num(tline(2:end));
        point = 0;
        leny = length(y);
        for i = 1:leny
            point = point+1;
            profile(prfNum).tld(point).y = y(point);
        end

        tline = fgetl(fid);
        z = str2num(tline(2:end));
        point = 0;
        lenz = length(z);
        for i = 1:lenz
            point = point+1;
            profile(prfNum).tld(point).z = z(point);
        end

        fgetl(fid); % Insert
        % Read x
        tline = fgetl(fid);
        x = str2num(tline(2:end));
        profile(prfNum).inserts(1).x = x(1);
        profile(prfNum).inserts(2).x = x(2);

        % Read y
        tline = fgetl(fid);
        y = str2num(tline(2:end));
        profile(prfNum).inserts(1).y = y(1);
        profile(prfNum).inserts(2).y = y(2);

        % Read z
        tline = fgetl(fid);
        z = str2num(tline(2:end));
        profile(prfNum).inserts(1).z = z(1);
        profile(prfNum).inserts(2).z = z(2);
    end
end
fclose(fid);
prfName = cell(prfNum+1,1);
prfName{1} = 'Select Profile';
[prfName{2:end}] = deal(profile.name);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function profile = initProfile
profile = struct(...
    'name'              ,  '',...
    'inserts'           ,  '',...
    'filmpts'           ,  '',...
    'tld'               ,  ''...
    );
pts = struct(...
    'x' ,'',...
    'y' ,'',...
    'z' ,''...
    );
profile.inserts = pts;
profile.filmpts = pts;
profile.tld     = pts;