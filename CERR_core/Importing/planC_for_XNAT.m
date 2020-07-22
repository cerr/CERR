function planC_for_XNAT(dicomPath,cerrPath,xhost,xproj,xsubj,xexp)

importDICOM(dicomPath,cerrPath);

cerrFile = ls([cerrPath filesep '*.mat']);

load([cerrPath filesep cerrFile]);

planC{indexS.header}.xnatInfo = struct('host',xhost,'project_id',xproj,'subject_id',xsubj,'experiment_id',xexp);

save([cerrPath filesep cerrFile],'planC');