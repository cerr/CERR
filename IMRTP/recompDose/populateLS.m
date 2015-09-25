function populateLS(planC_File, Leakage_flag)
%function populateLS()
%
%This function calculates Leaf sequences and populates IM.LeafSeq object
%It should be invoked after optimizing beamletWeights.
%Assumes Beamlet Weights are stored under planC{indexS.IM}(end).IMDosimetry.solution(end).beamletWeights
%
%planC_File: is the name of CERR plan.
%
%APA, 2/25/08
%
% Copyright 2010, Joseph O. Deasy, on behalf of the CERR development team.
% 
% This file is part of The Computational Environment for Radiotherapy Research (CERR).
% 
% CERR development has been led by:  Aditya Apte, Divya Khullar, James Alaly, and Joseph O. Deasy.
% 
% CERR has been financially supported by the US National Institutes of Health under multiple grants.
% 
% CERR is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of CERR is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% CERR is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with CERR.  If not, see <http://www.gnu.org/licenses/>.

%Load planC
load(planC_File)
indexS = planC{end};

%Get beamlet weights
beamWeights = planC{indexS.IM}(end).IMDosimetry.solution(end).beamletWeights;

%Generate Leaf Sequencer LS structure array (each index corresponds to beam)
[M, pos, xPts, yPts, Moriginal] = getMatricesToSegmentFromCERR(beamWeights);
[LeafSeq,MU] = getLeafSeqStruct(M,pos,Leakage_flag,Moriginal);
planC{indexS.IM}(end).IMDosimetry.LeafSeq.LS = LeafSeq;
planC{indexS.IM}(end).IMDosimetry.LeafSeq.MU = MU;

%Save updated planC
save(planC_File,'planC')
