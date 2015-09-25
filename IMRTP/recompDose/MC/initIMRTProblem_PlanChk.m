function IM = initIMRTProblem
%"initIMRTProblem"
%   Initialize all fields used for IMRTP treatment planning.
%
%   Currently problem.structures is not currently used, but will be used when non-uniform voxel selection is implemented,
%   to keep up with the list of voxels to which dose has been computed.  For this test case, we are just using
%   the 0.2 cm voxels inherent in the NOMOS system.
%
%JOD
%JRA 10/21/04 - Now initialize select fields to defaults.
%
%Usage:
%   function IM = initIMRTProblem



%-----------Initialize problem IMRT optimization problem statement---------------------%

IM = struct('beams','','goals','','beamlets','','solution','','params','');

IM.beams  = struct(...
                 'beamNum','', ...            %Is the beam index to dosimetry data.  Usually equal to the index
                 ...                          %within IM.beams.
                 'beamModality','', ...       %e.g., photons
                 'beamEnergy','',   ...       %e.g., 18 MV
                 'beamDescription','', ...    %User defined, e.g., LPO, AP boost, etc.
                 'beamType', '', ...          %IMRT, static, arc, or IMAT (IMAT not currently used)
                 'collimatorAngle', '',...    %Currently assumed to be zero
                 'couchAngle', '',  ...       %Not currently used
                 'arcAngle', '',  ...         %Could be used for arc computation
                 'isocenter',[], ...       %RTOG coords of isocenter for this beam
                 'zRel', '', ...           %RTOG coords; with respect to isocenter
                 'xRel', '', ...           %RTOG coords; with respect to isocenter
                 'yRel', '', ...           %RTOG coords; with respect to isocenter
                 'isodistance', '', ...    %All distances always in cm
                 'gantryAngle', '', ...    %Grantry angle (degrees), IEC coords (i.e. 3 o'clock facing linac is pi/2)
                 'beamletDelta_x','', ...  %IEC gantry coords (z points at isocenter, x is in transverse plan, ...
                 ...                       %y points towards linac/head of patient (with 'head In'))
                 'beamletDelta_y','', ...  %IEC gantry coords
                 'CTUsed', '', ...         %The index of the CT scan within the CERR archive which was used for the
                 ...                       %dose computation.
                 'RTOGPBVectorsM',[], ...  %Vectors of the central PB rays.
                 'RTOGPBVectorsM_MC',[], ...  %Vectors of the central PB rays.
                 'PBMaskM',[], ...         %2D array mask of PBs which are on
                 'xPBPosV',[], ...         %Xb-Yb midpoints of PBs which are on, in IEC 1217 coord system.
                 'yPBPosV',[], ...
                 'rowPBV',[], ...          %Gives the row and column of the PBs which are on
                 ...                       %matching the Xb-Yb midpoints (xPBPosV, yPBPosV).
                 'colPBV',[], ...
                 'sigma_100',[],...        %Gaussian blur of PBs at 100 cm. (not currently used).
                 'dateOfCreation',date ... %Date this structure was created
                  );
                  
IM.beams.isocenter = struct('x', [], 'y', [], 'z', []);                  

IM.goals =  struct(...                     %Contains information needed to formulate the IMRTP problem.
                 'isTarget', '',...        %Is this a target structure? 'yes'/'no'.
                 'PBMargin', [], ...       %If it is a target, this gives a margin; PBS are computed whose central rays
                  ...                      %strike any target plus this margin.
                 'structNum','',...        %index of structure within CERR dataset
                 'structName','',...       %Also supply name for human reviewability
                 'goalType', '', ...
                 'description', '', ...
                 'goalName', '', ...       %e.g., 'minDose'
                 'threshold', '', ...      %metric value below which the goal should not be active
                 'direction', '', ...      %'pushDown' vs. 'pushUp'.  Which direction should be goal be driven?
                 'goalPriority', '', ...   %Among all the goals, what is the priority?
                 'dateOfCreation',date ...  %Date this structure was created
                 );

IM.solution = struct( ...
                   'selectedBeams',[],...  %vector of beamNums of beams turned on.
                   'beamletWeights',{},... %weights of beamlets.  Each cell contains a weight vector for that beam.
                   'doseScale',1, ...      %scale factor (in addition to beamletWeights) which multiplies the overall dose to get Gy.
                   'doseArray',[],...      %resulting dose array, which can be placed back into CERR using dose2CERR.
                   'dateOfCreation','' ... %Date solution was obtained.
                 );


IM.beamlets = struct(...                      %This is a *2D* structure array with index:  {structNum, beamletNum}.
                    'structureName', '',...    %Structure name
                    'format',[], ...          %Influence storage format e.g., pre-scaled uint8.
                    'influence',[], ...       %Sparse influence/dose element storage, within the structure points: only non-zeros are stored
                    'beamNum',  [], ...       %Beam indentifier.
                    'fullLength',[], ...      %Number of dose elements in non-sparse structure; used to put dose back in.
                    'indexV',[], ...          %Index of nonzero influence/dose values into influence/dose vector
                    'maxInfluenceVal',[], ...  %The maximum influence matrix value for this PB.  Needed to scale dose back up after conversion from uint8 (or whatever) format.
                    'lowDosePoints', [], ...   %Compressed boolean vector indicating points that are scaled from 0...1/256 * maxDose.                    
                    'sampleRate', 1 ...
                    );
                
%Construct each part of the params.
                
IM.params = struct(...
                    'algorithm', 'QIB', ....    %'QIB' or 'MC', default is QIB
                    'writeScale',[], ...        %When writing the influence matrix to disk, use this scale factor.
                    'debug','', ...             %'y' to turn on extra data gathering.       
                    'ScatterMethod' ,'', ...    % Scatter reduce method - 'random' - randomly chosed points within Step, 'threshold', 'probabilistic'
                    'xyDownsampleIndex', [], ...%Sampling rate unformized CT scan in transverse dimension.  Must be a power of two.
                    'numCTSamplePts',[], ...    %Number of ray-trace points for radiological path length calculation.
                    'cutoffDistance',[], ...    %Never compute dose further than this distance from the PB ray.                           
                    'VMC', [], ...               %See below
                    'Scatter', [], ...          %See below             
                    'DoseTerm','' ...           % bterm - scatter part; nogauss - main part; nogauss+scatter - main part with scatter;         
                    );
                    
IM.params.VMC = struct(...
                    'NumParticles', [], ...          %Number of particles
                    'NumBatches', [], ...            %Number of batches
                    'scoreDoseToWater', 'yes', ...   
                    'includeError', 'no', ...        %Dumpdose in VMC++.
                    'monoEnergy', [], ...
                    'spectrum', 'fileName', ...
                    'repeatHistory', [], ...
                    'splitPhotons', [], ...
                    'photonSplitFactor', [], ...
                    'base', [], ...                
                    'dimension', [], ...
                    'skip', [] ...                    
                    );                    

IM.params.Scatter = struct(...
                    'Threshold' , [.01], ...      % threshold for scatter: 1% of max PB dose by default.
                    'RandomStep', [20] ...       % random frequency algorithm: 1 out of every 20 points by default.
                    );

%-----------fini---------------------%