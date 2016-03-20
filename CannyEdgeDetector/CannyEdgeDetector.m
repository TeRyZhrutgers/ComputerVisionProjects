% Perform edge detection with interpolation during non maximum suppression
function CannyEdgeDetector()
    close all;  % Close figures
    saveImage = true;
    sigma = 1; % Gaussian filter sigma
    highThresholdRatio = 0.275; % High threshold ratio
    lowThresholdRatio = 0.25; % Low threshold ratio OF THE high threshold
    
    % Change the current folder to the folder of this m-file.
    % Courtesy of Brett Shoelson
    if(~isdeployed)
      cd(fileparts(which(mfilename)));
    end
    
    im = imread('Test_Photos\test1.jpg');
    figure; imshow(im);
    title('Original Image');
    if saveImage
        imwrite(im, 'Output_Photos\1_original.jpg');
    end
    
    % Smooth with Gaussian 5x5 filter to reduce noise
    im = rgb2gray(im);
    figure; imshow(im);
    title('B/W Image');
    if saveImage
        imwrite(im, 'Output_Photos\2_bw.jpg');
    end
    
    im = double(imgaussfilt(im,sigma));
    figure; imshow(NormalizeMatrix(im));
    title('Gaussian Filter');
    if saveImage
        imwrite(NormalizeMatrix(im), 'Output_Photos\3_gaussian.jpg');
    end
    
    % Find the intensity gradient of the image
    Gx = SobelFilter(im, 'x');
    Gy = SobelFilter(im, 'y');
    Gx = imgaussfilt(Gx,sigma);
    Gy = imgaussfilt(Gy,sigma);
    figure; imshow(abs(NormalizeMatrix(Gx)));
    title('Gx Sobel Filter');
    if saveImage
        imwrite(abs(NormalizeMatrix(Gx)), 'Output_Photos\4_gx_sobel.jpg');
    end
    figure; imshow(abs(NormalizeMatrix(Gy)));
    title('Gy Sobel Filter');
    if saveImage
        imwrite(abs(NormalizeMatrix(Gy)), 'Output_Photos\5_gy_sobel.jpg');
    end
    
    % Find the magnitude of the gradient
    Gmag = sqrt(Gx.^2 + Gy.^2);
    angle = atan2(Gy,Gx)*180/pi;
    figure; imshow(NormalizeMatrix(Gmag));
    title('Gmag');
    if saveImage
        imwrite(NormalizeMatrix(Gmag), 'Output_Photos\6_gmag.jpg');
    end
         
    % Perform non-maximum suppression using interpolation
    [h,w] = size(im);
    X=[-1,0,+1 ;-1,0,+1 ;-1,0,+1];
	Y=[-1,-1,-1 ;0,0,0 ;+1,+1,+1];
    output = zeros(h,w);
    x = [0 1];
    for i=2:h-1 % row
        for j=2:w-1 % col
            if (angle(i,j)>=0 && angle(i,j)<=45) || ...
                    (angle(i,j)<-135 && angle(i,j)>=-180)
                yBot = [Gmag(i,j+1) Gmag(i+1,j+1)];
                yTop = [Gmag(i,j-1) Gmag(i-1,j-1)];
                x_est = abs(Gy(i,j)/Gmag(i,j)); % y
                if (Gmag(i,j) >= ((yBot(2)-yBot(1))*x_est+yBot(1)) && ...
                    Gmag(i,j) >= ((yTop(2)-yTop(1))*x_est+yTop(1))) % interpolation
                    output(i,j)= Gmag(i,j);
                else
                    output(i,j)=0;
                end
            elseif (angle(i,j)>45 && angle(i,j)<=90) || ...
                    (angle(i,j)<-90 && angle(i,j)>=-135)
                yBot = [Gmag(i+1,j) Gmag(i+1,j+1)];
                yTop = [Gmag(i-1,j) Gmag(i-1,j-1)];
                x_est = abs(Gx(i,j)/Gmag(i,j));
                if (Gmag(i,j) >= ((yBot(2)-yBot(1))*x_est+yBot(1)) && ...
                    Gmag(i,j) >= ((yTop(2)-yTop(1))*x_est+yTop(1)))
                    output(i,j)= Gmag(i,j);
                else
                    output(i,j)=0;
                end
            elseif (angle(i,j)>90 && angle(i,j)<=135) || ...
                    (angle(i,j)<-45 && angle(i,j)>=-90)
                yBot = [Gmag(i+1,j) Gmag(i+1,j-1)];
                yTop = [Gmag(i-1,j) Gmag(i-1,j+1)];
                x_est = abs(Gx(i,j)/Gmag(i,j));
                if (Gmag(i,j) >= ((yBot(2)-yBot(1))*x_est+yBot(1)) && ...
                    Gmag(i,j) >= ((yTop(2)-yTop(1))*x_est+yTop(1)))
                    output(i,j)= Gmag(i,j);
                else
                    output(i,j)=0;
                end
            elseif (angle(i,j)>135 && angle(i,j)<=180) || ...
                    (angle(i,j)<0 && angle(i,j)>=-45)
                yBot = [Gmag(i,j-1) Gmag(i+1,j-1)];
                yTop = [Gmag(i,j+1) Gmag(i-1,j+1)];
                x_est = abs(Gx(i,j)/Gmag(i,j));
                if (Gmag(i,j) >= ((yBot(2)-yBot(1))*x_est+yBot(1)) && ...
                    Gmag(i,j) >= ((yTop(2)-yTop(1))*x_est+yTop(1)))
                    output(i,j)= Gmag(i,j);
                else
                    output(i,j)=0;
                end
            end           
        end
    end
    
    Gmag = NormalizeMatrix(output);
    figure; imshow(Gmag);
    title('Non Maximum Suppression');
    if saveImage
        imwrite(Gmag, 'Output_Photos\7_non_maximum_suppression.jpg');
    end
    
    % Perform double thresholding
    highThreshold = max(max(Gmag))*highThresholdRatio;
    lowThreshold = highThreshold*lowThresholdRatio;
    strongEdgesRow = zeros(1,h*w); % Keep track of the strong edge row index
    strongEdgesCol = zeros(1,h*w); % Keep track of the strong edge col index
    weakEdgesRow = zeros(1,h*w);  % Keep track of the weak edge row index
    weakEdgesCol = zeros(1,h*w);  % Keep track of the weak edge col index
    strongIndex = 1;
    weakIndex = 1;
    for i=2:h-1 % row
        for j=2:w-1 % col
            if Gmag(i,j) > highThreshold    % Strong edge
                Gmag(i,j) = 1;
                strongEdgesRow(strongIndex) = i;
                strongEdgesCol(strongIndex) = j;
                strongIndex = strongIndex + 1;
            elseif Gmag(i,j) < lowThreshold % No edge
                Gmag(i,j) = 0;
            else                            % Weak edge
                weakEdgesRow(weakIndex) = i;
                weakEdgesCol(weakIndex) = j;
                weakIndex = weakIndex + 1;
            end
        end
    end
    figure; imshow(Gmag);
    title('Double Threshold'); 
    if saveImage
        imwrite(Gmag, 'Output_Photos\8_double_threshold.jpg');
    end
    
    % Perform edge tracking by hysteresis
    set(0,'RecursionLimit',10000)
    for i=1:strongIndex-1
        % Find the weak edges that are connected to strong edges and set 
        % them to 1
        Gmag = FindConnectedWeakEdges(Gmag, strongEdgesRow(i),...
            strongEdgesCol(i));
    end
    figure; imshow(Gmag);
    title('Edge Tracking Before Clean Up'); 
    if saveImage
        imwrite(Gmag, 'Output_Photos\9_edge_tracking.jpg');
    end
    
    % Remove the remaining weak edges that are not actually edges
    % and is noise instead
    for i=1:weakIndex-1
        if Gmag(weakEdgesRow(i),weakEdgesCol(i)) ~= 1
            Gmag(weakEdgesRow(i),weakEdgesCol(i)) = 0;
        end
    end
    figure; imshow(Gmag);
    title('Edge Tracking After Clean Up'); 
    if saveImage
        imwrite(Gmag, 'Output_Photos\10_final.jpg');
    end
    
