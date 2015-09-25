function [mvy,mvx,mvz,i1vx]=multigrid_nogui6(method,img1,img2,ratio,steps,offsets,img2mask,mvy0,mvx0,mvz0)
%
% Usage:	[mvy,mvx,mvz,i1vx]=multigrid_nogui6(method,img1,img2,ratio,steps,offsets,img2mask,mvy0,mvx0,mvz0)
%
% The multi-grid framework, supports images upto 4 coarse levels
%
% Changes:
%
% Version 4
% In coarse level, if the motion vector magnitude is less than 0.4, then
% set it to 0 because we could safely recover it in the finer level
%
% Version 5 : Try to fix the errors near the boundaries in the earlier steps
% - Limit the motion vector amplitude (<1) for each step
% - Limit the motion vector amplitude (<1) for each loop within the step
% - Apply multiple loops for each earlier step so that the motion field is
%   increasing gratually and under control
% - Save delta motion field for each loop and for each step
% - Save images in PNG (after maximizing the figure window)
%
% Version 6: Be able to run with or without GUI
%
% If calling from GUI, all input parameters could be left empty
% If calling from command line, then the first 3 parameters needs to be
% given.
%
% Changes:	Disable all GUIs
%
% Changes in v2:
% - Allow img1 to be larger than img2
% - add parameter zoffset
%
% Changes in v3:
% - To support mask for img2 and to reset all motion fields to 0 outside
% the mask
%
% Changes 10/21/2006
% - If img1 is larger than img2, the larger img1 will be passed into each
% optical flow routine, so that image gradient could be computed more
% accurately in the optical flow routine.
% - Accept initial value for mvz
%
% Changes in v4
% Using a different way to apply initial motion field mvx0,mvy0,mvz0. Will
% deform img1 first by using these initial motion field, then apply regular
% method on the deform the img1. The final motion field will be the resultant
% motion field computed by using the deformed img1 + the initial motion
% field
% 
% Changes in v5
% Fix the motion field / i1vx recalculation bug
%
% Version 6: 
% 1. support full offsets, not only zoffsets
% 2. support arbitrary image dimension 
%

% setpath;

maxmotion = 2.5;
displayflag = 0;

% Check input parameters

if( ~exist('ratio','var') || isempty(ratio) )
	ratio = [1 1 1];
end

if ~exist('offsets','var') || isempty(offsets) 
	offsets = [0 0 0];
elseif length(offsets) == 1
	offsets = [0 0 offsets];
end

if( ~exist('img2mask','var') || isempty(img2mask) )
	img2mask = ones(size(img2),'single');
end


% Options
check_motion_vector_magnitude = 1;
%check_motion_vector_magnitude = 0;

ct0 = cputime;

% If initial motion field is passed in, then deform the image 1 before
% using it
if ( exist('mvz0','var') && ~isempty(mvz0) && exist('mvx0','var') && ~isempty(mvx0) && exist('mvy0','var') && ~isempty(mvy0) ) 
	[mvyL0,mvxL0,mvzL0]=expand_motion_field(mvy0,mvx0,mvz0,size(img1),offsets);
    img1_org = img1;
	disp('Deforming img1 ...');
	img1 = move3dimage(img1,mvyL0,mvxL0,mvzL0,'linear');
	clear mvy0 mvx0 mvz0;
end

[img1_2,img1_4,img1_8,img2_2,img2_4,img2_8,img2mask_2,img2mask_4,img2mask_8]=GPReduceAll(img1,img2,img2mask,steps,displayflag);

% wy
clear img2mask_2 img2mask_4 img2mask_8 img2mask;

disp(sprintf('It took %.2f seconds to downsample the images',cputime-ct0));

calsecs = 0;	% Time on actual computation
ct0=cputime;


% These two vector control the number of loops and iterations
%maxiterratios = [1 3 8 6];
maxiterratios = [1 2 2 3 3];
%loopsinstep = [2 3 3 2];
loopsinstep = [1 2 2 3 3]*2;
%if (size(img1,3) == 1) loopsinstep=loopsinstep*2; end

% Starting the steps
for step = 1:steps
	disp(sprintf('\n\nStarting step %d\n',step));
	real_step = steps-step+1;
	ct1 = cputime;
	
    % setting images
	switch real_step
		case 4
			im1 = img1_8;
			im2 = img2_8;
