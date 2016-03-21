% This function computes the difference in gaussian and outputs a new pyramid
function gaussianPyramid = ComputeDifferenceOfGaussian(pyramid)
    if isempty(pyramid)
        return
    end
    
    gaussianPyramid = {};    % Initialize difference of gaussian cell array
    
    for i=1:size(pyramid,2)     % Iterate through the octaves
        for j=1:size(pyramid{1},2)-1  % Iterate through the scales
            gaussianPyramid{i}{j} = pyramid{i}{j+1} - pyramid{i}{j};
        end
    end 
end