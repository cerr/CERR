figure; 
for beam = 1:5;
	subplot(3,2,beam); plot(IM.beams(beam).xPBPosV, IM.beams(beam).yPBPosV, '.'); 
	title(['beam ',num2str(beam), 'gA ', num2str(IM.beams(beam).gantryAngle)]);
end
