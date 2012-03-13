function [newFluenceMap rowLeafPositions] = mergeFluenceMap(inflMap, rowLeafPositions, resolution);
% JC Sept 18, 2007
% ALG: For each pixel, search the 8 neighbors, merge them, if the change of
% the intensity is less than the threshold.

% General flow:
% Step, group the inter-leaf leakage part, i.e.
%type A: interleaf leakage part, with width 1mm.
%type B: the full leaf width, eg. 0.5cm or 1cm

% How to distinguish them?
% At the first column, check the gradient.
%

% The first colume of inflMap
% Do not use, since the 
% s = diff(inflMap(:,1));

% Why s = diff(inflMap(:,2)) is always zero?
% The second colume of inflMap
% s = diff(inflMap(:,2));
% Use first column. Worked for both "bar pattern" and the "complimental bar
% pattern"
s = diff(inflMap(:,1));

newFluenceMap = struct('width', [], 'intensity', []);

newRow = 1;
y=0;

widthLeaf = 5/resolution;       % The width of the MLC leaf is 5mm. (Should work for 10mm=1cm leaf width)
% Havent' tried on resolution = 0.5mm.
iStart = mod(size(inflMap,1), widthLeaf)+1;
newFluenceMap(newRow).width = iStart-1;    %mm
newFluenceMap(newRow).intensity = inflMap(1+1,:);  % second row.


for i = iStart: length(s),
    if (s(i) ~= 0)
        newRow = newRow + 1;
        newFluenceMap(newRow).width = resolution;
        newFluenceMap(newRow).intensity = inflMap(i+1,:);
    else
        if (i == iStart)
            newRow = newRow + 1;
            newFluenceMap(newRow).width = resolution;
        end
        newFluenceMap(newRow).width = newFluenceMap(newRow).width + resolution;
        newFluenceMap(newRow).intensity = inflMap(i+1,:);
    end
end

y = 0;
rowLeafPositions = zeros(size(newFluenceMap,2)+1,1);
rowLeafPositions(1) = y+1;
for i=1:length(newFluenceMap)
    % Following works for resolution == 1.
    % y =y+newFluenceMap(i).width;
    y =y+newFluenceMap(i).width/resolution;
    rowLeafPositions(i+1) = y+1;
end


[Ncol Nrow] = size(inflMap);

% for i = 1 : Nrow,
figure;hAxis1 = axes;imagesc(inflMap);
set(gcf, 'renderer', 'zbuffer')
figure;hAxis2 = axes;hold on;
set(gcf, 'renderer', 'zbuffer')
xL = get(hAxis1, 'xlim');
yL = get(hAxis1, 'ylim');
set(hAxis2, 'xlim', xL);
set(hAxis2, 'ylim', yL);
axis(hAxis2, 'manual');
%     w_colors = floor((w_field ./ max(w_field))*255)+1;
set(gcf, 'doublebuffer', 'on');

%y=0.05; %(?)
y=0;
for i=1:length(newFluenceMap)
    % Following works for resolution == 1.
    % y =y+newFluenceMap(i).width;
    y =y+newFluenceMap(i).width/resolution;
    for j=1:length(newFluenceMap(i).intensity)
% The display scheme here is problematic. To be worked on. 
        patch([xL(1) xL(1) xL(2) xL(2) xL(1)], [y-newFluenceMap(i).width/resolution y y y-newFluenceMap(i).width/resolution y-newFluenceMap(i).width/resolution], newFluenceMap(i).intensity(j));
    end
end
axis([hAxis1 hAxis2], 'ij');
kids = get(hAxis2, 'children');
%     set(kids, 'edgecolor', 'none');
cMap = colormap('jet');
set(hAxis2, 'color', cMap(1,:));

return;
 
   
        