function isocontrols(fig, onoff,xmesh,ymesh,zmesh)
% Set up FIG to have an ISO surface controller on the bottom.
% ONOFF indicates if the controller is being turned ON or OFF

% Check variables
error(nargchk(2,5,nargin))

  d = getappdata(fig, 'sliceomatic');
  
  if onoff
      if nargin == 5
          
          lim=[min(min(min(d.data))) max(max(max(d.data)))];
  
    set(d.axiso,'handlevisibility','on');
    set(fig,'currentaxes',d.axiso);
    set(d.axiso, 'xlim',lim,...
                 'ylim',[1 5],...
                 'clim',lim);
    image('parent',d.axiso,'cdata',1:64,'cdatamapping','direct',...
          'xdata',lim,'ydata',[0 5],...
          'alphadata',.6, ...
          'hittest','off');
    title('Iso Surface Controller');
    set(d.axiso,'handlevisibility','off');
          
      else
          
          
    lim=[min(min(min(d.data))) max(max(max(d.data)))];
  
    set(d.axiso,'handlevisibility','on');
    set(fig,'currentaxes',d.axiso);
    set(d.axiso, 'xlim',lim,...
                 'ylim',[1 5],...
                 'clim',lim);
    image('parent',d.axiso,'cdata',1:64,'cdatamapping','direct',...
          'xdata',lim,'ydata',[0 5],...
          'alphadata',.6, ...
          'hittest','off');
    title('Iso Surface Controller');
    set(d.axiso,'handlevisibility','off');
end

  else
    % Turn off the controller
    
    delete(findobj(d.axiso,'type','image'));
    %delete(d.axiso);

  end