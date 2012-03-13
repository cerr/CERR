function dicomrt_rename3ddose(oldstring,newstring,what2do,corm)
% dicomrt_rename3ddose(oldstring,newstring,what2do,corm)
%
% Change 3ddose filenames.
%
% oldstring is the old string that needs to be replaced or that is used to match string (see below)
% newstring is the new string that will be replaced or added 
% what2do is a single character which determines whether or not oldtring will be replaced
%    'r' newstring replace oldstring
%    'a' oldstring is not replaced, newstring is added to the filename just before the extension (3ddose)
%        is this case oldstring is still used to match filename among the 3ddose files in current fir
% corm is a single character which determines weather or not old files will be renamed or copied
%    'c' oldfile is copied into newfile
%    'm' oldfile is moved (renamed) into newfile
%
% When MC dose is computed for a water phantom case study (e.g. for dose verification) 
% 3ddose files contain the contribution from each segment.
% This information could be used in a study where TPS segment contribution
% needs to be evaluated.
% However the filename of the 3ddose files more likely will need to be changed to 
% suit the new case study filename convention.
%
% Example:
%
% dicomrt_rename3ddose('demo2','demo2_v2','r','c')
%
% find in the current directory the 3ddose filenames which contains the string demo2 
% and create new 3ddose files with the file name demo2_v2*.3ddose. If the dir contains
% the following files: demo2_b1s1.3ddose, demo2_b1s2.3ddose when the command terminates
% the following new files are created demo2_v2_b1s1.3ddose, demo2_v2_b1s2.3ddose.
% If then the following command is given:
%
% dicomrt_rename3ddose('demo2_v2','_mc_xyz_b1s1','a','m')
%
% it will move demo2_v2_b1s1.3ddose into demo2_v2_b1s1_mc_xyz_b1s1.3ddose and 
% demo2_v2_b1s2.3ddose into demo2_v2_b1s2_mc_xyz_b1s1.3ddose.
%
% Emiliano Spezi 2002 (emiliano.spezi@physics.org)

count=0;
list=dir;
newname=[];
pointer=[];

% Replace or add the new string
for i=1:size(list,1)
    if what2do=='r' % replace string option
        if isempty(strfind(list(i).name,oldstring))~=1 & list(i).isdir~=1
            temp=regexprep(list(i).name, oldstring, newstring);
            newname=[newname;temp];
            pointer=[pointer;i];
        end
    elseif what2do=='a' % add string option
        if isempty(strfind(list(i).name,oldstring))~=1 & list(i).isdir~=1
            % cut extension
            temp=list(i).name;
            oldname_noext=temp(1:length(temp)-7);
            temp=[oldname_noext,newstring,'.3ddose'];
            newname=[newname;temp];
            pointer=[pointer;i];
        end
    else
       error('dicomrt_rename3ddose: Option to replace (''r'') or add (''a'') new string not recognised. Exit now!');
    end 
end

% Copy or move the old file onto the new file
for i=1:size(newname,1)
    if corm=='c'
        copyfile(list(pointer(i)).name,newname(i,:));
    elseif corm=='m'
        movefile(list(pointer(i)).name,newname(i,:));
    else
        error('dicomrt_rename3ddose: Option to copy (''c'') or move (''m'') not recognised. Exit now!');
    end
end
