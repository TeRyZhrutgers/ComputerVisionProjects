% This function makes a pyramid of images
% Minsize dictages the minimum height or width of the smallest image
% in the template
function[pyramid] = MakePyramid(im, minsize, ratio)
    pyramid = {im};    % Initialize cell array
    
    [h,w] = size(im);
    
    % Make a pyramid by reducing the size until the minsize
    while w > minsize && h > minsize
        im = imresize(im, ratio);
        pyramid{end+1} = im;    % Add the resized image
        [h,w] = size(im);
    end
end