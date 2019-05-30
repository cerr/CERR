function [enhance, endval] = checkEnhance(fitcurve,newframes,CAcut)
% This function examines the contrast agent time course in voxels with low
% r-squared to determine whether the low r-squared was due to lack of
% enhancement or due to data with too much motion and noise.
%
% The function returns a value of 0 if the voxel was non-enhancing and 1
% if it was just too noisy to give a good fit
% -----------------------------------------------------------------------

% There are two tests
% 1.  Check the end value of the fitted curve. If it has a value lt contrast agent
% cutoff for Gd concentration, the voxels may be non-enhancing.
% try keeping it simple for now. 

endval = (fitcurve(newframes)+ fitcurve(newframes-1))/2;
enhance = endval >= CAcut;

end





  


    



