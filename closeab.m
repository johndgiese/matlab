
% close all figures but the last N made
function closeab(n)
    afh = sort(findall(0,'type','figure'));
    N = length(afh);
    for i = 1:(N-n)
        close(afh(i))
    end
end