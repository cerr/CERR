function newimg = GPReduce2(img,blocksize,displayflag)

if ~exist('displayflag')
	displayflag = 1;
end

dim = size(img);

newimg = [];
for b = 1:blocksize:dim(3)
    if b<dim(3)
        img2 = img(:,:,b:b+blocksize-1);
    else
        img2 = img(:,:,b);
    end
	newimg2 = GPReduce(img2,displayflag);
	newimg = cat(3,newimg,newimg2);
end
