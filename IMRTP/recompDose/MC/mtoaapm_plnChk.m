function [xAAPM, yAAPM]=mtoaapm(Row, Col, Dims, gridUnits, offset)
%function [xAAPM, yAAPM]=mtoaapm(Row,Col,Dims)  OR (Row,Col,Dims,gridUnits,offset)
%Description: Convert from Matlab-natural matrix coordinates to AAPM format
%coordinates (with origin at the center of the image).
%
%Inputs:
%Row -- A vector of row coordinates
%Col -- A vector of column coordinates
%Dims -- A length-2 vector, giving the numbers of rows first then columns.
%gridUnits -- gives grid units on [y side, x side]
%offset -- gives offset on [y side, x side]
%
%Outputs:
%xAAPM -- x coordinates in AAPM system assuming x = 0 is the midpoint.  (unless offset is provided)
%yAAPM -- y coordinates in AAPM system assuming y = 0 is the midpoint.  (unless offset is provided)
%
%Globals: None.
%
%Storage needed: Twice the size of the (x,y) input vectors.
%
%Internal parameters: None.
%
%Last modified: 5 Oct 01, JOD.
%              19 Jul 02, VHC.  (added offset capability) 
%
%Author: J. O. Deasy, deasy@radonc.wustl.edu
%
%References: W. Harms, Specifications for Tape/Network Format for Exchange of
%Treatment Planning Information, version 3.22., RTOG 3D QA Center,
%(http://rtog3dqa.wustl.edu), 1997.
%
%copyright (c) 2001, J.O. Deasy and Washington University in St. Louis.
%Use is granted for non-commercial and non-clinical applications.
%No warranty is expressed or implied for any use whatever.


yAAPMShifted=-Row+Dims(1);
xAAPMShifted=Col;

yOffset=Dims(1)/2-0.5;
xOffset=Dims(2)/2+0.5;

xAAPM=xAAPMShifted-xOffset;
yAAPM=yAAPMShifted-yOffset;

if nargin > 3
  xAAPM = xAAPM*gridUnits(2)+offset(2);
  yAAPM = yAAPM*gridUnits(1)+offset(1);
end
