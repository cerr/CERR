% animateToFile.m
%
% This script captures animation of 3D rendering to a file
%
% APA, 10/08/2021

videoFileName = '/path/to/save/animation.avi';

hFig = gcf; % get this from stateS in future
hAxis = gca;

azV = -180:180;
numAz = length(azV);
azV = repmat(azV,[1,4]);
elV = linspace(-90,-45,numAz);
elV = [elV,linspace(-45,90,numAz)];
elV = [elV,linspace(90,0,numAz)];
elV = [elV,linspace(0,20,numAz)];

% Prepare the new file.
vidObj = VideoWriter(videoFileName);
open(vidObj);

for k = 1:length(azV)
    view(hAxis,azV(k),elV(k))
    
    % Write each frame to the file.
    currFrame = getframe(hFig);
    writeVideo(vidObj,currFrame);
end

% Close the file.
close(vidObj);
