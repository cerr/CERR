classdef parfor_progressbar < handle
% PARFOR_PROGRESSBAR  Progress bar suitable for multi-process computation.
%
%   H = parfor_progressbar(N, 'message', 'property',value, ...)
%   creates a graphical progress bar with N iterations before completion.
%   A temporary file in tempdir is used to communicate among threads.
%   Any property/value pairs are passed to waitbar internally (optional).
%
%   H.iterate(X) updates the progress bar by X iterations.
%
%   Example:
%   --------
%     N=50;    %total number of parfor iterations
%     hbar = parfor_progressbar(N,'Computing...');  %create the progress bar
%     parfor i=1:N,
%         pause(rand);       % computation
%         hbar.iterate(1);   % update progress by one iteration
%     end
%     close(hbar);   %close progress bar
%
%   Notes:
%   ------
%   Properties cannot be modified while inside a parfor loop. Use iterate only.
%
%   With many short iterations, call iterate() periodically. Example:
%     if mod(i,10)==0,  hbar.iterate(10);  end
%
%   Inspired by the parfor_progress script made by Jeremy Scheff:
%   http://www.mathworks.com/matlabcentral/fileexchange/32101
%
%   See also: WAITBAR, PARFOR.

%   Copyright 2015-2016 Cornell University All Rights Reserved.



% Public properties
properties (SetAccess=protected, GetAccess=public)
    wbh;      % Waitbar figure object handle
    N;        % Total number of iterations expected before completion
end

properties (Dependent, GetAccess=public)
    percent;  % Percentage of completed iterations
end

properties (Dependent, SetAccess=public, GetAccess=public)
    message;  % Message text displayed in waitbar
end

% Internal properties
properties (SetAccess=protected, GetAccess=protected, Hidden)
    ipcfile;  % Path to temporary file for inter-process communication
    htimer;   % Timer object that checks ipcfile for completed iterations
end



methods
    %========================  CONSTRUCTOR  ========================%
    function this = parfor_progressbar(N_init, varargin)
    % Create a new progress bar with N_init iterations before completion.
        
        % Create a unique inter-process communication file.
        for i=1:10,
            f = sprintf('%s%d.txt', mfilename, round(rand*1000));
            this.ipcfile = fullfile(tempdir, f);
            if ~exist(this.ipcfile,'file'), break; end
        end

        if exist(this.ipcfile,'file'),
            error('Too many temporary files. Clear out tempdir.');
        end
    
        % Create a new waitbar 
        this.N = N_init;
        this.wbh = waitbar(0, varargin{:});
        
        % Create timer to periodically update the waitbar in the GUI thread.
        this.htimer = timer( 'ExecutionMode','fixedSpacing', 'Period',0.5, ...
                             'BusyMode','drop', 'Name',mfilename, ...
                             'TimerFcn',@(x,y)this.tupdate );
        start(this.htimer);
    end
    
    
    %=========================  DESTRUCTOR  ========================%
    function delete(this)
        this.close();
    end
    
    function close(this)
    % Closer the progress bar and clean up internal state.
    
        % Stop the timer
        if isa(this.htimer,'timer') && isvalid(this.htimer),
            stop(this.htimer);
            pause(0.01);
            delete(this.htimer);
        end
        this.htimer = [];
        
        % Delete the IPC file.
        if exist(this.ipcfile,'file'),
            delete(this.ipcfile);
        end
        
        % Close the waitbar
        if ishandle(this.wbh)
            close(this.wbh);
        end
        this.wbh = [];
    end
    
    
    %======================  GET/SET METHODS  ======================%
    function percent = get.percent(this)
    % Calculate the fraction of completed iterations from IPC file.
        if ~exist(this.ipcfile, 'file'),
            percent = 0;  % File may not exist before the first iteration
        else
            fid = fopen( this.ipcfile, 'r' );
            percent = sum(fscanf(fid, '%d')) / this.N;
            percent = max(0, min(1,percent) );
            fclose(fid);
        end
    end
    
    
    function set.message(this, newMsg)
    % Update the progress bar's displayed message.
        if ishandle(this.wbh),
            waitbar( this.percent, this.wbh, newMsg );
        end
    end
    
    
    function iterate(this, Nitr)
    % Update the progress bar by Nitr iterations (or 1 if not specified).
        if nargin<2,  Nitr = 1;  end
    
        fid = fopen(this.ipcfile, 'a');
        fprintf(fid, '%d\n', Nitr);
        fclose(fid);
    end
    
    
end %public methods



%=====================  INTERNAL METHODS  =====================%
methods (Access=protected, Hidden)
    
    
    function tupdate(this)
    % Check the IPC file and update the waitbar with progress.
    
        if ishandle(this.wbh),
            waitbar( this.percent, this.wbh );
        else
            % Kill the timer if the waitbar is closed.
            close(this);
        end
    end
    
    
end %private methods




end %classdef





