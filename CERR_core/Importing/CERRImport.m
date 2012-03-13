function planC = CERRImport(optName, archiveDir, saveFile)
%function planC = CERRImport(optName,archiveDir,saveDir)
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
%
%Description: Wrapper file to import AAPM/RTOG directories.  The main work is done
%by importRTOGDir.  If called without arguments, the user selects an archive file and
%an options file via GUI dialogs, and the name of the file to save the
%CERR plan to is input via the file save GUI.  Can be called with 1, 2, or 3
%arguments.
%
%Inputs:
%optName -- is the name of an options file (an example file is initCERRImport).
%archiveDir -- is the path of the archive directory, with trailing slash.
%saveFile -- the name, including path, of a file to which to save the CERR plan.
%
%Output: None, except the saved file.
%
%Globals:  None.
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%Reference:
%W. Harms, Specifications for Tape/Network Format for Exchange of Treatment Planning Information,
%version 3.22., RTOG 3D QA Center, (http://rtog3dqa.wustl.edu), 1997.
%
%Last Modified:  28 Aug 03, by ES.
%                added control for clean exit when user cancel file
%                selection
%
%Version:  1.x. (Incremented by 0.001 for every modification of this file or a called file.)
%
%Copyright:
%This software is copyright J. O. Deasy and Washington University in St Louis.
%A free license is granted to use or modify but only for non-commercial non-clinical use.
%Any user-modified software must retain the original copyright and notice of changes if redistributed.
%Any user-contributed software retains the copyright terms of the contributor.
%No warranty or fitness is expressed or implied for any purpose
%whatsoever--use at your own risk.
% Unzip routines
% outstr = ['gzip.exe -vd ', fmat]
% dos(outstr)

fname1 = '';

%Interactive or not:
if nargin == 0
    [fname1, pathname] = uigetfile({'*.*',  'All Files (*.*)'},'Select 0000 file to begin importing.');
    pause(0.1);
    if fname1==0;
        disp('RTOG scan aborted.');
        return
    else
        archiveDir = pathname;
        [fname, pathname] = uigetfile({'*.m',  'M-files (*.m)'},'Select CERR options .m file', fullfile(getCERRPath, 'CERROptions.m'));
        pause(0.1);
        if fname==0;
            disp('RTOG scan aborted.');
            return
        else
            optName = [pathname fname];
            optS = opts4Exe(optName);
            saveFlag = 'ui';
        end
    end

elseif nargin == 1 %Assume options given
    [fname1, pathname] = uigetfile({'*.*',  'All Files (*.*)'},'Select aapm0000 file to begin importing.');
    pause(0.1);
    
    if fname1==0;
        disp('RTOG scan aborted.');
        return
    else
        archiveDir = pathname;
        optS = opts4Exe(optName);
        saveFlag = 'ui';
    end
elseif nargin == 2
    optS = opts4Exe(optName);

    saveFlag = 'ui';
elseif nargin == 3
    optS = opts4Exe(optName);
    if ~strcmp(saveFile,'no')
        saveFlag = 'spec';
    else
        saveFlag = 'no';
    end
    fname1 = 'aapm0000';

end

%Start diary and timer for import log.
startTime = now;
tmpFileName = tempname;
diary(tmpFileName);

%%%%Call the import tool: IMPORT occurs here.
planC = importRTOGDir(optS, archiveDir, fname1);
%%%%

%Stop diary and write it to planC.
diary off;
endTime = now;
logC = file2cell(tmpFileName);
delete(tmpFileName);
indexS = planC{end};
planC{indexS.importLog}(1).importLog = logC;
planC{indexS.importLog}(1).startTime = datestr(startTime);
planC{indexS.importLog}(1).endTime = datestr(endTime);

switch saveFlag

    case 'ui'

        save_planC(planC,optS);

    case 'spec'

        if isempty(saveFile) %save within the subdirectory
            saveFile = [archiveDir 'planC.mat'];
        end

        try

            %Save functions... modified to work with matlab 7
            saveOpt = getSaveInfo;
            if ~isempty(saveOpt);
                save(saveFile, 'planC', saveOpt);
            else
                save(saveFile, 'planC');
            end

            if strcmp(optS.zipSave,'yes') %zip the saved file
                outstr = gnuCERRCompression(saveFile,'compress');
                if (~ischar(outstr)) % Function returned as zero when compression complete
                    errordlg('File not found by compression routine.', 'CERR compression');
                end
            end

        catch
            warndlg('That file name was not valid.')
            save_planC(planC,optS);

        end
    case 'no'

        %no save

end