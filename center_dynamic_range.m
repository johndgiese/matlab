function centered_array = center_dynamic_range(array)
%CENTER_DYNAMIC_RANGE Fix original zero at 0.5 and then fill to [0, 1].

    array_min = min(array(:));
    array_max = max(array(:));
    scale = 2.0*max(abs(array_max), abs(array_min));    
    centered_array = array/scale + 0.5;    
end
