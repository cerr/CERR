function success = callDeepLearnSegContainer(algorithm, containerPath, fullSessionPath, sshConfigS)

   
% Execute the container
if ~exist('sshConfigS','var') || (exist('sshConfigS','var') && isempty(sshConfigS))
    bindingDir = ':/scratch';
    bindPath = strcat(fullSessionPath,bindingDir);
    command = sprintf('singularity run --app %s --nv --bind  %s %s %s', algorithm, bindPath, containerPath, fullSessionPath)
    status = system(command)

else
    %call .bat file with correct inputs
    currentPath = pwd;
    cd(sshConfigS.putty_path);
    [~, sessionName, sessionVer] = fileparts(fullSessionPath);
    sessionName = [sessionName,sessionVer];
    command = sprintf('call %s %s %s %s %s %s %s %s %s',sshConfigS.bat_file_path, ...
        sshConfigS.ssh_key, sshConfigS.ssh_server_name, sshConfigS.ssh_uname, ...
        fullSessionPath, sshConfigS.server_session_dir, sessionName, ...
        containerPath, algorithm)      
    status = system(command);
    cd(currentPath);
end
success = 1;
end