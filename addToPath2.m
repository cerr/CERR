function addToPath2(cerrPath)

G = dir(cerrPath);

for i = 1:numel(G)
    Gi = G(i);
    if Gi.isdir
        if ~strcmp(Gi.name(1),'.')
            subpath = fullfile(Gi.folder,Gi.name);
            %disp(['Adding to path ... ' subpath]);
            addpath(genpath(subpath));
        end
    end
end