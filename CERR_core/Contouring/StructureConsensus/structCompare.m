function structCompare(varargin)
%Callback for Structure comparison mode
%
%APA, 01/30/07
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


if length(varargin{:}) > 1
    command = 'INIT';
    for i=1:length(varargin{:})
        structAll(i) = str2num(varargin{1}{i});
    end
elseif length(varargin{:}) == 1
    command = 'EXIT';
end

global stateS planC
indexS = planC{end};

switch upper(command)

    case 'INIT'

        try

            scanNum = getStructureAssociatedScan(structAll(1));
            for i=2:length(structAll)
                if scanNum ~= getStructureAssociatedScan(structAll(i))
                    error('All structures must be associated to the same scan')
                    return;
                end
            end

            %Remove old masks
            cleanupAxes(stateS.handle.CERRAxis)
            structCompare({'exit'})

            oldLayout = stateS.layout;

            % Change panel layout to 4 medium
            sliceCallBack('layout', 4)

            % Link the three views and display Transverse view on the three axes
            Ax1 = stateS.handle.CERRAxis(1);
            Ax2 = stateS.handle.CERRAxis(2);
            Ax3 = stateS.handle.CERRAxis(3);

            setAxisInfo(Ax1,'scanSelectMode','manual','structSelectMode','manual','scanSets',scanNum,'structureSets',scanNum,'doseSets',[],'view','transverse','xRange',[],'yRange',[])
            setAxisInfo(Ax2,'scanSelectMode','manual','structSelectMode','manual','scanSets',scanNum,'structureSets',scanNum,'doseSets',[])
            setAxisInfo(Ax3,'scanSelectMode','manual','structSelectMode','manual','scanSets',scanNum,'structureSets',scanNum,'doseSets',[])
            axisInfo = get(Ax2,'userdata');
            axisInfo.coord       = {'Linked', Ax1};
            axisInfo.view        = {'Linked', Ax1};
            axisInfo.xRange      = {'Linked', Ax1};
            axisInfo.yRange      = {'Linked', Ax1};
            set(Ax2, 'userdata', axisInfo);
            axisInfo = get(Ax3,'userdata');
            axisInfo.coord       = {'Linked', Ax1};
            axisInfo.view        = {'Linked', Ax1};
            axisInfo.xRange      = {'Linked', Ax1};
            axisInfo.yRange      = {'Linked', Ax1};
            set(Ax3, 'userdata', axisInfo);

            %Set coord at the starting slice of strNum1
            [x,y,z] = size(getScanArray(planC{indexS.scan}(scanNum)));
            [xCoord,yCoord,zCoord] = getScanXYZVals(planC{indexS.scan}(scanNum));
            for i=1:z
                if length(planC{indexS.structures}(structAll(1)).contour(i).segments) > 0 && ~isempty(planC{indexS.structures}(structAll(1)).contour(i).segments(1).points)
                    coord = zCoord(i);
                    break
                end
            end

            setAxisInfo(Ax1,'coord',coord,'xRange',[xCoord(1) xCoord(end)],'yRange',[yCoord(end) yCoord(1)])

            %Create an unLinked 5th axis to look at other view
            if length(stateS.handle.CERRAxis) < 5
                sliceCallBack('DUPLICATEAXIS',Ax1)
                setAxisInfo(stateS.handle.CERRAxis(5),'scanSelectMode','manual','structSelectMode','manual','scanSets',scanNum,'structureSets',scanNum,'doseSets',[],'view','sagittal','xRange',[],'yRange',[],'coord',median(yCoord))
            end

            %Turn-off all structures except the two selected for comparison
            sliceCallBack('ViewNoStructures')
            for i=1:length(structAll)
                sliceCallBack('toggleSingleStruct',num2str(structAll(i)))
            end

            %Store strNum1, strNum2 and oldLayout in stateS
            if ~isfield(stateS,'structCompare')
                stateS.structCompare.oldLayout = oldLayout;
            end
            stateS.structCompare.structAll = structAll;

            %5> Plot histogram
            %         averageMask3M = logical(zeros(getUniformScanSize(planC{indexS.scan}(scanNum))));
            %         for i=1:length(structAll)
            %             averageMask3M = averageMask3M + getUniformStr(i);
            %         end
            %         averageMask3M = averageMask3M/length(structAll);
            %         [iV,jV,kV]=find3d(averageMask3M);
            %         iMin = min(iV);
            %         iMax = max(iV);
            %         jMin = min(jV);
            %         jMax = max(jV);
            %         kMin = min(kV);
            %         kMax = max(kV);
            %         averageMask3M = averageMask3M(iMin:iMax,jMin:jMax,kMin:kMax);
            %get the min and max i, j, k
            %bigMask=zeros(getUniformScanSize(planC{indexS.scan}(1)));
            bigMask=zeros(getUniformScanSize(planC{indexS.scan}(1)),'int8');
            for i=1:length(structAll)
                mask3M = getUniformStr(structAll(i));
                bigMask=bigMask | mask3M;
            end
            [iV,jV,kV]=find3d(bigMask);
            iMin = min(iV);
            iMax = max(iV);
            jMin = min(jV);
            jMax = max(jV);
            kMin = min(kV);
            kMax = max(kV);
            clear iV kV jV bigMask

            %averageMask3M = single(zeros([length(iMin:iMax) length(jMin:jMax) length(kMin:kMax)]));
            averageMask3M = zeros([length(iMin:iMax) length(jMin:jMax) length(kMin:kMax)],'single');
            %get clipped average mask for each volume
            rateMat = logical([]);
            for i=1:length(structAll)
                mask3M = getUniformStr(structAll(i));
                averageMask3M = averageMask3M + mask3M(iMin:iMax,jMin:jMax,kMin:kMax);
                temp=mask3M(iMin:iMax,jMin:jMax,kMin:kMax);
                rateMat=[rateMat,temp(:)];
            end
            clear mask3M
            averageMask3M = averageMask3M/length(structAll);

            iterlim=100;
            senstart=0.9999*ones(1,length(structAll));
            specstart=0.9999*ones(1,length(structAll));
            [staple3M, sen, spec, Sall] = staple(rateMat,iterlim, single(senstart), single(specstart));
            mean_sen=mean(sen);  std_sen=std(sen);
            mean_spec=mean(spec);  std_spec=std(spec);
            %get volume of an uniformized voxel
            [xUnifV,yUnifV,zUnifV] = getUniformScanXYZVals(planC{indexS.scan}(scanNum));
            vol = (xUnifV(2)-xUnifV(1)) * (yUnifV(1)-yUnifV(2)) * (zUnifV(2)-zUnifV(1));
            numBins = 20;
            obsAgree = linspace(0.001,1,numBins);
            rater_prob=mean(rateMat,1);
            chance_prob=sqrt(rater_prob.*(1-rater_prob));
            chance_prob_mat=repmat(chance_prob,size(rateMat,1),single(1));
            reliability_mat=mean((rateMat-chance_prob_mat)./(1-chance_prob_mat),2);
            %mean_chance_prob=mean(chance_prob);

            for i=1:length(obsAgree)
                %volV(i) = vol * length(find(averageMask3M(:) >= percentV(i)));
                %indAvg = find(averageMask3M(:) < obsAgree(i));
                volV(i)         = sum((averageMask3M(:) >= obsAgree(i))*vol);
                volStapleV(i)   = sum((staple3M(:) >= obsAgree(i))*vol);
                %kappa(i)=(obsAgree(i)-mean_chance_prob)/(1-mean_chance_prob);
                volKappaV(i)   = sum((reliability_mat(:) >= obsAgree(i))*vol);
            end

            %calculate overall kappa
            [kappa,pval,k, pk]=kappa_stats(rateMat,[0 1]); % agreement
            %%  calculations
            min_vol=min(sum(rateMat,1))*vol;
            max_vol=max(sum(rateMat,1))*vol;
            mean_vol=mean(sum(rateMat,1))*vol;
            sd_vol=std(sum(rateMat,1))*vol;


            disp('-------------------------------------------')
            disp(['Overall kappa: ',num2str(kappa)])
            disp(['p-value: ',num2str(pval)])
            disp(['Mean Sensitivity: ',num2str(mean_sen)])
            disp(['Std. Sensitivity: ',num2str(std_sen)])
            disp(['Mean Specificity: ',num2str(mean_spec)])
            disp(['Std. Specificity: ',num2str(std_spec)])
            disp(['Min. volume: ',num2str(min_vol)])
            disp(['Max. volume: ',num2str(max_vol)])
            disp(['Mean volume: ',num2str(mean_vol)])
            disp(['Std. volume: ',num2str(sd_vol)])
            disp(['Intersection volume: ',num2str(volV(end))])
            disp(['Union volume: ',num2str(volV(1))])
            disp('-------------------------------------------')

            clear rateMat averageMask3M chance_prob_mat mask3M indAvg

            stapleToPass = zeros(getUniformScanSize(planC{indexS.scan}(1)),'single');
            stapleToPass(iMin:iMax,jMin:jMax,kMin:kMax) = reshape(staple3M,length(iMin:iMax),length(jMin:jMax),length(kMin:kMax));
            correctedMaskToPass = zeros(getUniformScanSize(planC{indexS.scan}(1)),'single');
            correctedMaskToPass(iMin:iMax,jMin:jMax,kMin:kMax) = reshape(reliability_mat,length(iMin:iMax),length(jMin:jMax),length(kMin:kMax));
            agreementHistogram('init',obsAgree,volV,volStapleV,volKappaV,stapleToPass,correctedMaskToPass)
            %figure, plot(percentV,volV/volV(1))  %percent volume

            %6> Draw mask for structure 1,2 and the difference
            showComparisonMask(structAll,mean(obsAgree))

        catch

            structCompare('EXIT')

        end

    case 'EXIT'

        if ~isfield(stateS,'structCompare')
            return;
        end
        sliceCallBack('layout', stateS.structCompare.oldLayout)
        %unLink the axes
        Ax1 = stateS.handle.CERRAxis(1);
        Ax2 = stateS.handle.CERRAxis(2);
        Ax3 = stateS.handle.CERRAxis(3);
        axisInfo1 = get(Ax1,'userdata');
        axisInfo1.coord       = [];
        axisInfo1.view        = 'transverse';
        axisInfo1.xRange      = [];
        axisInfo1.yRange      = [];
        axisInfo1.scanSets = 1;
        axisInfo1.structureSets = 1;
        set(Ax1, 'userdata', axisInfo1);
        axisInfo2 = get(Ax2,'userdata');
        axisInfo3 = get(Ax3,'userdata');
        axisInfo2.coord       = [];
        axisInfo2.view        = 'sagittal';
        axisInfo2.xRange      = [];
        axisInfo2.yRange      = [];
        axisInfo2.scanSets = 1;
        axisInfo2.structureSets = 1;
        set(Ax2, 'userdata', axisInfo2);
        axisInfo3.coord       = [];
        axisInfo3.view        = 'coronal';
        axisInfo3.xRange      = [];
        axisInfo3.yRange      = [];
        axisInfo3.scanSets = 1;
        axisInfo3.structureSets = 1;
        set(Ax3, 'userdata', axisInfo3);
        stateS = rmfield(stateS,'structCompare');
        %close the active histogram figure
        hFig = findobj('name','Agreement Histogram');
        delete(hFig);
        %setAxisInfo(hAxis, 'coord', coord, 'view', view, 'xRange', [], 'yRange', []);
        % Remove check-mark from the "Consensus" drop-down
        set(findobj(stateS.handle.CERRStructMenu,'label', 'Consensus'),'Checked','off');
        CERRRefresh

end
