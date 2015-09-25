% function [img]=jp2read(filename)
%
% reads a JPEG2000 compliant file and stores information
% in a matlab image

function img=jp2read(filename)
    
    import jj2000.disp.*;
    import jj2000.j2k.util.*;
    import jj2000.j2k.decoder.*;
    import java.awt.image.*;
    import java.awt.*;
    import java.io.*;

    defpl=ParameterList();
    params=Decoder.getAllParameters();

    for i=1:size(params,1)
        if ne(params(i,4),'')
            defpl.setProperty(params(i,1),params(i,4));
        end
    end

    defpl.setProperty('i',filename);
    defpl.setProperty('v','on');
    defpl.setProperty('debug','on');

    isp=ImgScrollPane();

    d=Decoder(ParameterList(defpl),isp);

    ml=StreamMsgLogger(FileOutputStream('out.log'), ...
        FileOutputStream('err.log'),78);
    
    FacilityManager.registerMsgLogger('',ml);

    d.run();

    image=isp.getImage();
    
    w=image.getWidth();
    h=image.getHeight();

    pg=PixelGrabber(image,0,0,w,h,false);
    pg.startGrabbing();
    a=pg.getPixels();
    
    img=java2im(a,h,w);
return