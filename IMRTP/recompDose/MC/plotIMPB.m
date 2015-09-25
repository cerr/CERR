function plotIMPB(IMCalc)
% JC
% Plot the pb information for IMCalc. IM struct. 
% To make sure the coordinates are alright. and pbs are adjacent to each
% other.
%

figure;
xPosV = IMCalc.beams.xPBPosV;
yPosV = IMCalc.beams.yPBPosV;
beamlet_delta_x = IMCalc.beams.beamletDelta_x;
beamlet_delta_y = IMCalc.beams.beamletDelta_y;
w_field = ones(size(xPosV));
%for i=1:length(xPosV)
for i = 250: 251
   patch([xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2], [yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2], w_field(i));
   hold on; plot(xPosV(i), yPosV(i), 'r.');
end