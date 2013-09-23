function spectra = powerspectra(img)
%POWERSPECTRA Take the power spectra of an image.

spectra = fftshift(abs(fft2(img)).^2);

end

