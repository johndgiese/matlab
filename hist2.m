function out = hist2(x,y,xbin,ybin)    
% HIST2 two dimensional histogram
% X and Y define 2d points on a grid (they must be the same length).
% XBIN and YBIN define the end points of a set of bins that are used to
% generate a 2d histogram.  They do not need to be the same size.
% e.g. if xbin = [0 1 2 3] and ybin = [0 1], out(1,1) will contain the
% number of points that are x < 1 and y < 1, out(2,2) will contain the
% number of points that are 1 <= x <= 2, 1 <= y.

    nx = length(xbin);
    ny = length(ybin);
    out = zeros(ny,nx);
    for k = 1:length(x)
        indx = find(x(k) < xbin,1,'first');
        indy = find(y(k) < ybin,1,'first');
        if isempty(indx)
            indx = nx;
        end
        if isempty(indy)
            indy = ny;
        end
        
        out(indy,indx) = out(indy,indx) + 1;
    end
end