function filled_img = fill_dynamic_range(img)
%FILL_DYNAMIC_RANGE Stretch image values to fill [0, 1].
    img_min = min(img(:));
    img_max = max(img(:));
    img_range = img_max - img_min;
    filled_img = (img - img_min)/img_range;
end
