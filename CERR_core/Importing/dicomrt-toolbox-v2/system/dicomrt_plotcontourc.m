function dicomrt_plotcontourc(data)
% dicomrt_plotcontourc(data)
%
% Plot contours created by contourc.
%
% See also: contourc
%
% Copyright (C) 2002 Emiliano Spezi (emiliano.spezi@physics.org) 

% scan and plot data
start=1;
highestpair=0;
while (length(data)-highestpair)~=0
    npair=data(2,start);
    lowestpair=start+1;
    highestpair=start+npair;
    plot(data(1,lowestpair:highestpair),data(2,lowestpair:highestpair),'w','LineWidth',2);
    start=highestpair+1;
end
