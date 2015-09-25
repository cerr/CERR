function [MVOI3DA]=dicomrt_close3dvoi(MVOI3DA)
% dicomrt_close3dvoi(MVOI3DA)
% 
% Close 3D VOI contours.
% 
% MVOI3DA contains VOI contours defined in X Y and Z planes.
% 
% See also: dicomrt_closevoi
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Check case and set-up some parameters and variables
[MVOI3DA_temp,type,label]=dicomrt_checkinput(MVOI3DA);
MVOI3DA=dicomrt_varfilter(MVOI3DA_temp);

for k=1:size(MVOI3DA,1) % loop through the number of VOIs
    
    % Close VOI in Z
    zcontourcell=MVOI3DA{k,2}{3};
    for j=1:size(zcontourcell,1) % loop through the number of slices/VOI
        temp=zcontourcell{j};
        isequalx=isequal(temp(1,1,1),temp(end,1,1));
        isequaly=isequal(temp(1,2,1),temp(end,2,1));
        if or(~isequalx,~isequaly)
            temp(end+1,:)=temp(1,:);
            zcontourcell{j}=temp;
        end
    end
   
    % Close VOI in X
    xcontourcell=MVOI3DA{k,2}{1};
    for j=1:size(xcontourcell,1) % loop through the number of slices/VOI
        start_reverse=[];
        firstpoint=[xcontourcell{j}(1,1) xcontourcell{j}(1,2) xcontourcell{j}(1,3)];
        % basic idea:
        % Contour points as calculated by dicomrt_build3dVOI are OK.
        % However, for sagittal or coronal contours (X and Y slices), the coordinates 
        % of the superior and inferior part of the contour may be not continuous.
        % We have a singularity, which results in a line joining the 2 discontinuos points.
        % The idea of this algorithm is to find the points of discontinuity and reverse
        % the order of coordinates so the data to plot appears continuous.
        % To do this the gradient function is used. However this is not sufficient
        % to detect discontinuities cause a gradient <0 could occur by simply having 
        % a line which
        % Therefore another loop is necessary in order to check whether 
        oldx=xcontourcell{j}(:,1);
        oldy=xcontourcell{j}(:,2);
        oldz=xcontourcell{j}(:,3);
        gradientz=gradient(oldz);
        singularity=find(gradientz<0);
        if j==300
            disp('Hello world');
        end
        if isempty(singularity)~=1
            for jj=1:2:length(singularity)-1
                if isequal(oldz(singularity(jj)+1),firstpoint(3))==1
                    start_reverse=singularity(jj)+1;
                end
            end
        end
        
        if isempty(start_reverse)~=1
            xcontourcell{j}(start_reverse:end,1)=flipud(oldx(start_reverse:end));
            xcontourcell{j}(start_reverse:end,2)=flipud(oldy(start_reverse:end));
            xcontourcell{j}(start_reverse:end,3)=flipud(oldz(start_reverse:end));
        end
            
        %[sortz,sort_index]=sort(oldz);
        %xcontourcell{j}(:,1)=oldx(sort_index);
        %xcontourcell{j}(:,2)=oldy(sort_index);
        %xcontourcell{j}(:,3)=oldz(sort_index);
        
        % closing the contour      
        xcontourcell{j}=vertcat(xcontourcell{j},firstpoint);
    end
    
    clear old* firstpoint
    
    % Close VOI in Y
    ycontourcell=MVOI3DA{k,2}{2};
    for j=1:size(ycontourcell,1) % loop through the number of slices/VOI
        % sorting the coordinates so that plot function wont display crossing lines
        start_reverse=[];
        firstpoint=[ycontourcell{j}(1,1) ycontourcell{j}(1,2) ycontourcell{j}(1,3)];
        oldx=ycontourcell{j}(:,1);
        oldy=ycontourcell{j}(:,2);
        oldz=ycontourcell{j}(:,3);
        gradientz=gradient(oldz);
        singularity=find(gradientz<0);
        if isempty(singularity)~=1
            for jj=1:2:length(singularity)-1
                if isequal(oldz(singularity(jj)+1),firstpoint(3))==1
                    start_reverse=singularity(jj)+1;
                end
            end
        end
        
        if isempty(start_reverse)~=1
            ycontourcell{j}(start_reverse:end,1)=flipud(oldx(start_reverse:end));
            ycontourcell{j}(start_reverse:end,2)=flipud(oldy(start_reverse:end));
            ycontourcell{j}(start_reverse:end,3)=flipud(oldz(start_reverse:end));
        end
        
        %[sortz,sort_index]=sort(oldz);
        %ycontourcell{j}(:,1)=oldx(sort_index);
        %ycontourcell{j}(:,2)=oldy(sort_index);
        %ycontourcell{j}(:,3)=oldz(sort_index);
        % actually closing the contour
        
        ycontourcell{j}=vertcat(ycontourcell{j},firstpoint);
    end
    
    % Update 3d VOI
    MVOI3DA{k,2}{3}=zcontourcell;
    MVOI3DA{k,2}{1}=xcontourcell;
    MVOI3DA{k,2}{2}=ycontourcell;
end

% Store 3d VOI
[MVOI3DA]=dicomrt_restorevarformat(MVOI3DA_temp,MVOI3DA);