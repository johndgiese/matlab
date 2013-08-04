function fftplot(x,Fs)
    X = fft(x);
    N = length(x);
    f = (0:(N-1))/N*Fs;
    ind = find(f > Fs/2,1,'first'); % grab only first half of the spectrum    
    
    % Plot single-sided amplitude spectrum.
    plot(f(1:ind),2*abs(X(1:ind))) 
    title('Single-Sided Amplitude Spectrum of x(t)')
    xlabel('Frequency (Hz)')
    ylabel('|X(f)|')
end