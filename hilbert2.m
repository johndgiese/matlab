function analytic_img = hilbert2(img)
    %HILBERT2 Perform a 2D Hilbert transform
    %
    % Assumes the signum is along the y-axis.

    % create the mask
    s = size(img); nx = s(2);
    mask = ones(size(img));
    mask(:, 1) = 0;
    if ~mod(nx, 2) % iseven
        mask(:, (nx/2 + 2):end) = -1;
        mask(:, (nx/2 + 1)) = 0;
    else % isodd
       mask(:, ((nx - 1)/2 + 2):end) = -1;
    end

    img_ft = fft2(img);
    img_ft_masked = img_ft.*mask;
    analytic_img = ifft2(1j*real(img_ft_masked) + imag(img_ft_masked));
end