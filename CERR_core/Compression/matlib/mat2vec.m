% function v=mat2vec(matrix,rowcol)
%
% Converts the matrix in a single row or column vector
% having dimension row*col. Rowcol can be either 'row'
% or 'col', with obvious meaning.

function v=mat2vec(matrix,rowcol)
    v=[];
    if strcmp(rowcol,'row')
        for i=1:size(matrix,1)
            v=[v matrix(i,:)];
        end
    elseif strcmp(rowcol,'col')
        for i=1:size(matrix,2)
            v=[v ; matrix(:,i)];
        end
    else
        disp(sprintf('Value %s for rowcol not admitted.',rowcol));
    end
return
            
        
                