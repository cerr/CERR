function [varargout] = CONVERT_voxels_to_stl(STLname,gridDATA,gridX,gridY,gridZ,varargin)
% CONVERT_voxels_to_stl  Convert a voxelised object contained within a 3D logical array into an STL surface mesh
%==========================================================================
% AUTHOR        Adam H. Aitkenhead
% CONTACT       adam.aitkenhead@christie.nhs.uk
% INSTITUTION   The Christie NHS Foundation Trust
% DATE          24th May 2010
%
% EXAMPLE       CONVERT_voxels_to_stl(STLname,gridDATA,gridX,gridY,gridZ,STLformat)
%       ..or..  [faces,vertices] = CONVERT_voxels_to_stl(STLname,gridDATA,gridX,gridY,gridZ,STLformat)
%
% INPUTS        STLname   - string            - Filename of the STL file.
%
%               gridDATA  - 3D logical array of size (P,Q,R) - Voxelised data
%                                     1 => Inside the object
%                                     0 => Outside the object
%
%               gridX     - A 1xP array       - List of the X axis coordinates.
%               gridY     - A 1xQ array       - List of the Y axis coordinates.
%               gridZ     - A 1xR array       - List of the Z axis coordinates.
%
%               STLformat - string (optional) - STL file format: 'binary' or 'ascii'
%
% OUTPUTS       faces    - Nx3 array   - A list of the vertices used in
%                          each facet of the mesh, identified using the row
%                          number in the array vertices.
%
%               vertices - Nx3 array   - A list of the x,y,z coordinates of
%                          each vertex in the mesh.
%               
%==========================================================================

%==========================================================================
% VERSION  USER  CHANGES
% -------  ----  -------
% 100524   AHA   Original version
% 100526   AHA   Improved memory handling
% 100530   AHA   Major speed improvement
% 100818   AHA   Improved documentation
% 101123   AHA   Allow the STL to be written in binary or ascii format
% 110314   AHA   Tidied the code a little
% 120709   AHA   Optionally output the mesh (Faces,Vertices) data
%==========================================================================


%======================================================
% CHECK THE INPUTS
%======================================================

if nargin==6
  STLformat = lower(varargin{1});
else
  STLformat = 'ascii';
end

if size(gridX,1)>size(gridX,2)
  gridX = gridX';
end
if size(gridY,1)>size(gridY,2)
  gridY = gridY';
end
if size(gridZ,1)>size(gridZ,2)
  gridZ = gridZ';
end

if ~isequal(size(gridDATA),[numel(gridX),numel(gridY),numel(gridZ)])
  error(' The dimensions of gridDATA do not match the dimensions of gridX, gridY, gridZ.')
end

gridDATA = logical(gridDATA);

%======================================================
% REMOVE ANY OUTER UNUSED AREAS FROM gridDATA
%======================================================

objectIND = find(gridDATA==1);
[objectX,objectY,objectZ] = ind2sub([numel(gridX),numel(gridY),numel(gridZ)],objectIND);

if objectX(1)~=objectX(end)
  gridDATA = gridDATA(min(objectX):max(objectX),:,:);
  gridX    = gridX(min(objectX):max(objectX));
end

if objectY(1)~=objectY(end)
  gridDATA = gridDATA(:,min(objectY):max(objectY),:);
  gridY    = gridY(min(objectY):max(objectY));
end

if objectZ(1)~=objectZ(end)
  gridDATA = gridDATA(:,:,min(objectZ):max(objectZ));
  gridZ    = gridZ(min(objectZ):max(objectZ));
end

%======================================================
% DEFINE THE LOWER AND UPPER LIMITS OF EACH VOXEL
%======================================================

gridXsteps = gridX(2:end)-gridX(1:end-1);
gridXlower = gridX-[gridXsteps(1),gridXsteps]/2;
gridXupper = gridX+[gridXsteps,gridXsteps(end)]/2;

gridYsteps = gridY(2:end)-gridY(1:end-1);
gridYlower = gridY-[gridYsteps(1),gridYsteps]/2;
gridYupper = gridY+[gridYsteps,gridYsteps(end)]/2;

gridZsteps = gridZ(2:end)-gridZ(1:end-1);
gridZlower = gridZ-[gridZsteps(1),gridZsteps]/2;
gridZupper = gridZ+[gridZsteps,gridZsteps(end)]/2;

