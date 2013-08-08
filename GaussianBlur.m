classdef GaussianBlur
    % Gaussian Blur Class for efficiently blurring images.
    %
    % Filtering is done in the fourier domain.  The image and kernel are
    % zero-padded to avoid edge effects associated with circular convolution.
    %
    % A kernel is calculated upon instantiating the blur object,
    % thus subsequent filtering operations are fast because the filter doesn't
    % need to be recalculated.
    %
    % Example:
    %     img = imread('lena512.bmp');
    %     sigma = 8;
    %     blur = GaussianBlur(sigma, size(img));
    %     img_blurred = blur.filter(img);

    properties (Hidden, SetAccess = private)
        kernel_ft
        img_size
        padded_size
        calibration
        edges
    end
    
    methods
        function obj = GaussianBlur(sigma, img_size, edges)
            %GAUSSIANBLUR Create Gaussian Blur filter object.

            if ~exist('edges', 'var')
                edges = 'zero';
            end

            obj.img_size = img_size;
            obj.edges = edges;
%             obj.padded_size = 2.^nextpow2(2*img_size - 1);
            obj.padded_size = 2*img_size - 1;

            kernel = fftshift(fspecial('gaussian', obj.padded_size, sigma));            
            obj.kernel_ft = fft2(kernel);

            switch obj.edges
                case 'smart'
                    integration_img = ones(obj.img_size);
                    integration_img_ft = fft2(integration_img, obj.padded_size(1), obj.padded_size(2));
                    energy_in_img = obj.fft_conv2(integration_img_ft, obj.kernel_ft);
                    filter_energy = sum(kernel(:));
                    obj.calibration = filter_energy./energy_in_img;
            end

        end

        function filtered_img = apply(obj, img)
            %APPLY Apply a gaussian blur to an image.

            % preprocess image
            switch obj.edges                
                case 'replicate'
                    img = repmat(img, 2, 2);
                case 'reflect'
                    bottom = flipud(img);
                    right = fliplr(img);
                    bottom_right = fliplr(bottom);
                    img = [img, right; bottom, bottom_right];
            end

            img_ft = fft2(img, obj.padded_size(1), obj.padded_size(2));
            filtered_img = obj.fft_conv2(img_ft, obj.kernel_ft);

            % postprocess image
            switch obj.edges
                case 'smart'
                    filtered_img = filtered_img.*obj.calibration;                    
            end
        end
                
    end
    
    methods (Hidden)
        function filtered_img = fft_conv2(obj, img_ft, kernel_ft)
            filtered_img_padded = ifft2(img_ft.*kernel_ft);
            filtered_img = filtered_img_padded(1:obj.img_size(1), 1:obj.img_size(2));
        end
    end


end
