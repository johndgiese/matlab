function complexZeros(w,varargin)
    
    NX = 800;
    NY = 800;    

    if nargin == 1
        x = linspace(-50,50,NX);
        y = linspace(-50,50,NY);
    elseif nargin == 2
        x = varargin{1};
        y = varargin{2};
    end
    
    cmap = [1 .5 0; 1 1 1; 0 .5 1; 0 0 0];
    fh = figure;
    updatePlot();    
    zh = zoom(fh);
    set(zh,'ActionPostCallback',@customZoom);        
        
    function updatePlot()
        [X Y] = meshgrid(x,y);
        Z = X + 1i*Y;
        W = w(Z);
        A = angle(W)+pi;
        C = floor(A/(pi/2)) + 1;
        imagesc(x,y,C);
        colormap(cmap);
    end

    function customZoom(obj,evd)
        xl = get(evd.Axes,'XLim');
        yl = get(evd.Axes,'YLim');
        x = linspace(xl(1),xl(2),NX);
        y = linspace(yl(1),yl(2),NY);
        updatePlot();
    end

end