%     % MATLAB canny comparison
%     im = imread('Test_Photos/test1.jpg');
%     im = rgb2gray(im);
%     im = edge(im, 'canny');
%     figure; imshow(im);
%     title('MATLAB');
end

% Perform sobel filter
function[A] = SobelFilter(A, filterDirection)
    switch filterDirection
        case 'x' 
            Gx = [-1 0 +1; -2 0 +2; -1 0 +1];
            A = imfilter(A, double(Gx), 'conv', 'replicate');
        case 'y'
            Gy = [-1 -2 -1; 0 0 0; +1 +2 +1];
            A = imfilter(A, double(Gy), 'conv', 'replicate');
        otherwise
            error('Bad filter direction - try inputs ''x'' or ''y''');
    end
end

% Find weak edges that are connected to strong edges and set them to 1
function[Gmag] = FindConnectedWeakEdges(Gmag, row, col)
    for i = -3:1:3
        for j = -3:1:3
            if (row+i > 0) && (col+j > 0) && (row+i < size(Gmag,1)) && ...
                    (col+j < size(Gmag,2)) % Make sure we are not out of bounds
                if (Gmag(row+i,col+j) > 0) && (Gmag(row+i,col+j) < 1)
                    Gmag(row+i,col+j) = 1;
                    Gmag = FindConnectedWeakEdges(Gmag, row+i, col+j);
                end
            end
        end
    end
end