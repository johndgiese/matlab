function y = jinc(x)
%JINC This calculates the jinc function

y = ones(size(x));
y(x ~= 0) = 2*besselj(1,x(x~=0))./x(x~=0);

end

