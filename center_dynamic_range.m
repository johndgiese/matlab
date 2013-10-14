function centered_array = center_dynamic_range(data, varargin)
%CENTER_DYNAMIC_RANGE Fix original zero at 0.5 and then fill to [0, 1].
%
% If only one argument is provided, then the array is centered on the min and
% max.  Otherwise, the optional second argument specifies the min and maximum
% as a percentile.  For example to set the min value at the lowest 1 percentile
% and the maximum value at the 99 percentile:
%
%     img_c = center_dynamic_range(img, 1);
%

    if nargin == 1
        data_min = min(data(:));
        data_max = max(data(:));
    elseif nargin == 2
        cutoff = varargin{1};
        data_min = prctile(data(:), cutoff);
        data_max = prctile(data(:), 100 - cutoff);
    else
        error('Need to provide a data array!');
    end

    scale = 2.0*max(abs(data_max), abs(data_min));    
    centered_array = data/scale + 0.5;    
end
