classdef ImageIterator < FileIterator
    %ImageIterator Conveniently loop through files.
    %   Pass in a relative directory and a glob, and return an iterator
    %   that returns the relative path of all the images.
    %
    %   Example:
    %
    %       folder = 'my/images/are/here';
    %       glob = '*.tif';
    %       imgs = ImageIterator(folder, glob);
    %       while(imgs.more())
    %           img = imgs.next();
    %       end

    methods
        function obj = ImageIterator(folder, glob)
            obj = obj@FileIterator(folder, glob);            
        end
        
        function img = next(self)
            if ~self.more()
                img = [];
            else
                img = imread(self.filenames{self.current});
                self.current = self.current + 1;
            end
        end
    end

end
