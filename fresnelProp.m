function [x y E1] = fresnelProp(z,lambda,A,B,E0)    
    [Na Nb] = size(E0);
    dA = A(1,2) - A(1,1);
    dB = B(2,1) - B(1,1);
    fx = 1/(2*dA)*linspace(-1,1,Na); % not exact, but very close for big Nx
    fy = 1/(2*dB)*linspace(-1,1,Nb); % same
    [Fx Fy] = meshgrid(fx,fy);
    k = 2*pi/lambda;
    H = exp(-1j*pi/lambda/z*(A.^2 + B.^2));
    E1 = exp(1j*k*z)/(1j*lambda*z)*exp(1j*pi*lambda*z*(Fx.^2+Fy.^2)).*...
        fftshift(fft2(E0.*H))/Na/Nb;
    x = fx*lambda*z;
    y = fy*lambda*z;
end