function c = mat2cellstr(a,pre,post,format)
%INPUT
% a - vector of number ,e.g. [1 2 3 4.5];
% pre - is a string that will prepend every number
% post - is a string that will be after every number

%OUTPUT
% c - cell with string representation of the number is input array.
%EXAMPLE
% a=[1 2 4 6 -12];
% c=numarray2cellstring(a);
% c = 
%
%   '1'    '2'    '4'    '6'    '-12'
%

c={};
if (~exist('pre','var'))
    pre = '';
end
if (~exist('post','var'))
    post = '';
end
if (exist('format','var'))
    for i=1:length(a) 
        c{end+1}=[pre, num2str(a(i),format), post];
    end
else
    for i=1:length(a) 
        c{end+1}=[pre, num2str(a(i)), post];
    end
end