%======================================================
% CHECK THE DIMENSIONS OF THE GRID
%======================================================

voxcountX = numel(gridX);
voxcountY = numel(gridY);
voxcountZ = numel(gridZ);

%======================================================
% FOR EACH VOXEL, IDENTIFY WHETHER ITS 6 NEIGHBOURS ARE WITHIN THE OBJECT.
% IF ANY NEIGHBOUR IS OUTSIDE THE OBJECT, DRAW FACETS BETWEEN THE VOXEL AND
% THAT NEIGHBOUR.
%======================================================

gridDATAshifted = false(size(gridDATA));
if voxcountX>2
  gridDATAwithborder = cat(1,false(1,voxcountY,voxcountZ),gridDATA,false(1,voxcountY,voxcountZ));         %Add border
  gridDATAshifted    = cat(1,false(1,voxcountY,voxcountZ),gridDATAshifted,false(1,voxcountY,voxcountZ));  %Add border
  gridDATAshifted    = gridDATAshifted + circshift(gridDATAwithborder,[-1,0,0]) + circshift(gridDATAwithborder,[1,0,0]);
  gridDATAshifted    = gridDATAshifted(2:end-1,:,:);  %Remove border
end
if voxcountY>2
  gridDATAwithborder = cat(2,false(voxcountX,1,voxcountZ),gridDATA,false(voxcountX,1,voxcountZ));         %Add border
  gridDATAshifted    = cat(2,false(voxcountX,1,voxcountZ),gridDATAshifted,false(voxcountX,1,voxcountZ));  %Add border
  gridDATAshifted    = gridDATAshifted + circshift(gridDATAwithborder,[0,-1,0]) + circshift(gridDATAwithborder,[0,1,0]);
  gridDATAshifted    = gridDATAshifted(:,2:end-1,:);  %Remove border
end
if voxcountZ>2
  gridDATAwithborder = cat(3,false(voxcountX,voxcountY,1),gridDATA,false(voxcountX,voxcountY,1));         %Add border
  gridDATAshifted    = cat(3,false(voxcountX,voxcountY,1),gridDATAshifted,false(voxcountX,voxcountY,1));  %Add border
  gridDATAshifted    = gridDATAshifted + circshift(gridDATAwithborder,[0,0,-1]) + circshift(gridDATAwithborder,[0,0,1]);
  gridDATAshifted    = gridDATAshifted(:,:,2:end-1);  %Remove border
end

%Identify the voxels which are at the boundary of the object:
edgevoxelindices = find(gridDATA==1 & gridDATAshifted<6)';
edgevoxelcount   = numel(edgevoxelindices);

%Calculate the number of facets there wil be in the final STL mesh:
facetcount = 2 * (edgevoxelcount*6 - sum(gridDATAshifted(edgevoxelindices)) );

%Create an array to record...
%Cols 1-6: Whether each edge voxel's 6 neighbours are inside or outside the object.
neighbourlist = false(edgevoxelcount,6);

%Initialise arrays to store the STL mesh data:
meshXYZ    = zeros(facetcount,3,3);
normalsXYZ = zeros(facetcount,3);

%Create a counter to keep track of how many facets have been written as the
%following 'for' loop progresses:
facetcountsofar = 0;

