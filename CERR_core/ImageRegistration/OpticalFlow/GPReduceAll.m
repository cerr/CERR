function [img1_2,img1_4,img1_8,img2_2,img2_4,img2_8,img2mask_2,img2mask_4,img2mask_8]=GPReduceAll(img1,img2,img2mask,levels,displayflag)
%
% [img1_2,img1_4,img1_8,img2_2,img2_4,img2_8]=GPReduceAll(img1,img2,levels)
%

global Gimg1 Gimg2 Gimg2mask Gimg1_2 Gimg1_4 Gimg1_8 Gimg2_2 Gimg2_4 Gimg2_8 Gimg2mask_2 Gimg2mask_4 Gimg2mask_8;

if ~isequal(img1,Gimg1) || isempty(Gimg1_2)
	disp('Down sampling image #1 for step 2...');
% 	if( size(img1,3) > size(img2,3) & size(img2,3)==16 )
% 		Gimg1_2 = GPReduce2(img1,16,displayflag);
% 	else
		Gimg1_2 = GPReduce(img1,displayflag);
% 	end
end

if ~isequal(img2,Gimg2) || isempty(Gimg2_2)
	disp('Down sampling image #2 for step 2...');
	Gimg2_2 = GPReduce(img2,displayflag);
end

if ~isequal(img2mask,Gimg2mask) || isempty(Gimg2mask_2)
	if isempty(img2mask)
		Gimg2mask_2 = [];
	else
		disp('Down sampling image #2 mask for step 2...');
		Gimg2mask_2 = GPReduce(img2mask,displayflag);
	end
end

if levels > 2
	if ~isequal(img1,Gimg1) || isempty(Gimg1_4)
		disp('Down sampling image #1 for step 3...');
% 		if( size(img1,3) > size(img2,3) & size(img2,3)==16 )
% 			Gimg1_4 = GPReduce2(Gimg1_2,8,displayflag);
% 		else
			Gimg1_4 = GPReduce(Gimg1_2,displayflag);
% 		end
	end

	if ~isequal(img2,Gimg2) || isempty(Gimg2_4)
		disp('Down sampling image #2 for step 3...');
		Gimg2_4 = GPReduce(Gimg2_2,displayflag);
	end

	if ~isequal(img2mask,Gimg2mask) || isempty(Gimg2mask_4)
		if isempty(img2mask)
			Gimg2mask_4 = [];
		else
			disp('Down sampling image #2 mask for step 3...');
			Gimg2mask_4 = GPReduce(Gimg2mask_2,displayflag);
		end
	end
end

if levels > 3
	if ~isequal(img1,Gimg1) || isempty(Gimg1_8)
		disp('Down sampling image #1 for step 4...');
% 		if( size(img1,3) > size(img2,3) & size(img2,3)==16 )
% 			Gimg1_8 = GPReduce2(Gimg1_4,4,displayflag);
% 		else
			Gimg1_8 = GPReduce(Gimg1_4,displayflag);
% 		end
	end

	if ~isequal(img2,Gimg2) || isempty(Gimg2_8)
		disp('Down sampling image #2 for step 4...');
		Gimg2_8 = GPReduce(Gimg2_4,displayflag);
	end

	if ~isequal(img2mask,Gimg2mask) || isempty(Gimg2mask_8)
		if isempty(img2mask)
			Gimg2mask_8 = [];
		else
			disp('Down sampling image #2 mask for step 4...');
			Gimg2mask_8 = GPReduce(Gimg2mask_4,displayflag);
		end
	end
end

Gimg1 = img1;
Gimg2 = img2;
Gimg2mask = img2mask;

img1_2 = Gimg1_2;
img1_4 = Gimg1_4;
img1_8 = Gimg1_8;
img2_2 = Gimg2_2;
img2_4 = Gimg2_4;
img2_8 = Gimg2_8;
img2mask_2 = Gimg2mask_2;
img2mask_4 = Gimg2mask_4;
img2mask_8 = Gimg2mask_8;

clear global Gimg1 Gimg2 Gimg2mask Gimg1_2 Gimg1_4 Gimg1_8 Gimg2_2 Gimg2_4 Gimg2_8 Gimg2mask_2 Gimg2mask_4 Gimg2mask_8;



