function [success,gitHash] = callDeepLearnSegContainer(algorithm, containerPath, fullSessionPath, sshConfigS, batchSize)
% This function merges the segmentations from the respective algorithm back
% into the original CERR file
%
% RKP, 3/21/2019
%
% INPUTS:
%   algorithm         : Name of algorithm being processed
%   containerPath     : Path of the container to call
%   fullSessionPath   : Temp session path
%   sshConfigS        : Structure with information read from ssh
%                       configuration for connecting to server if needed
%   batchSize         : batch size to pass to the deep learning model
   

% Execute the container
gitHash = 'unavailable';
if ~exist('sshConfigS','var') || (exist('sshConfigS','var') && isempty(sshConfigS))
    bindingDir = ':/scratch';
    bindPath = strcat(fullSessionPath,bindingDir);
    command = sprintf('singularity run --app %s --nv --bind  %s %s %s', algorithm, bindPath, containerPath, num2str(batchSize))
    status = system(command);
    
    % Run container app to get hash (placeholder for now)
    %[~,hashChk] = system(['singularity apps ' containerPath ' | grep get_hash'],'-echo');
    [~,hashChk] = system(['singularity inspect --list-apps ' containerPath ' | grep get_hash'],'-echo');
    if ~isempty(hashChk)
        [~,gitHash] = system(['singularity run --app get_hash ' containerPath],'-echo');
    end

else
    %call .bat file with correct inputs
    currentPath = pwd;
    cd(sshConfigS.putty_path);
    [~, sessionName, sessionVer] = fileparts(fullSessionPath);
    sshCombinedSessionStr = strcat(sshConfigS.ssh_uname, '@',sshConfigS.ssh_server_name)
    sessionName = [sessionName,sessionVer];
    command = sprintf('call %s %s %s %s %s %s %s %s %s',sshConfigS.bat_file_path, ...
        sshConfigS.ssh_key, sshCombinedSessionStr, ...
        fullSessionPath, sshConfigS.server_session_dir, sessionName, ...
        containerPath, num2str(batchSize), algorithm)      
    status = system(command);
    
    
    cd(currentPath);
end
success = 1;
end