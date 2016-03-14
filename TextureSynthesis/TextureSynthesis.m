function TextureSynthesis()
    close all;
    WINDOW_SIZE = 15;    % Neighbor window size
    SIGMA = 1.5;    % Gaussian kernal sigma
    EPS = 0.1;    % Closest match threshold
    OUTPUT_SIZE = 10;  % Size of the output texture image
    
    fileName = '3_grid.png';
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
    
    gaussMask = fspecial('gaussian',WINDOW_SIZE,SIGMA);
    
    se = strel('square',3);
    borderMask = imdilate(textured,se)-textured;
    
    while sum(sum(borderMask))~=0  % While there are still border pixels
        [borderRows,borderCols] = find(borderMask);
        % Loop through the border pixels
        for index=1:length(borderRows)
            row = borderRows(index);
            col = borderCols(index);
            imPatch = GeneratePatch(im, row, col, WINDOW_SIZE); % Generate image patch around p
            validMask = GenerateValidMask(textured, row, col, WINDOW_SIZE);
            [bestMatchRow,bestMatchCol] = FindBestMatch(gaussMask, validMask, imPatch, imSample, ...
                WINDOW_SIZE);
            im(row,col) = imSample(bestMatchRow,bestMatchCol);
            textured(row,col) = 1;
            imshow(im);
        end
        borderMask = imdilate(textured,se)-textured;
    end
    
    strcat('Output_Photos\',fileName);
    imwrite(im,strcat('Output_Photos\',fileName));
end

function[patch] = GeneratePatch(im, row, col, WINDOW_SIZE)
    patch = zeros(WINDOW_SIZE,WINDOW_SIZE);
    for i=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
        for j=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
            if (row+i) < 1 || (col+j) < 1 || ...
                    (row+i) > size(im,1) || (col+j) > size(im,2)  % If out of bounds
                patch((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = 0;
            else
                patch((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = im(row+i,col+j);
            end
        end
    end
end

function[validMask] = GenerateValidMask(textured, row, col, WINDOW_SIZE)
    validMask = zeros(WINDOW_SIZE,WINDOW_SIZE);
    for i=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
        for j=-floor(WINDOW_SIZE/2):1:+floor(WINDOW_SIZE/2)
            if (row+i) < 1 || (col+j) < 1 || ...
                    (row+i) > size(textured,1) || (col+j) > size(textured,2)  % If out of bounds
                validMask((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = 0;
            else
                validMask((i+ceil(WINDOW_SIZE/2)),(j+ceil(WINDOW_SIZE/2))) = textured(row+i,col+j);
            end
        end
    end
end

function[bestMatchRow,bestMatchCol] = FindBestMatch(gaussMask, validMask, imPatch, imSample, ...
    WINDOW_SIZE)
    [h,w] = size(imSample);
    minError = 8*255^2;
    
    % Loop through sample image to find the best match
    for i=floor(WINDOW_SIZE/2+1):h-floor(WINDOW_SIZE/2-1)
        for j=floor(WINDOW_SIZE/2+1):w-floor(WINDOW_SIZE/2-1)
            imSamplePatch = GeneratePatch(imSample, i, j, WINDOW_SIZE);
            ssdError = SSDError(imSamplePatch,imPatch, gaussMask, validMask);
            if ssdError < minError
                minError = ssdError;
                bestMatchRow = i;
                bestMatchCol = j;
            end
        end
    end
end

function[ssdError] = SSDError(imSamplePatch, imPatch, gaussMask, validMask)
    imSamplePatch(ceil(numel(imSamplePatch)/2)) = 0;    % Set the middle pixel to 0
    ssdError = (double(imSamplePatch) - double(imPatch)).^2;
    ssdError = NormalizeMatrix(ssdError);
    ssdError = ssdError.*gaussMask.*validMask;
    ssdError = sum(sum(ssdError));
end