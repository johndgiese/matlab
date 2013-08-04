function img2 = cutborder(img, pixels)
    img2 = img(pixels:end-pixels, pixels:end-pixels);
end