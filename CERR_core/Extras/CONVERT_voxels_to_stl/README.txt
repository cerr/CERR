Converting a 3D logical array into an STL surface mesh
======================================================
 
Adam H. Aitkenhead 
adam.aitkenhead@christie.nhs.uk 
The Christie NHS Foundation Trust 
24th May 2010
 
 
USAGE
=====
 
>>  CONVERT_voxels_to_stl(STLname,gridDATA,gridX,gridY,gridZ,'ascii')
..or..
>>  [faces,vertices] = CONVERT_voxels_to_stl(STLname,gridDATA,gridX,gridY,gridZ,STLformat)

converts the voxelised object contained within the 3D logical array <gridINPUT> into an STL surface mesh, which is saved to the ascii file <STLin>.   The x,y,z axes for <gridINPUT> are defined by <gridX>, <gridY> and <gridZ>.  The (faces,vertices) data are optional outputs.
 
 
INPUTS
======
 
STLname   - string            - Filename of the STL file.
gridINPUT - 3D logical array of size (P,Q,R) - The voxelised object (1 => Inside the object, 0 => Outside the object)
gridX     - A 1xP array       - List of the X axis coordinates.
gridY     - A 1xQ array       - List of the Y axis coordinates.
gridZ     - A 1xR array       - List of the Z axis coordinates.
STLformat - string (optional) - STL file format: 'binary' or 'ascii'.
 
 
OUTPUTS
=======
 
faces    - Nx3 array  - A list of the vertices used in each facet of the mesh, identified using the row number in the array vertices.
vertices - Nx3 array  - A list of the x,y,z coordinates of each vertex in the mesh.
 
 
EXAMPLE
=======
 
For an example, run the following script:
>> CONVERT_voxels_to_stl_example
 
 
NOTES
=====
 
- This code does not apply any smoothing.  The stl mesh will be exactly the same geometry as the original voxelised object.
 
 