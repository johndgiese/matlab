classdef DirectoryIterator < handle
    %DirectoryIterator Conveniently loop through directories.

    properties (Hidden, SetAccess = protected)
        current = 1;
        directories = {};
    end

    properties (SetAccess = protected)
        length = 0;
    end

    methods
        function iterator = FileIterator(folder)
            fullFolder = fullfile(folder, '/');
            files = dir(fullFolder);
            iterator.length = length(files);
            iterator.dirnames = cell(iterator.length, 1);
            for i = 1:iterator.length
                folder = files(i).name;
                iterator.dirnames{i} = fullfile(folder, '/', folder);
            end
        end

        function dirname = next(self)
            if ~self.more()
                dirname = '';
            else
                dirname = self.dirnames{self.current};
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