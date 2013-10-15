function folder = lowest_folder_from_path(path, dirseparator)
%LOWEST_FOLDER_FROM_PATH ('../asdf/zxcv/', '/') -> 'zxcv'

path_parts = strsplit(path, dirseparator);

for from_back = 0:(length(path_parts) - 1)
    if ~strcmp(path_parts{end - from_back}, '')
        folder = path_parts{end - from_back};
        break;
    end
end
