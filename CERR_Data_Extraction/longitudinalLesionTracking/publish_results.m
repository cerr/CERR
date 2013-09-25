% %%

dirS = dir(absolutePathForImageFiles);
dirS(1:3) = [];
%%
for lesionNum = 1:length(lesionStory)
    disp(['Lesion ',num2str(lesionNum)])
    hFig = figure('position',[5 5 1000 1000]);
    hold on,
    set(gca,'position',[0.15 0.38 0.8 0.58])
    %plot(longitLen{lesionNum},'r','linewidth',2)
    [~,remC] = strtok({dirS.name},'_');
    [scanLesionUIDc,remC] = strtok(remC,'_');
    indImagesV = strmatch(['_',num2str(lesionNum),'.png'],remC);
    % Get scanUIDs for these indImagesV
    scanNumV = [];
    for i = 1:length(indImagesV)
        imgNum = indImagesV(i);
        [~,rem] = strtok(dirS(imgNum).name,'_');
        scanUID = strtok(rem,'_');
        scanNumV(i) = strmatch(scanUID,scanUIDc);
    end
    [scanNumV,indSort] = sort(scanNumV);
    indImagesV = indImagesV(indSort);
    
    hp = plot(dateV(lesionStory{lesionNum}(1):lesionStory{lesionNum}(2)),longitLen{lesionNum},'r','linewidth',3);
    plot(dateV(lesionStory{lesionNum}(1):lesionStory{lesionNum}(2)),longitLen{lesionNum},'b.','markerSize',25);
    ylabel('cm','fontsize',35)
    set(gca,'xTick',dateV(lesionStory{lesionNum}(1):lesionStory{lesionNum}(2)))
    set(gca,'xTickLabel',datestr(dateV(lesionStory{lesionNum}(1):lesionStory{lesionNum}(2))))
    rotateXLabels(gca, 90)
    set(gca,'fontsize',20)
    grid on
    snapnow;
    close(hFig)
    hFig = figure('position',[8 10 1500 1500]);    
    set(gca,'position',[0.05 0.05 0.75 0.75])    
    for i = 1:length(indImagesV)
        imgNum = indImagesV(i);
        imageFilename = ['scan_',scanUIDc{scanNumV(i)},'_',num2str(lesionNum),'.png'];
        [background, map] = imread(fullfile(absolutePathForImageFiles,imageFilename));
        %subplot(1,length(indImagesV),i)
        image(background, 'CDataMapping', 'direct')
        axis('off')
        title(datestr(dateAllV(scanNumV(i))),'fontsize',60)
        snapnow;
    end        
    sprintf('\n');
    disp('_______________________________________________________________')
    sprintf('\n');
    %snapnow
    close(hFig)
end

