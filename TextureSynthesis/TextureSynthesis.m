function TextureSynthesis()
    close all;
    WINDOW_SIZE = 5;    % Neighbor window size
    SIGMA = 1.5;    % Gaussian kernal sigma
    EPS = 0.1;    % Closest match threshold
    OUTPUT_SIZE = 100;  % Size of the output texture image
    
    fileName = '5_brick.jpg';
    imReal = imread(strcat('Test_Photos\',fileName));
    imReal = rgb2gray(imReal);
    
    imshow(imReal);
    title('Sample Texture');
    
    % Get sample texture
    textureRect = getrect;
    imSample = imcrop(imReal,textureRect);
    
    % Initialize image being synthesized from imReal texture
    im = uint8(zeros(OUTPUT_SIZE,OUTPUT_SIZE));
    
    % Initialize a matrix specifying which pixels have been textured
    textured = uint8(zeros(OUTPUT_SIZE,OUTPUT_SIZE));
    
    % Generate random seed starting pixel of size 3x3
    [h,w] = size(imSample);
    seed = [randi([2,h-1]) randi([2,w-1])]; 
    for i=-1:1:1
        for j=-1:1:1
            im(seed(1)+i,seed(2)+j) = imSample(seed(1)+i,seed(2)+j);
            textured(seed(1)+i,seed(2)+j) = 1;
        end
    end
    
    % Gaussian mask to make error for closer pixels larger
    gaussMask = fspecial('gaussian',WINDOW_SIZE,SIGMA);
    
    % Get a mask of the border
    se = strel('square',3);
    borderMask = imdilate(textured,se)-textured;
    
    while sum(sum(borderMask))~=0  % While there are still border pixels
        [borderRows,borderCols] = find(borderMask); % Get the x,y values of the dilated border
        % Loop through the border pixels
        for index=1:length(borderRows)
            row = borderRows(index);
            col = borderCols(index);
            
            % Generate image patch around p
            imPatch = GeneratePatch(im, row, col, WINDOW_SIZE); % Generate image patch around p
            
            % Get the valid mask, this mask is so we ignore the unknown neighborhood pixel values 
            % in our calculations
            validMask = GenerateValidMask(textured, row, col, WINDOW_SIZE);
            
            % Get the best match, (match with the lowest ssd error)
            [bestMatchRows,bestMatchCols] = FindBestMatches(gaussMask, validMask, imPatch, imSample, ...
                WINDOW_SIZE, EPS);
%             randIndex = randi(length(bestMatchRows));
%             im(row,col) = imSample(bestMatchRows(randIndex), ...
%                 bestMatchCols(randIndex)); % Set im to one of the best match pixels
            im(row,col) = imSample(bestMatchRows,bestMatchCols);
            textured(row,col) = 1; % Update textured matrix to keep track of what has been textured
            imshow(im);
        end
        borderMask = imdilate(textured,se)-textured;    % Get the new border mask
    end
    
    strcat('Output_Photos\',fileName);
    imwrite(im,strcat('Output_Photos\',fileName));
end

% This function generates a WINDOW_SIZE x WINDOW_SIZE patch around row,col 
function[patch] = GeneratePatch(im, row, col, WINDOW_SIZE)
    patch = zeros(WINDOW_SIZE,WINDOW_SIZE);
    for i=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
        for j=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
            if (row+i) < 1 || (col+j) < 1 || ...
                    (row+i) > size(im,1) || (col+j) > size(im,2)  % If out of bounds
                patch((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = 0; % Set to 0
            else
                patch((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = im(row+i,col+j);
            end
        end
    end
end

% This function generates a valid mask. This is used to handle unknown neighborhood pixel values. 
function[validMask] = GenerateValidMask(textured, row, col, WINDOW_SIZE)
    validMask = zeros(WINDOW_SIZE,WINDOW_SIZE);
    for i=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
        for j=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
            if (row+i) < 1 || (col+j) < 1 || ...
                    (row+i) > size(textured,1) || (col+j) > size(textured,2)  % If out of bounds
                validMask((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = 0;
            else    % Determine if pixel is known, if it is, set to 1
                validMask((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = textured(row+i,col+j);
            end
        end
    end
end

% This function finds the best match. The algorithm only matches the known values and normalizes the
% error by the total number of known pixels.
function[bestMatchRows,bestMatchCols] = FindBestMatches(gaussMask, validMask, imPatch, imSample, ...
    WINDOW_SIZE, EPS)
    [h,w] = size(imSample);
    matches = zeros(h,w);
    minError = 8*255^2;
    
    % Loop through sample image to find the best match
    for i=floor(WINDOW_SIZE/2+1):h-floor(WINDOW_SIZE/2-1)
        for j=floor(WINDOW_SIZE/2+1):w-floor(WINDOW_SIZE/2-1)
            imSamplePatch = GeneratePatch(imSample, i, j, WINDOW_SIZE);
            ssdError = SSDError(imSamplePatch,imPatch, gaussMask, validMask); % Get the new error
            if ssdError < minError
                minError = ssdError;
                bestMatchRows = i;
                bestMatchCols = j;
            end
            matches(i,j) = ssdError;
        end
    end
%     [bestMatchRows,bestMatchCols] = find(matches < (1+EPS)*min(min(matches(matches>0))));
%     [bestMatchRows,bestMatchCols] = find(matches == min(min(matches(matches>0))));

end

% Calculate the normalized sum of squared differences error for the input patch and sample patch
function[ssdError] = SSDError(imSamplePatch, imPatch, gaussMask, validMask, EPS)
    imSamplePatch(ceil(numel(imSamplePatch)/2)) = 0;    % Set the middle pixel to 0
    ssdError = (double(imSamplePatch) - double(imPatch)).^2;
    ssdError = NormalizeMatrix(ssdError);
    ssdError = ssdError.*gaussMask.*validMask; % Only get the error for the known values
    ssdError = sum(sum(ssdError));
end