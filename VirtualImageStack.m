classdef VirtualImageStack < handle
    %IMAGESTACK A convenience class for saving sets of images.
    %
    %   Images are stored on disk; note all images are assumed to be the
    %   same size and have the same bitdepth.
    %
    %   EXAMPLE:    
    %       filetype = 'tiff';
    %       stack = ImageStack('my/directory', filetype);
    %
    %   NOTE: The stack assumes that all images in the specified folder starting
    %   with basename should be processed as part of the stack.        
    
    properties (Hidden, SetAccess = private)
        folder        
        filetype
        count
        iterator
    end

    methods
        function obj = VirtualImageStack(folder, filetype)
            obj.folder = folder;            
            obj.filetype = filetype;
            obj.count = 0;            
            [~, ~, ~] = mkdir(obj.folder);
        end
        
        function img_name = push(self, img)
            img_name = self.next_name();
            save_location = fullfile(self.folder, img_name);
            imwrite(img, save_location);
            self.count = self.count + 1;
        end
        
        function movie = movie(self, varargin)
        %MOVIE Generate an AVI movie from the virtual image stack. 
        %
        %   The first argument is a string specifying the colormap;
        %   defaults to gray.  See COLORMAP for available colormaps.
        %   
        %   Example:
        %       fps = 30;
        %       repeat = 5;
        %       cmap = 'jet';
        %       M = stack.movie(cmap);
        %       movie(M, repeat, fps);
        %
        %   See also MOVIE.
                   
            if length(varargin) >= 1
                cmap = varargin{1};
            else
                cmap = 'gray';
            end                       
            
            bitdepth = self.bitdepth();
            cmap_size = 2^bitdepth;
            cmap = eval([cmap, '(', num2str(cmap_size), ');']);                                                       
            
            imgs = self.create_iterator();
            movie(imgs.length) = struct('cdata',[],'colormap',[]);
            for i = 1:imgs.length
                img = imgs.next();
                movie(i) = im2frame(img, cmap);
            end            
        end

        function reset(self)
            self.iterator = self.create_iterator();
        end

        function next(self)
            self.iterator.next();
        end
        
        function iterator = create_iterator(self)
            glob = ['*.', self.filetype];
            iterator = ImageIterator(self.folder, glob);
        end
        
        function bitdepth = bitdepth(self)
            first_img_name = self.create_file_iterator().next();
            info = imfinfo(first_img_name);
            bitdepth = info.BitDepth;
        end
    end


    methods (Access = private)
        
        function iterator = create_file_iterator(self)           
            glob = ['*.', self.filetype];
            iterator = FileIterator(self.folder, glob);
        end

        function img_name = next_name(self)
            count_as_str = sprintf('%4.4d', self.count);
            img_name = ['img', count_as_str, '.', self.filetype];
        end
        
        function test_img = test_image(self)
            imgs = self.create_iterator();
            if imgs.more()
                test_img = imgs.next();
            else
                test_img = [];
            end            
        end

    end

end
