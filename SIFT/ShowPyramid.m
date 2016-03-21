% This function shows the pyramid image in a figure
function ShowPyramid(pyramid)
    if isempty(pyramid)
        return
    end
    
    pyramidImage = cell(1,size(pyramid,2));
    pyramidImage(:) = {uint8(0)};
    
    for i=1:size(pyramid,2)     % Iterate through the octaves
        for j=1:size(pyramid{1},2)  % Iterate through the scales
            temp = pyramidImage{i};
            padadd(temp, pyramid{i}{j});
            pyramidImage{i} = temp;
        end
    end 
    
    figure;
    for i=1:length(pyramidImage)
        subplot(length(pyramidImage),1,i);
        imshow(pyramidImage{i});
    end
end