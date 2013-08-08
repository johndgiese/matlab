function centered_img = center_dynamic_range(img)
%CENTER_DYNAMIC_RANGE Fix original zero at 0.5 and then fill to [0, 1].

    img_min = min(img(:));
    img_max = max(img(:));
    scale = 2.0*max(abs(img_max), abs(img_min));    
    centered_img = img/scale + 0.5;    
end
