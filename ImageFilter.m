 classdef ImageFilter < handle
     %IMAGEFILTER 
     % 
     % Abstract base class for an image filter

     methods (Abstract)
         apply(obj, img)
     end
 end