% 			im2mask = img2mask_8;
		case 3
			im1 = img1_4;
			im2 = img2_4;
% 			im2mask = img2mask_4;
		case 2
			im1 = img1_2;
			im2 = img2_2;
% 			im2mask = img2mask_2;
		case 1
            clear im1 im2 im2mask;
            clear img1_2 img2_2 img1_4 img2_4 img1_8 img2_8;
            pack;
            im1 = img1;
			im2 = img2;
% 			im2mask = img2mask;
            
	end
	
	im1 = single(im1);
	im2 = single(im2);
% 	im2mask = single(im2mask>0);

	% Normalize images
	maxv = max(max(im1(:)),max(im2(:)));
	im1 = im1/maxv;
	im2 = im2/maxv;
	dim1 = mysize(im1);
	dim2 = mysize(im2);

	image_current_offsets = floor(offsets / (2^(real_step-1)));
	
	% Initialze motion fields for this step
	ctc = cputime;
	if( step == 1 )
		disp(sprintf('Initialize motion fields'));
		mvy = zeros(dim2,'single');	% mvx, mvy and mvz are the motion vector for each image pixels
		mvx = zeros(dim2,'single');	% mvx, mvy and mvz are the motion vector for each image pixels
		mvz = zeros(dim2,'single');	% mvx, mvy and mvz are the motion vector for each image pixels
		i1vx = im1;
	else
		disp(sprintf('Step %d - Upscaling the motion field ...', step));
		[mvy,mvx,mvz] = recalculate_mvs(mvy,mvx,mvz,displayflag);%mem use here
		if ~isequal(size(mvy),dim2)
			mvy = mvy(1:dim2(1),1:dim2(2),1:dim2(3));
			mvx = mvx(1:dim2(1),1:dim2(2),1:dim2(3));
			mvz = mvz(1:dim2(1),1:dim2(2),1:dim2(3));
		end
		
		disp('Upscaling motion field is finished.');
    end
    
    %wy
    if (step==steps)&&(dim2(1)*dim2(2)>128^2)
        isLastStep=1;
        clear img1 img2;%????
        pack; 
    else
        isLastStep=0;
    end
	
	if step > 1
		disp('Computing moved image by interpolating ...');
		if ~isequal(dim1,dim2)
			[mvyL_step,mvxL_step,mvzL_step]=expand_motion_field(mvy,mvx,mvz,size(im1),image_current_offsets);
			i1vx = move3dimage(im1,mvyL_step,mvxL_step,mvzL_step,'linear');
		else
			i1vx = move3dimage(im1,mvy,mvx,mvz,'linear',image_current_offsets);
		end
		disp('Computing moved image is finished');		
	end
	calsecs = calsecs + (cputime-ctc);

	disp(sprintf('Step %d - Saving initial variables ...', step));

	% Initial motion field for the current step
	mvx_this_step = zeros(size(mvx), 'single'); %wy
	mvy_this_step = mvx_this_step;
	mvz_this_step = mvx_this_step;

	% Starting loops within a step
	for loop = 1:loopsinstep(real_step)
		ct2 = cputime;
		disp(sprintf('Computing motion: step %d - loop %d', step, loop));
		
		ctc = cputime;
		switch method
			case 1	% Horn original global smoothness optical flow method
				[mvy1,mvx1,mvz1] = optical_flow_global_methods(1,[],i1vx,im2,ratio,maxiterratios(real_step),[],[],[],image_current_offsets);
			case 2	% Lucas and Kanade's local LMS method
				%[mvy1,mvx1,mvz1] = optical_flow_lkt(i1vx,im2);
				%[mvy1,mvx1,mvz1] = optical_flow_lkt_2(i1vx,im2);
				%[mvy1,mvx1,mvz1] = optical_flow_lkt_2_5(i1vx,im2,ratio,1000);
				%[mvy1,mvx1,mvz1] = optical_flow_lkt_4(i1vx,im2,ratio,1000);
				%[mvy1,mvx1,mvz1] = optical_flow_lkt_3(i1vx,im2,ratio,1000);
				%[mvy1,mvx1,mvz1] = optical_flow_lkt_5(i1vx,im2,ratio,1000);
				[mvy1,mvx1,mvz1] = optical_flow_lkt_6(i1vx,im2,ratio,1000,0,image_current_offsets,displayflag);
			case 3	% Modified Lucas-Kanada method with outlier rejection
			case 4	% Weighted smoothness optical flow method
			case 5	% Oriented smoothness optical flow method
			case 6	% Combine local LMS and global smoothness method
				[mvy1,mvx1,mvz1] = optical_flow_global_methods(3,[],i1vx,im2,ratio,maxiterratios(real_step),[],[],[],image_current_offsets);
			case 7	% Combine local LMS and weighted smoothness method
				[mvy1,mvx1,mvz1] = optical_flow_global_methods(4,[],i1vx,im2,ratio,maxiterratios(real_step),[],[],[],image_current_offsets);
			case 8	% Issam's Non-linear smoothness method
				[mvy1,mvx1,mvz1] = optical_flow_global_methods(2,[],i1vx,im2,ratio,maxiterratios(real_step),[],[],[],image_current_offsets);
			case 9	% Levelset motion method
				lmfactors = [1 1 1 1 1];
				lmmaxiters = [20 20 10 10 10];
				lmtors = [1e-3 1e-3 1e-3 1e-3 1e-3];
				%[mvy1,mvx1,mvz1] = levelset_motion_free_deform_wo_gui(i1vx,im2,lmfactors(step),lmmaxiters(step),lmtors(step),[],[3 3 3],2,1);
				%[mvy1,mvx1,mvz1] = levelset_motion_0(i1vx,im2,lmfactors(step),lmmaxiters(step),lmtors(step));
				%[mvy1,mvx1,mvz1] = levelset_motion_local_affine_wo_gui(i1vx,im2,lmfactors(real_step),lmmaxiters(real_step),lmtors(real_step),[5 5 5],[],[],1);
				[mvy1,mvx1,mvz1] = levelset_motion_wo_gui(i1vx,im2,ratio,step,[],im1,mvy + mvy_this_step,mvx + mvx_this_step,mvz + mvz_this_step);
			case 10 % Affine approximation of motion field
				[mvy1,mvx1,mvz1] = optical_flow_affine(i1vx,im2);
			case 11 % The original LKT LMS method
				[mvy1,mvx1,mvz1] = optical_flow_lkt_0(i1vx,im2,ratio);
			case 12 % The original HS + divergence contraint
				[mvy1,mvx1,mvz1] = optical_flow_global_methods('001',[],i1vx,im2,ratio,maxiterratios(real_step),mvy + mvy_this_step,mvx + mvx_this_step,mvz + mvz_this_step,image_current_offsets);
			case 13 % The original HS + intensity correction
				[mvy1,mvx1,mvz1] = optical_flow_global_methods('0001',[],i1vx,im2,ratio,maxiterratios(real_step),[],[],[],image_current_offsets, isLastStep);
			case 14 % The original HS + intensity correction + divergence contraint
				[mvy1,mvx1,mvz1] = optical_flow_global_methods('0011',[],i1vx,im2,ratio,maxiterratios(real_step),mvy + mvy_this_step,mvx + mvx_this_step,mvz + mvz_this_step,image_current_offsets);
			case 15 % Inverse consistency Horn-Schunck
				[mvy1,mvx1,mvz1] = optical_flow_inverse_consistency_methods(1,[],i1vx,im2,ratio,maxiterratios(real_step));
			case 16 % Inverse consistency Horn-Schunck with image intensity correction
				[mvy1,mvx1,mvz1] = optical_flow_inverse_consistency_methods(2,[],i1vx,im2,ratio,maxiterratios(real_step));				
			case 17 % Demon method
				[mvy1,mvx1,mvz1] = demon_global_methods(1,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 18	% modified demon method
				[mvy1,mvx1,mvz1] = demon_global_methods(2,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 19 % SSD Minimization
				[mvy1,mvx1,mvz1] = demon_global_methods(3,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 20 % Iterative Optical Flow
				[mvy1,mvx1,mvz1] = demon_global_methods(4,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 21 % Iterative Levelset Motion
				[mvy1,mvx1,mvz1] = demon_global_methods(5,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 22 % Fast demon method
				[mvy1,mvx1,mvz1] = fast_demon_global_methods(1,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 23 % Fast iterative optical flow
				[mvy1,mvx1,mvz1] = fast_demon_global_methods(2,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
			case 24 % Fast demon method with elastic regularization constraint
				[mvy1,mvx1,mvz1] = fast_demon_global_methods(3,[],i1vx,im2,ratio,[],[],[],image_current_offsets);
		end
		disp(sprintf('Motion computation step %d,%d is finished',step,loop));
		
		if check_motion_vector_magnitude == 1
			% Limit the magnitude of motion vector computed by the current
			% loop
			if step < steps
				[mvx1,mvy1,mvz1]=CheckMagnitude1(mvx1,mvy1,mvz1,maxmotion/loopsinstep(real_step));
			end
			
% 			if step < steps
% 				[mvx1,mvy1,mvz1]=CheckMagnitude2(mvx1,mvy1,mvz1);
% 			end
		end
		
% 		mvy1 = mvy1.*im2mask;
% 		mvx1 = mvx1.*im2mask;
% 		mvz1 = mvz1.*im2mask;

		if loop == 1
			mvy_this_step = mvy1;
			mvx_this_step = mvx1;
			mvz_this_step = mvz1;
		else
			disp('Computing result motion field for this loop by interpolating ...');
			if isequal(dim1,dim2)
				mvy_this_step = move3dimage(mvy_this_step,mvy1,mvx1,mvz1,'linear') + mvy1;
				mvx_this_step = move3dimage(mvx_this_step,mvy1,mvx1,mvz1,'linear') + mvx1;
				mvz_this_step = move3dimage(mvz_this_step,mvy1,mvx1,mvz1,'linear') + mvz1;
			else
				mvy_this_step = move3dimage(mvyL,mvy1,mvx1,mvz1,'linear',image_current_offsets) + mvy1;
				mvx_this_step = move3dimage(mvxL,mvy1,mvx1,mvz1,'linear',image_current_offsets) + mvx1;
				mvz_this_step = move3dimage(mvzL,mvy1,mvx1,mvz1,'linear',image_current_offsets) + mvz1;
			end
		end
		
		disp('Computing moved image by interpolating ...');
		if ~isequal(dim1,dim2)
			[mvyL,mvxL,mvzL]=expand_motion_field(mvy_this_step,mvx_this_step,mvz_this_step,size(im1),image_current_offsets);
			if step == 1
				i1vx = move3dimage(im1,mvyL,mvxL,mvzL,'linear');
			else
				i1vx = move3dimage(im1,mvyL+mvyL_step,mvxL+mvxL_step,mvzL+mvzL_step,'linear');
			end
		else
			i1vx = move3dimage(im1,mvy+mvy_this_step,mvx+mvx_this_step,mvz+mvz_this_step,'linear',image_current_offsets);
		end

		disp('Computing moved image is finished');
		calsecs = calsecs + (cputime-ctc);

		clear mvx1 mvy1 mvz1;
		
		% Compute the image statistics
		if ~isequal(dim1,dim2)
			i1vx2 = i1vx((1:dim2(1))+image_current_offsets(1),(1:dim2(2))+image_current_offsets(2),(1:dim2(3))+image_current_offsets(3));
		else
			i1vx2 = i1vx;
		end

		[MI,NMI,MI3,CC,CC2,COV,MSE] = images_info(i1vx2,im2,'MI','NMI','MI3','CC','CC2','cOV','MSE');
		disp(sprintf('step %d,%d, MI = %d',step, loop, MI));
		disp(sprintf('step %d,%d, NMI = %d',step, loop, NMI));
		disp(sprintf('step %d,%d, MI3 = %d',step, loop, MI3));
		disp(sprintf('step %d,%d, CC = %d',step, loop, CC));
		disp(sprintf('step %d,%d, CC2 = %d',step, loop, CC2));
		disp(sprintf('step %d,%d, COV = %d',step, loop, COV));
		disp(sprintf('step %d,%d, MSE = %d',step, loop, MSE));
		clear i1vx2;

		disp(sprintf('Step %d,%d - Finished', step,loop));

		disp(sprintf('This loop used %.2f seconds to finish.\n',cputime-ct2));
		if method == 9	|| method > 16 % levelset motion or demon methods
			break;	% Don't loop here
		end
    end
    %end loops
	
	if check_motion_vector_magnitude == 1
		if step < steps
			[mvx_this_step,mvy_this_step,mvz_this_step]=CheckMagnitude1(mvx_this_step,mvy_this_step,mvz_this_step,maxmotion);
		end
		
% 		if step < steps-1
% 			[mvx_this_step,mvy_this_step,mvz_this_step]=CheckMagnitude2(mvx_this_step,mvy_this_step,mvz_this_step);
% 		end
	end
	
	if step == 1
		mvy = mvy_this_step;
		mvx = mvx_this_step;
		mvz = mvz_this_step;
	else
		disp('Computing result motion field for this step by interpolating ...');
		if ~isequal(dim1,dim2)
			mvy = move3dimage(mvyL_step,mvy_this_step,mvx_this_step,mvz_this_step,'linear',image_current_offsets) + mvy_this_step;
			mvx = move3dimage(mvxL_step,mvy_this_step,mvx_this_step,mvz_this_step,'linear',image_current_offsets) + mvx_this_step;
			mvz = move3dimage(mvzL_step,mvy_this_step,mvx_this_step,mvz_this_step,'linear',image_current_offsets) + mvz_this_step;
		else
			mvy = move3dimage(mvy,mvy_this_step,mvx_this_step,mvz_this_step,'linear') + mvy_this_step;
			mvx = move3dimage(mvx,mvy_this_step,mvx_this_step,mvz_this_step,'linear') + mvx_this_step;
			mvz = move3dimage(mvz,mvy_this_step,mvx_this_step,mvz_this_step,'linear') + mvz_this_step;
		end
	end
	
	
%     mvx = mvx.*im2mask;
%     mvy = mvy.*im2mask;
%     myz = mvz.*im2mask;
	
    if (step==steps)
        clear global mvx_this_step mvy_this_step mvz_this_step;
    end
    
	disp(sprintf('Step %d - Finished', step));
	disp(sprintf('\nStep %d is finished, used %.2f seconds.\n\n',step,cputime-ct1));
end

% if ~isequal(dim1,dim2)
% 	i1vx = i1vx((1:dim2(1))+image_current_offsets(1),(1:dim2(2))+image_current_offsets(2),(1:dim2(3))+image_current_offsets(3));
% end

if ( exist('mvyL0','var') )
	disp('Computing final motion field by interpolating ...');
	mvy1 = move3dimage(mvyL0,mvy,mvx,mvz,'linear',image_current_offsets);
	mvx1 = move3dimage(mvxL0,mvy,mvx,mvz,'linear',image_current_offsets);
	mvz1 = move3dimage(mvzL0,mvy,mvx,mvz,'linear',image_current_offsets);
	mvy = mvy + mvy1;
    mvx = mvx + mvx1;
    mvz = mvz + mvz1;
	clear mvy1 mvx1 mvz1;
end


disp('All finished');
disp(sprintf('It took %.2f seconds to finish the entire multigrid registration',cputime-ct0));
disp(sprintf('It took %.2f seconds with actually computation',calsecs));
return;



function [mvx,mvy,mvz]=CheckMagnitude1(mvx,mvy,mvz,thres)
% This step will restrict the magnitude of the motion field
% in the earlier steps to be less than 1. Such a
% restriction will help to solve the outlier and errors
% near the boundaries
mv = sqrt(mvx.^2+mvy.^2+mvz.^2);
mv2 = min(mv,thres);
factor = mv2 ./ (mv + (mv == 0 ));
mvx = mvx .* factor;
mvy = mvy .* factor;
mvz = mvz .* factor;
% mvx = lowpass3d(mvx,1);
% mvy = lowpass3d(mvy,1);
% mvz = lowpass3d(mvz,1);
clear mv mv2 factor;
return;

function [mvx,mvy,mvz]=CheckMagnitude2(mvx,mvy,mvz)
% This step will reduce the magnitude of the motion field
% in the earlier steps if the motion could be recovered in
% later multigrid steps
mv = sqrt(mvx.^2+mvy.^2+mvz.^2);
mv2 = (mv - 0.4) .* (mv > 0.4);
factor = mv2 ./ (mv + (mv == 0 ));
mvx = mvx .* factor;
mvy = mvy .* factor;
mvz = mvz .* factor;
% mvx = lowpass3d(mvx,1);
% mvy = lowpass3d(mvy,1);
% mvz = lowpass3d(mvz,1);
clear mv mv2 factor;
return;

