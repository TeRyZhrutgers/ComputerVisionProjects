% This function shows the pyramid image in a figure
function ShowPyramid(pyramid)
    if isempty(pyramid)
        return
    end
    
    pyramidImage = uint8(0);
    
    for i=1:size(pyramid,2)     % Iterate through the 1xn pyramid of images
        padadd(pyramidImage,pyramid{i});
    end 
       
    imshow(pyramidImage);
end