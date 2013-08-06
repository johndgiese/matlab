function cropped_img = cutborder(img, pixels)
    %CUTBORDER Cut the outer pixels from an image.
    
    cropped_img = img(pixels:end-pixels, pixels:end-pixels);
end
