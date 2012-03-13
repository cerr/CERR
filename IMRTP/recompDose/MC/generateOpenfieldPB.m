function generateOpenfieldPB(fieldSizeX, fieldSizeY, beamletSize);

xP = -(fieldSizeX-beamletSize)/2 : beamletSize : (fieldSizeX-beamletSize)/2;
yP = -(fieldSizeY-beamletSize)/2 : beamletSize : (fieldSizeY-beamletSize)/2;
[xPosV, yPosV] = meshgrid(xP, yP);
xPosV = xPosV(:);
yPosV = yPosV(:);
w_field = ones(size(xPosV));
beamlet_delta_x = beamletSize*ones(size(xPosV));
beamlet_delta_y = beamlet_delta_x;

filename = ['PB_', num2str(fieldSizeX), 'x', num2str(fieldSizeY), '_PBsize', num2str(beamletSize), 'cm.mat']
disp ('save PB info to above filename.')
save (filename, 'xPosV', 'yPosV', 'beamlet_delta_x', 'beamlet_delta_y', 'w_field');

% Display generated PB information.
figure;hAxis2 = axes;hold on;
%axis(hAxis2, 'manual');
           %     w_colors = floor((w_field ./ max(w_field))*255)+1;
                set(gcf, 'doublebuffer', 'on');
                for i=1:length(xPosV)
                    patch([xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2], [yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2], w_field(i));
                end
            %    axis([hAxis1 hAxis2], 'ij');
            %    kids = get(hAxis2, 'children');
            %     set(kids, 'edgecolor', 'none');
            %    cMap = colormap('jet');
            %   set(hAxis2, 'color', cMap(1,:));
            
end
