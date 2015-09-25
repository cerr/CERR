function [change,error_handle]=dicomrt_sortct(filelist,xlocation,ylocation,zlocation,filename)
% dicomrt_sortct(filelist,xlocation,ylocation,zlocation,filename)
%
% Sort CT data set specified in filename. 
%
% See also dicomrt_loaddose, dicomrt_loadct, dicomrt_loadctlist
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Set parameters
counter=0;
error_handle=0;
match=0;

% sort ct slices with respect to their z location
[zlocation_sorted,sorted_index]=sort(zlocation);

% Progress bar
h = waitbar(0,['Sorting progress:']);
set(h,'Name','dicomrt_sortct: sorting CT images');

diff_location=dicomrt_mmdigit(zlocation_sorted-zlocation,6);

if find(diff_location) % ct slices are not sorted
    disp('Message: slices are not sorted!');
    change=1;
    % sort filelist accordingly
    filelist_sorted=' ';
    for i=1:length(sorted_index)
        counter=counter+1;
        filelist_sorted=char(filelist_sorted,filelist(sorted_index(i),:));
        xlocation_sorted(i)=xlocation(sorted_index(i));
        ylocation_sorted(i)=ylocation(sorted_index(i));
        waitbar(i/length(sorted_index),h);
    end
    
    xlocation_sorted=xlocation_sorted';
    ylocation_sorted=ylocation_sorted';
    filelist_sorted(1,:)=[];
    disp('Message: ct slices are now sorted!');
    % finds duplicates
    duplicate_index=0;
    [duplicate]=diff(zlocation_sorted);
    [duplicate_index]=find(duplicate==0);
    if length(duplicate_index)~=0
        warning('dicomrt_sortct: Images with the same zlocation were found. You can exit now or proceed to delete duplicates.');
        leaveoption=input('Exit now ? (Y/N) [N]','s');
        if leaveoption == 'Y' | leaveoption == 'y';
            disp('OK. Check your file list and try again. ');
            error_handle=1;return;
        else
            duplicates_name=' ';
            filelist_sorted_scrub=' ';
            for i=1:length(duplicate_index)
                duplicates_name=char(duplicates_name,filelist_sorted(duplicate_index(i),:));
                filelist_sorted(duplicate_index(i),1:10)='duplicate-'; % mark duplicates
                xlocation_sorted(duplicate_index(i))=pi;
                ylocation_sorted(duplicate_index(i))=pi;
            end
            for i=1:length(filelist_sorted)
                if isequal(filelist_sorted(i,1:10),'duplicate-')~=1
                    filelist_sorted_scrub=char(filelist_sorted_scrub,filelist_sorted(i,:));
                else
                end
            end % at this point duplicates are deleted in new filelist
                        filelist_sorted_scrub(1,:)=[];
            disp('The following duplicates has been deleted from file list:');
            duplicates_name(1,:)=[];
            duplicates_name
            %
            % now sorting xlocation and ylocation accordingly to what done before
            % (prepare for scout images identification)
            %
            for i=1:length(xlocation_sorted)
                if xlocation_sorted(i)~=pi
                    xlocation_sorted_scrub=xlocation_sorted(i);
                end
            end
            for i=1:length(ylocation_sorted)
                if ylocation_sorted(i)~=pi
                    ylocation_sorted_scrub=ylocation_sorted(i);
                end
            end
        end
    else
        filelist_sorted_scrub=filelist_sorted;
    end
    
    % Export sorted/scrubed filelist
    newfilename=[filename,'.sort.txt'];
    newfile=fopen(newfilename,'w');
    
    for i=1:size(filelist_sorted_scrub,1)
        fprintf(newfile,'%s',filelist_sorted_scrub(i,:)); fprintf(newfile,'\n');
    end
    
    fclose(newfile);
    disp(['A new file list has been written by dicomrt_sortct with name: ',newfilename]);
    disp('This file will be used to import ct data instead');
    
else % ct slices are already sorted
    change=0;
end

% Close progress bar
close(h);
