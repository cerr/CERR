function plan = read_pinnacle_plan_trial(filename,trialname)
%
%	plan = read_pinnacle_plan_trial(filename,trialname)
%	read_pinnacle_plan_trial(filename) to list all trials

fid = fopen(filename,'r');
if fid < 0
	fprintf('Cannot open file: %s.\n',filename);
	return;
end

lineno = 0;
lastlineistrial = 0;
trialno = 0;
plan = [];

% Scan the whole file for all available trials
while 1
	tl = fgetl(fid);
	lineno = lineno+1;
	
	if feof(fid)
		break;
	end

	if length(tl) >= 10 && strcmp(tl(1:10),'  Name = "') == 1 && lastlineistrial == 1
		outl = strsplit_cerr('=',tl);
		tname = ddeblank(outl{2});
		tname = tname(1:end-2);
		tname = tname(2:end);
		trialnames{trialno,1} = tname;
		%triallines(trialno) = lineno-1;
        triallines(trialno) = trialLineNo;
	end
	
% 	if strcmp(tl,'Trial ={') == 1
% 		lastlineistrial = 1;
% 		trialno = trialno + 1;
% 	else
% 		lastlineistrial = 0;
% 	end
	if strcmp(tl,'Trial ={') == 1
		lastlineistrial = 1;
		trialno = trialno + 1;
        trialLineNo = lineno - 1;
    elseif strcmp(tl,'};') == 1
		lastlineistrial = 0;
	end

end

if ~exist('trialname','var')
	if length(trialnames) > 1
		disp('Trial names');
		trialnames
		return;
	else
		trialname = trialnames{1};
		fprintf('Trail name = %s\n',trialname);
	end
end

if ~exist('triallines','var')
    disp('Trail is not found');
    fclose(fid);
    return;
end

% find the trial
found = 0;
for k = 1:length(triallines)
	if strcmp(trialnames{k},trialname)
		found = 1;
		break;
	end
end

if found == 0
	disp('Trail is not found');
	fclose(fid);
	return;
end

fclose(fid);

fid = fopen(filename,'r');
lineno = 0;
while lineno < triallines(k)-1
	fgetl(fid);
	lineno = lineno + 1;
end

% Read the whole trial into the MATLAB structure
[planname,plan] = read_1_field_pinnacle(fid);


fclose(fid);

return;



