classdef CustomFilter < ImageFilter

    properties (Hidden, SetAccess = private)
        kernel_ft
    end

    methods
        function obj = CustomFilter(kernel_ft)
            obj.kernel_ft = kernel_ft;
        end

        function filtered_img = apply(obj, img)
            img_ft = fft2(img);
            filtered_img = ifft2(img_ft.*obj.kernel_ft);
            if isreal(img)
                % use real instead of abs for speed
                filtered_img = real(filtered_img);
            end
        end

        function shape = size(obj)
            shape = size(obj.kernel_ft);
        end
    end
end
