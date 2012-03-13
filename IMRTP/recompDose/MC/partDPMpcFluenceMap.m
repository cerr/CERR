bf = planC{7}.FractionGroupSequence.Item_1.ReferencedBeamSequence.(['Item_' num2str(indexBeam)]);
           bs = planC{7}.BeamSequence.(['Item_' num2str(indexBeam)]);

        LS = getDICOMLeafPositions(bs)


        [inflMap, xV, yV, colDividerXCoord, rowDividerYCoord, rowLeafPositions] = getLSInfluenceMapFactor(LS,leak,bs.BeamNumber);

        gA = bs.ControlPointSequence.Item_1.GantryAngle;
        iC = bs.ControlPointSequence.Item_1.IsocenterPosition;
        IMBase.beams(1).gantryAngle = gA;

        if ~isfield(planC{7}.PatientSetupSequence,(['Item_' num2str(indexBeam)]))
            position = {planC{7}.PatientSetupSequence.(['Item_' num2str(1)]).PatientPosition};
        else
            position = {planC{7}.PatientSetupSequence.(['Item_' num2str(indexBeam)]).PatientPosition};
        end

        if strcmpi(position, 'HFP')
            IMBase.beams(1).isocenter.x = iC(1)/10;
            IMBase.beams(1).isocenter.y = iC(2)/10;
            IMBase.beams(1).isocenter.z = -iC(3)/10;
        else
            IMBase.beams(1).isocenter.x = iC(1)/10;
            IMBase.beams(1).isocenter.y = -iC(2)/10;
            IMBase.beams(1).isocenter.z = -iC(3)/10;
        end

        IMBase.beams(1).isodistance = bs.SourceAxisDistance/10;

        IMBase.beams(1).xRel = IMBase.beams(1).isodistance * sindeg(IMBase.beams(1).gantryAngle);

        IMBase.beams(1).yRel = IMBase.beams(1).isodistance * cosdeg(IMBase.beams(1).gantryAngle);

        IMBase.beams(1).beamEnergy = bs.ControlPointSequence.Item_1.NominalBeamEnergy;


        %[PBX] = getPBXCoorFromFluence(inflMap, rowLeafPositions, 2, 50, colDividerXCoord, rowDividerYCoord, 10);
        [PBX] = getPBXCoorFromFluence(inflMap, rowLeafPositions, 2, 20, colDividerXCoord, rowDividerYCoord, 25);


        [xPosV, yPosV, beamlet_delta_x, beamlet_delta_y, w_field] = getPBVectors(PBX,rowLeafPositions,colDividerXCoord,rowDividerYCoord,inflMap);

        figure;hAxis1 = axes;imagesc([xV(1)+.05 xV(end)-.05], [yV(1)+.05, yV(end)-.05], inflMap);
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
                for i=1:length(xPosV)
                    patch([xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) + beamlet_delta_x(i)/2 xPosV(i) - beamlet_delta_x(i)/2], [yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) + beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2 yPosV(i) - beamlet_delta_y(i)/2], w_field(i));
                end
                axis([hAxis1 hAxis2], 'ij');
                kids = get(hAxis2, 'children');
            %     set(kids, 'edgecolor', 'none');
                cMap = colormap('jet');
                set(hAxis2, 'color', cMap(1,:));