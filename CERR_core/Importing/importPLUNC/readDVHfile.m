function [doseBin, volV] = readDVHfile(filename)

fid=fopen(filename);
for i=1:5
    tline = fgetl(fid);
end

data_count = sscanf(tline, '%f');
for i=1:data_count
    tline = fgetl(fid);
%     disp(tline);
    data = sscanf(tline, '%f');
    doseBin(i) = data(1);
    volV(i) = data(2);
    
    data_count = data_count+1;
end
dvh = [doseBin', volV'];
save('dvh', 'dvh');
fclose(fid);