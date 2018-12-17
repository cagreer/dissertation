close all;
clear all;
imageFolder = 'C:\ImagesDissertation\109CANON';
splitStr = strsplit(imageFolder, '\');
tableName = splitStr{end};
knownObjects = createTable;

photoImages = imageDatastore(fullfile(imageFolder), 'IncludeSubfolders', false, 'FileExtensions', '.jpg');
[numImg, ~] = size(photoImages.Files());

for i = 1:numImg
    photo = readimage(photoImages, i);
    grayPhoto = rgb2gray(photo);
    photoPoints = detectSURFFeatures(grayPhoto);
    [photoFeatures, valid_photoPoints] = extractFeatures(grayPhoto, photoPoints);
    [pathstr, name, ext] = fileparts(char(photoImages.Files(i)));
    fileName = fullfile(pathstr, strcat(name, '_mod', ext));
    RGB = photo;
    for t = 1:height(knownObjects)
        imageLocation = char(knownObjects.Image(t));
        known = imread(imageLocation);
        grayKnown = rgb2gray(known);
        
        knownPoints = detectSURFFeatures(grayKnown);
        [knownFeatures, valid_knownPoints] = extractFeatures(grayKnown, knownPoints);
        
        boxPairs = matchFeatures(knownFeatures, photoFeatures);
        matchedKnownPoints = valid_knownPoints(boxPairs(:, 1), :);
        matchedPhotoPoints = valid_photoPoints(boxPairs(:, 2), :);
        
%         figure;
%         showMatchedFeatures(grayKnown, grayPhoto, matchedKnownPoints, matchedPhotoPoints, 'montage');
%         title('Putatively Matched Points (Including Outliers)');
        
        if(matchedKnownPoints.Count>=5)
            
            [tform, inlierKnownPoints, inlierPhotoPoints] = estimateGeometricTransform(matchedKnownPoints, matchedPhotoPoints, 'affine');
        
            boxPolygon = [1, 1;...                           % top-left
                size(grayKnown, 2), 1;...                 % top-right
                size(grayKnown, 2), size(grayKnown, 1);... % bottom-right
                1, size(grayKnown, 1);...                 % bottom-left
                1, 1];                   % top-left again to close the polygo

            newBoxPolygon = transformPointsForward(tform, boxPolygon);
            pos = zeros(1,8);
            num = 1;
            for ii = 1:4
                for tt = 1:2
                   pos(num) = newBoxPolygon(ii, tt);
                   num = num +1;
                end
            end
            
            
            
            RGB = insertShape(RGB, 'Polygon', pos, 'Color', 'y');
            imwrite(RGB, fileName);
            
        end
    end
end




function [tableT] = createTable()

    Image = {'C:\ImagesDissertation\KnownObjects\Tripplite.jpg'; 'C:\ImagesDissertation\KnownObjects\ATMeteoStation.jpg';
        'C:\ImagesDissertation\KnownObjects\Empire331-9Level.jpg'; 'C:\ImagesDissertation\KnownObjects\Mafrotto496.jpg';
        'C:\ImagesDissertation\KnownObjects\WipeAWays.jpg'};
    Label = {'Tripp Lite'; 'AT Meteo'; 'Torpedo Level'; 'Mafrotto'; 'Wipe A Way'};
    Dimension = {9.000; 4.738; 9.000; 3.697; 9.500};
    
    tableT = table(Image, Label, Dimension);
end