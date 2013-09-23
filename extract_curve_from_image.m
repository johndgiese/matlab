function [x, y] = extract_curve_from_image(img, y_dim, x_dim)
%EXTRACT_CURVE_FROM_IMAGE Extract a curve from an image
%
% Lets say you need to do some analysis on a curve in a data sheet, what do
% you do?  First you call and ask for the data, but they don't want to give
% it to you.  So you have to extract a curve from an image.  Here is how
% you do it:
%
% Take a screen shot of the graph
% Crop it to a rectangle
% Use photoshop to remove any legends etc. When you are done the curve
% should be the darkest line left in any column of the image.
% Run this function where y_dim = [y_min, y_max] on the image.
% You are given back a curve that has a value for each column in the image.

    img = mean(double(img), 3);

    [num_rows, num_cols] = size(img);
    curve = zeros(num_cols, 1);
    for col = 1:num_cols
        [~, I] = min(img(:, col));
        curve(col) = num_rows - I;
    end
    y = smooth(curve, 5);
    
    y_slope = (max(y_dim)-min(y_dim))/(num_rows - 1);
    
    y = min(y_dim) + y_slope*y;
    x = linspace(min(x_dim), max(x_dim), num_cols);    

end