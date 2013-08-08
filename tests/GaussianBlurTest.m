% Test blurring

img = zeros(40);
img(1:20, 1:20) = 0.5;
img(21:40, 21:40) = 0.5;
img = repmat(img, 10, 10);
img = imnoise(img, 'salt & pepper', 0.4); 

%img = imread('C:\Users\Public\Pictures\Sample Pictures\Tulips.jpg');
img = mean(img, 3);

BLUR_SIGMA = 10;
edge_types = {'zeros', 'smart', 'replicate', 'reflect'};

subplot(2, 3, 1);
imshow(img);
title('original');

for i = 1:length(edge_types)
    type = edge_types{i};
    blur = GaussianBlur(BLUR_SIGMA, size(img), type);
    blurred = blur.apply(img);
    subplot(2, 3, i+1);
    imshow(blurred);   
    title(type);
end
linkaxes();