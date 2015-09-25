function dicomrt_plotctramp(name,materials,mat_ct_up_bound,density_lo_bound,density_up_bound)
% dicomrt_plotctramp(name,materials,mat_ct_up_bound,density_lo_bound,density_up_bound)
%
% Plot ct conversion ramp used to create ct-phantom.
%
% materials			    materials name
% mat_ct_up_bound		materials upper bound (see dosxyz user's manual)
% density_lo_bound		density lower bound (see dosxyz user's manual)
% density_up_bound		density upper bound (see dosxyz user's manual)
%
% See also dicomrt_ctcreate, dicomrt_createwphantom
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% Plot
figure
set(gcf,'Name',['dicomrt_plotctramp: CT conversion ramp for ',name]);
hold
for i=1:size(materials,1)
    if i==1
        plot([0 mat_ct_up_bound(i)], [0 density_up_bound(i)],'LineWidth',2);
        text(mat_ct_up_bound(i)/2,density_up_bound(i)/2,['\leftarrow', materials(i,:)],'FontSize',12,'FontWeight','bold');
    else
        locateXtext=(mat_ct_up_bound(i)-mat_ct_up_bound(i-1))./2+mat_ct_up_bound(i-1);
        locateYtext=(density_up_bound(i)-density_lo_bound(i))./2+density_lo_bound(i);
        plot([mat_ct_up_bound(i-1) mat_ct_up_bound(i)], [density_lo_bound(i) density_up_bound(i)],...
            'LineWidth',2);
        plot(mat_ct_up_bound(i-1),density_lo_bound(i),'Linestyle','none','Marker','d','MarkerFaceColor','auto');
        text(locateXtext,locateYtext,['  \leftarrow ', materials(i,:)],'FontSize',12,'FontWeight','bold');
    end
end
grid on
title('CT conversion ramp','FontSize',18);
ylabel('Density (g/cm^3)','FontSize',14);
xlabel('CT number','FontSize',14);
set(gca,'XLim',[0 max(mat_ct_up_bound)])
set(gca,'YLim',[0 max(density_up_bound)])