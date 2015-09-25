% function [enc]=jp2write(img,filename,indexing,arguments)
%
% It takes a matlab image and stores it in a JPEG2000 compliant file.
% Important notice: the JVM matlab uses is important in order to
% see if jars provided in classpath are compatible or not. If not,
% the only message thrown is 'class not found'.
% Here I've built the jars using -source 1.4 -target 1.4 options in javac
% while it is possible to change the JVM that Matlab is running
% by setting the MATLAB_JAVA system variable. In order to know which
% version of JVM Matlab is running the command is version -java
% 
% Using Matlab 7.0.1.24704 (R14) Service Pack 1
% the corresponding JVM is
% Java 1.4.2_05 with Sun Microsystems Inc. Java HotSpot(TM) Client VM
%    (mixed mode)
%
% To resemble the use of the standard command line environment, the 
% arguments variable is intented to be a big string with all the
% jj2000 parameters passes as if they were to be driving the command
% line implementation of the encoder.

function enc=jp2write(img,filename,indexing,arguments)

    import middleware.*;
    import jj2000.j2k.util.*;
    import jj2000.j2k.encoder.*;

    % la sistemo sopra l'immagine in modo che qui arrivi sempre RGB
    
    [image]=im2java(img);

    %imgr=ImgReaderMTLB(image);
    
    defpl=ParameterList();
    
    params=Encoder.getAllParameters();

    for i=1:size(params,1)
        if ne(params(i,4),'')
            defpl.setProperty(params(i,1),params(i,4));
            disp(sprintf('%s=%s',char(params(i,1)),char(params(i,4))));
        end
    end
    
    pl=ParameterList(defpl);
    
    pl.setProperty('v','on');
    pl.setProperty('debug','on');
    pl.setProperty('Qguard_bits','2'); % default values
    pl.setProperty('file_format','on'); % this to use XML
    pl.setProperty('o',filename); % to resemble matlab
    
    na=1;
    [t(na).s,r]=strtok(arguments);
    while(~isempty(r))
        na=na+1;
        [t(na).s,r]=strtok(r)
    end
    argv=javaArray('java.lang.String',na);
    for i=1:na
        argv(i)=java.lang.String(t(i).s);
        
    end
% [PENDING] Gestione degli spazi nei nomi dei file delle ROI
% Serve agire sullo strato di middleware
%     argv(na)=java.lang.String(t(na).s);
%     argv(na)=javaMethod('replaceAll',argv(na),'\*','\\ ')
    
    pl.parseArgs(argv);
    
    enc=MyEncoder(ParameterList(pl),image,indexing);
    
    javaMethod('run',enc);

return