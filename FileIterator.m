classdef FileIterator < handle
    %FileIterator Conveniently loop through files.
    %   Pass in a relative directory and a glob, and return an iterator
    %   that returns the relative path of all the files.
    %
    %   Example:
    %
    %       folder = 'my/images/are/here';
    %       glob = '*.tif';
    %       imgs = FileIterator(folder, glob);
    %       while(imgs.more())
    %           img = imread(imgs.next());
    %       end

    properties (Hidden)
        current = 1;
        filenames = {};
    end

    properties (SetAccess = private)
        length = 0;
    end

    methods
        function iterator = FileIterator(folder, glob)
            fullFolder = fullfile(folder, '/');
            files = dir([fullFolder, glob]);
            iterator.length = length(files);
            iterator.filenames = cell(iterator.length, 1);
            for i = 1:iterator.length
                filename = files(i).name;
                iterator.filenames{i} = fullfile(folder, '/', filename);
            end
        end

        function filename = next(self)
            if ~self.more()
                filename = '';
            else
                filename = self.filenames{self.current};
                self.current = self.current + 1;
            end
        end

        function more = more(self)
            more = self.current <= self.length;
        end

        function iterator = reset(self)
            self.current = 1;
            iterator = self;
        end
    end

end
