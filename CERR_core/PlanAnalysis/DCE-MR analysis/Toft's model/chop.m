   function y = chop(x,n)
        if n<=size(x,2)
        y = x(:,1:n);
        else
            y = x;
        end
    end