for loopP = 1:edgevoxelcount
  
  [subX,subY,subZ] = ind2sub(size(gridDATA),edgevoxelindices(loopP));
  
  if subX==1
    neighbourlist(loopP,1) = 0;
  else
    neighbourlist(loopP,1) = gridDATA(subX-1,subY,subZ);
  end
  if subY==1
    neighbourlist(loopP,2) = 0;
  else
    neighbourlist(loopP,2) = gridDATA(subX,subY-1,subZ);
  end
  if subZ==voxcountZ
    neighbourlist(loopP,3) = 0;
  else
    neighbourlist(loopP,3) = gridDATA(subX,subY,subZ+1);
  end
  if subY==voxcountY
    neighbourlist(loopP,4) = 0;
  else
    neighbourlist(loopP,4) = gridDATA(subX,subY+1,subZ);
  end
  if subZ==1
    neighbourlist(loopP,5) = 0;
  else
    neighbourlist(loopP,5) = gridDATA(subX,subY,subZ-1);
  end
  if subX==voxcountX
    neighbourlist(loopP,6) = 0;
  else
    neighbourlist(loopP,6) = gridDATA(subX+1,subY,subZ);
  end
  
  facetCOtemp         = zeros(2*(6-sum(neighbourlist(loopP,:))),3,3);
  normalCOtemp        = zeros(2*(6-sum(neighbourlist(loopP,:))),3);
  facetcountthisvoxel = 0;
  
  if neighbourlist(loopP,1)==0   %Neighbouring voxel in the -x direction
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXlower(subX),gridYlower(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXlower(subX),gridYlower(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXlower(subX),gridYupper(subY),gridZlower(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [-1,0,0];
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXlower(subX),gridYupper(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXlower(subX),gridYupper(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXlower(subX),gridYlower(subY),gridZupper(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [-1,0,0];
    facetcountsofar                        = facetcountsofar+2;
  end
  if neighbourlist(loopP,2)==0   %Neighbouring voxel in the -y direction
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXlower(subX),gridYlower(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXupper(subX),gridYlower(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXlower(subX),gridYlower(subY),gridZupper(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,-1,0];
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXupper(subX),gridYlower(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXlower(subX),gridYlower(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXupper(subX),gridYlower(subY),gridZlower(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,-1,0];
    facetcountsofar                        = facetcountsofar+2;
  end
  if neighbourlist(loopP,3)==0   %Neighbouring voxel in the +z direction
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXupper(subX),gridYlower(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXupper(subX),gridYupper(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXlower(subX),gridYlower(subY),gridZupper(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,0,1];
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXlower(subX),gridYupper(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXlower(subX),gridYlower(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXupper(subX),gridYupper(subY),gridZupper(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,0,1];
    facetcountsofar                        = facetcountsofar+2;
  end
  if neighbourlist(loopP,4)==0   %Neighbouring voxel in the +y direction
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXupper(subX),gridYupper(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXlower(subX),gridYupper(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXupper(subX),gridYupper(subY),gridZupper(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,1,0];
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXlower(subX),gridYupper(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXupper(subX),gridYupper(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXlower(subX),gridYupper(subY),gridZlower(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,1,0];
    facetcountsofar                        = facetcountsofar+2;
  end
  if neighbourlist(loopP,5)==0   %Neighbouring voxel in the -z direction
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXlower(subX),gridYlower(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXlower(subX),gridYupper(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXupper(subX),gridYlower(subY),gridZlower(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,-1,0];
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXupper(subX),gridYupper(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXupper(subX),gridYlower(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXlower(subX),gridYupper(subY),gridZlower(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [0,-1,0];
    facetcountsofar                        = facetcountsofar+2;
  end
  if neighbourlist(loopP,6)==0   %Neighbouring voxel in the +x direction
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXupper(subX),gridYupper(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXupper(subX),gridYupper(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXupper(subX),gridYlower(subY),gridZlower(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [1,0,0];
    facetcountthisvoxel                    = facetcountthisvoxel+1;
    facetCOtemp(facetcountthisvoxel,1:3,1) = [ gridXupper(subX),gridYlower(subY),gridZupper(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,2) = [ gridXupper(subX),gridYlower(subY),gridZlower(subZ) ];
    facetCOtemp(facetcountthisvoxel,1:3,3) = [ gridXupper(subX),gridYupper(subY),gridZupper(subZ) ];
    normalCOtemp(facetcountthisvoxel,1:3)  = [1,0,0];
    facetcountsofar                        = facetcountsofar+2;
  end
  
  meshXYZ(facetcountsofar-facetcountthisvoxel+1:facetcountsofar,:,:)  = facetCOtemp;
  normalsXYZ(facetcountsofar-facetcountthisvoxel+1:facetcountsofar,:) = normalCOtemp;
  
end

%======================================================
% WRITE THE MESH TO AN ASCII STL FILE
%======================================================

WRITE_stl(STLname,meshXYZ,normalsXYZ,STLformat)


%======================================================
% PREPARE THE OUTPUT ARGUMENTS
%======================================================

if nargout==2
  [faces,vertices] = CONVERT_meshformat(meshXYZ);
  varargout(1)     = {faces};
  varargout(2)     = {vertices};
end


end %function


