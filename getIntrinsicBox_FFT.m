% =========================================================================
%            __                                                         
%           //\\               MAGNA Electronics Europe GmbH & Co. KG   
%           \\//                                                        
%                                                                       
%        \\\\\ \\\\\                                                    
%      /\ \\\\\ \\\\\          Kurfuerst-Eppstein-Ring 9                
%     //\\ \\\\\ \\\\\         63877 Sailauf                            
%    ///\\\ \\\\\ \\\\\        Germany                                  
%   ////\\\\ \\\\\ \\\\\                                                
%  /////\\\\\ \\\\\ \\\\\      www.magnaelectronics.eu                  
%                                                                       
% ------------------------------------------------------------------------ 
% MAGNA Electronics - C O N F I D E N T I A L                           
%  This document in its entirety is CONFIDENTIAL and may not be         
%  disclosed, disseminated or distributed to parties outside MAGNA      
%  Electronics without written permission from MAGNA Electronics.       
% =========================================================================
%> @file IntrinsicVerify_DotSphere.m
%> @brief Implemenation of intrinsic verification in a dot sphere
% =========================================================================

% =========================================================================
%> @brief Abstract parent of intrisic verification class 
%> 
%> 
% =========================================================================



classdef getIntrinsicBox_FFT  < made.Intrinsic
    
    properties (SetAccess = public)
        
        %> Maximum possible number of dots in Left/Right and Upper/Lower target boards
        maxDotsLeftRight =  18;
        maxDotsUpperLower = 14;
       
        %> Center dots (left and right) area threshold (Default = [320 800])
        CenterDotsAreaThreshold = [300 700]; % For LVDS camera
        %CenterDotsAreaThreshold = [50 500]; % For NTSC Camera
        
        %> Dots area threshold (Default = [15 360])
        DotAreaThreshold = [10 300]; % For LVDS camera
        %DotAreaThreshold = [3 150]; % For NTSC Camera

        %> Dots detector distance of deviation from a line threshold (Default=30)
        DistanceThreshold = 25;
        
        %> Dots detector distance from the border of image (Default=14)
        BorderThreshold = 15;

        %> Size of Gaussian filter to smooth the image(Default=5)
        median_filter_size = 5;
        
        %> Size of median filter to smooth the image for imfindcircle (Default=7)
        Gaussian_filter_size = 7;
        %> EdgeThreshold used in imfindcircle (Default=0.1)
        EdgeThreshold = 0.1; % 
        %> Radius_range_imfindcircles used in imfindcircle (Default= [1 10])
        Radius_range_imfindcircles = [1 10]
        %> Gray values used to mask the MacBeth chart, rgb value is given
        %but used only first parameter as image is converted to grayscale
        %beforehand (Default= [120 120 120])
        MacBethChart_mask_value = [120 120 120];
        
        
        %> Rectangle for MacBeth chart [Not passed from configuration file]
        RectMacBethChart = [33, 92, 230, 185]; % These values will be superseeded by values estimated below
        %RectMacBethChart = [33+5, 92+5, 230+10, 185+10]; % first two are the distance from Left Dot in x and y, last two are width and height respectively. This will be camera specific.
        
        
    end % end of properties
    
    
    methods
        
        % =================================================================
        %> @brief Detect grid points within image
        %>
        %> @param Obj       Own object
        %> @param Img       Input image
        %> @param Debug     Show debug screen
        %> @retval Dots     Image pixel position of every grid point
        % =================================================================
        function [intrinsicBox2D, intrinsicBox3D, PP_mechanical] = DetectGrid (Obj, calib_config, Img, Debug)
            
            % Superceeding the defualt Obj data from configuration file
            Obj.maxDotsLeftRight =  calib_config.maxDotsLeftRight;
            Obj.maxDotsUpperLower = calib_config.maxDotsUpperLower;
            Obj.CenterDotsAreaThreshold = calib_config.CenterDotsAreaThreshold;
            Obj.DotAreaThreshold = calib_config.DotAreaThreshold;
            Obj.DistanceThreshold = calib_config.DistanceThreshold;
            Obj.BorderThreshold = calib_config.BorderThreshold;
            Obj.median_filter_size = calib_config.median_filter_size; %[Used in DetectFilterOtherDots]
            Obj.Radius_range_imfindcircles = calib_config.Radius_range_imfindcircles; %[Used in DetectFilterOtherDots]
            Obj.EdgeThreshold = calib_config.EdgeThreshold; %[Used in DetectFilterOtherDots]
            Obj.MacBethChart_mask_value = calib_config.MacBethChart_mask_value; %[Used in DetectFilterOtherDots]
            Obj.Gaussian_filter_size = calib_config.Gaussian_filter_size; % Could be used in DetectInitialDots
            
            
            
            %for ci = 1:size(Img,3)
            %    Img(:,:,ci) = histeq( Img(:,:,ci) );
            %end
            
            if (Debug == 1)
                figure(2)
                imshow (Img)
                impixelinfo
                set(gca,'xtick',[0:size(Img,2)/10:size(Img,2)])
                set(gca,'ytick',[0:size(Img,1)/10:size(Img,1)])
                axis on
                grid on
                
                
            end
            % Detect all dots within image
            Dots = Obj.DetectInitialDots (Img);


            if (Debug == 1)
                hold on, plot (Dots(:,1), Dots(:,2), 'g.');
            end
            %size(Img,1)
            %size(Img,2)
%             % Filter for center dots (left and right dots on MacBeth)
%            [LeftDot, RightDot, Dots] = Obj.DetectFilterCenterDots (Dots, [size(Img,1) size(Img,2)]);
            
            
            if(calib_config.left_dot_cognex.x ~= 9999 && calib_config.left_dot_cognex.y ~= 9999 && calib_config.right_dot_cognex.x ~= 9999 && calib_config.right_dot_cognex.y ~= 9999)
                fprintf('Using left and right dots coordinates from Cognex.');
                LeftDot = [calib_config.left_dot_cognex.x calib_config.left_dot_cognex.y];
                RightDot = [calib_config.right_dot_cognex.x calib_config.right_dot_cognex.y];
            else            
                UpperLeftSerach = 32;%32; %52; %JJT
                LeftRightSearch = 128;%128;
                % Wallis filter starts
                % Wallis filter used to change the radiometry of image under
                % consideration using a Master image
                Img_master = imread(strcat(calib_config.lens_identifier,'_Master.bmp')); 
                %Img_master = imread('PSA_Lite_Master.bmp'); %JJT
                Img_slave = Img;
                im_master_r = Img_master(:,:,1);
                im_master_g = Img_master(:,:,2);
                im_master_b = Img_master(:,:,3);
                im_slave_r = Img_slave(:,:,1);
                im_slave_g = Img_slave(:,:,2);
                im_slave_b = Img_slave(:,:,3);
                [im_master_r, im_slave_r_corr] = preprocess(im_master_r,im_slave_r);
                [im_master_g, im_slave_g_corr] = preprocess(im_master_g,im_slave_g);
                [im_master_b, im_slave_b_corr] = preprocess(im_master_b,im_slave_b);
                Img_slave(:,:,1) = im_slave_r_corr(:,:);
                Img_slave(:,:,2) = im_slave_g_corr(:,:);
                Img_slave(:,:,3) = im_slave_b_corr(:,:);
                figure (3);
                imshow(Img_slave);
                figure (4);
                imshow(Img_master);
                figure (5);
                imshow(Img);
                % Wallis filter ends
                fprintf('Wallis Filter applied for radimetric correction (only for center dots detection).');

                %plot(LeftDot(1), LeftDot(2), 'rx');
                %plot(RightDot(1), RightDot(2), 'rx');
                % Following code will superceed the above function call DetectFilterCenterDots
                % LeftDot and RightDot are detected now using template matching
                LeftRightDotsTemplate = imread(strcat(calib_config.lens_identifier,'.bmp'));   
                %LeftRightDotsTemplate = imread('PSA_Lite_medium.bmp'); %JJT
                I = Img_slave(floor(size(Img_slave,1)/2)-UpperLeftSerach:floor(size(Img_slave,1)/2)+UpperLeftSerach, floor(size(Img_slave,2)/2)-LeftRightSearch:floor(size(Img_slave,2)/2), :);
                figure(19);
                imshow (I);
                
                [I_SSD,I_NCC,Idata]=template_matching(LeftRightDotsTemplate,I);
                [x,y]=find(I_SSD==max(I_SSD(:)));            
                LeftDot = [y, x] + [floor(size(Img_slave,2)/2)-LeftRightSearch-1, floor(size(Img_slave,1)/2)-UpperLeftSerach-1];

                %figure(10)
                %imshow(I_SSD+I_NCC); title('SSD Matching');
                %impixelinfo
                I = Img_slave(floor(size(Img_slave,1)/2)-UpperLeftSerach:floor(size(Img_slave,1)/2)+UpperLeftSerach, floor(size(Img_slave,2)/2):floor(size(Img_slave,2)/2)+LeftRightSearch, :);
                                figure(29)
                imshow (I);
                [I_SSD,I_NCC,Idata]=template_matching(LeftRightDotsTemplate,I);
                [x,y]=find(I_SSD==max(I_SSD(:)));
                RightDot = [y, x] + [floor(size(Img_slave,2)/2)-1, floor(size(Img_slave,1)/2)-UpperLeftSerach-1];
            end
            %plot(LeftDot(1), LeftDot(2), 'g+');
            %plot(RightDot(1), RightDot(2), 'g+');
            fprintf('\nDetected/given left dot (x,y): %f, %f', LeftDot(1), LeftDot(2));
            fprintf('\nDetected/given right dot (x,y): %f, %f', RightDot(1), RightDot(2));

             %NOT TESTED WELL YET%
             [LeftDot] = RefineCentreDotsPositions1 (Obj, LeftDot, Img);
             [RightDot] = RefineCentreDotsPositions1 (Obj, RightDot, Img);
             %NOT TESTED WELL YET%
             fprintf('\nRefined left dot (x,y): %f, %f', LeftDot(1), LeftDot(2));
             fprintf('\nRefined right dot (x,y): %f, %f', RightDot(1), RightDot(2));
            
            
            %figure(11)
            %imshow(I_SSD+I_NCC); title('SSD Matching');
            %impixelinfo
%return
            temp = 0;
            Obj.RectMacBethChart = floor([LeftDot(1)-(RightDot(1)-LeftDot(1))/4.5,...
                                  LeftDot(2)-(RightDot(1)-LeftDot(1))/(1.75+temp),...
                                  (RightDot(1)-LeftDot(1))+(RightDot(1)-LeftDot(1))/2.25,...
                                  2*(RightDot(1)-LeftDot(1))/(1.75+temp)] );
                              

            if(strcmp(calib_config.FFT_id, 'Tiengen_RVC1'))
                Obj.RectMacBethChart = floor([LeftDot(1)-(RightDot(1)-LeftDot(1))/4.4,... % Changes made for Tiengen FFT 01.04.2017
                                      LeftDot(2)-(RightDot(1)-LeftDot(1))/(1.5+temp),...
                                      (RightDot(1)-LeftDot(1))+(RightDot(1)-LeftDot(1))/2.1,...
                                      2*(RightDot(1)-LeftDot(1))/(1.52+temp)] );
                calib_config.FFT_id                                  
            end

           %rectangle('Position',Obj.RectMacBethChart, 'edgecolor','k');

            
                
%             Img1 = medfilt2(rgb2gray(Img), [floor(Obj.median_filter_size) floor(Obj.median_filter_size)]);
%             Img2 = zeros(size(Img1,1), size(Img1,2),1);
%             Img2(:,:,1) = Obj.MacBethChart_mask_value(1);
%             
%             for i = Obj.RectMacBethChart(1):Obj.RectMacBethChart(1)+Obj.RectMacBethChart(3)
%                 for j = Obj.RectMacBethChart(2):Obj.RectMacBethChart(2)+Obj.RectMacBethChart(4)    
%                     Img2(j,i,1) = Img1(j,i,1);
%                 end
%             end
%                 
%             imshow(Img2)
%             
%             return
            
%             UpperLeftSerach = 32;
%             LeftRightSearch = 128;
% 
%             CentralMeshDotsTemplate = imread(strcat(calib_config.lens_identifier,'_meshDot.bmp'));            
%             I = Img(floor(size(Img,1)/2)-UpperLeftSerach:floor(size(Img,1)/2)+UpperLeftSerach, floor(size(Img,2)/2)-LeftRightSearch:floor(size(Img,2)/2), :);
%             [I_SSD,I_NCC,Idata]=template_matching(CentralMeshDotsTemplate,I);
%             [x,y]=find(I_SSD==max(I_SSD(:)))            
%             MeshDot = [y, x] + [floor(size(Img,2)/2)-LeftRightSearch-1, floor(size(Img,1)/2)-UpperLeftSerach-1]
%             hold on, plot(MeshDot(1), MeshDot(2), 'r*');
%             hold on
            
            % Filter for calibration dots (which might be wrong dots)


            [Dots] = Obj.DetectFilterOtherDots (Img, [size(Img,1) size(Img,2)], Debug);
%            [Dots] = Obj.DetectFilterOtherDots (Dots, Img, [size(Img,1) size(Img,2)], Debug);

           
            % Refine the position of detected dots by regionprops method
            % immeditaly after imfindcircles
            [Dots] = Obj.RefineDotsPositions1(Dots, Img, [size(Img,1) size(Img,2)], Debug);
            %hold on, plot (Dots(:,1), Dots(:,2), 'g.');

            % Check if still some double dots are there even after Dots = unique(Dots,'rows');
            [Dots] = Obj.RefineDotsPositions2(Dots, Img, [size(Img,1) size(Img,2)], Debug);
            %hold on, plot (Dots(:,1), Dots(:,2), 'g.');
            
            % Generate a virtual grid on MacBeth pattern where center dots
            % were found in earlier step
            GridMacbeth = Obj.DetectGridMacbeth(LeftDot, RightDot, Debug);
            % The center of Macbeth chart in production should be close to
            % the actual principal point of camera, provided mechanial
            % fixture is calibration and accurate. So in production mode,
            % search area will be around PP_mechanical (mechanically
            % estimated principal point) instead of center of image.
            PP_mechanical = GridMacbeth.Center;
            
            
%           plot(GridMacbeth.Center(1), GridMacbeth.Center(2), 'ro');
            
%           GridMacbeth = Obj.DetectGridMacbethOLD(LeftDot, RightDot, Debug);
            
            % Filter remaining dots
            [intrinsicBox2D, segments] = DetectOrderedDots (Obj, Dots, GridMacbeth, [size(Img,1) size(Img,2)], Debug);
%           [intrinsicBox2D, segments] = DetectOrderedDotsOLD(Obj, Dots, GridMacbeth, [size(Img,1) size(Img,2)], Debug);
            

            % Refine the position of detected dots by advanced method
            % Non-functional function
            % intrinsicBox2D = RefineDotsPositions0(Obj, Img, intrinsicBox2D);
            if (Debug == 1)
                hold on, plot (intrinsicBox2D(:,1), intrinsicBox2D(:,2), 'g.');
            end
            
            % Overlaying 3D points based on values in segments
            intrinsicBox3D = Overlay3DDots (Obj, segments, calib_config);
            
                   

            % Show debug if set
            if (Debug == 1)
                hold on
                h = plot (Dots(:,1), Dots(:,2), 'c.');
                rectangle('Position',Obj.RectMacBethChart, 'edgecolor','k');
                %plot (LeftDot(:,1), LeftDot(:,2), 'm*');
                %plot (RightDot(:,1), RightDot(:,2), 'c*');
                set(gca,'xtick',[0:size(Img,2)/10:size(Img,2)])
                set(gca,'ytick',[0:size(Img,1)/10:size(Img,1)])
                %axis on
                grid on
%               plot (Dots(find(Dots(:,6)==1),1), Dots(find(Dots(:,6)==1),2), 'r*');
            end
        end
        
        
        
        % =================================================================
        %> @brief Refine the position of LeftDot and RightDot which have
        %been detected using template matching. As the template is not
        %exectly centerd, so regionprops will be used to refine the center
        %location of dots.
        %>
        %> @param Obj       Own object
        %> @param LeftDot   (x,y) position of left dot
        %> @param RightDot  (x,y) position of right dot
        %> @param Img       Image array to check the color information
        %> @retval Dots     Remaining Dots without left and right dot
        % =================================================================
        function [LeftOrRightDot] = RefineCentreDotsPositions1 (Obj, LeftOrRightDot, Img)
        
                     
            
            LeftOrRightDotFloor = floor(LeftOrRightDot);
            roundingDiff = LeftOrRightDot - LeftOrRightDotFloor;

            img = Img(LeftOrRightDotFloor(2)-2*Obj.BorderThreshold:LeftOrRightDotFloor(2)+2*Obj.BorderThreshold,...
                          LeftOrRightDotFloor(1)-2*Obj.BorderThreshold:LeftOrRightDotFloor(1)+2*Obj.BorderThreshold);
                      
            bw = ~im2bw(img,graythresh(img));     
            %bw = abs(bw-1);
            CC_Dots = regionprops(bw, 'Centroid', 'Area', 'BoundingBox', 'Perimeter' );
            newDots = [];
               
            for iRegion=1:size(CC_Dots,1)
            
                x1 = 2*Obj.BorderThreshold;
                y1 = 2*Obj.BorderThreshold;
                x2 = CC_Dots(iRegion).Centroid(1);
                y2 = CC_Dots(iRegion).Centroid(2);
                d = sqrt((x2-x1)^2+(y2-y1)^2); % Trying to find out the region which is the center. Just to avoid the situation when a small portion of adjoining dot is visible.
                if (d<7) % There might be more regions detected due to adjoining Dots visible part. So keep only center Dot.
                    newDots = [newDots; CC_Dots(iRegion).Centroid CC_Dots(iRegion).Area CC_Dots(iRegion).Perimeter]; % BoundingBox is not needed
                end
            end
            %size(newDots,1)
            if(size(newDots,1)~=0) % In case the Dot is not detected properly in this step
                refineShift = [newDots(1)-2*Obj.BorderThreshold-1, newDots(2)-2*Obj.BorderThreshold-1] - roundingDiff;
                LeftOrRightDot(1:2) = LeftOrRightDot(1:2) + refineShift;
                LeftOrRightDot(5:6) = newDots(3:4);
            end
            
             showInBetween = 0;
                if(showInBetween)
                    figure(10)
                    pause(0.5)
                    imshow(bw)                
                    hold on, plot(newDots(1), newDots(2), 'r.');
                    hold on, plot(size(img,1)/2, size(img,2)/2, 'b.');
                    figure(11)
                    imshow(img)
                
                end
            
            

        end
        
        

        
        % =================================================================
        %> @brief Detect inital dots in image
        %>
        %> @param Obj       Own object
        %> @param Img       Input image      
        %> @retval Dots     List of dots 
        % =================================================================
        function [Dots] = DetectInitialDots (Obj, Img)
            
            % preparation of input image, automatic grayscaling and thresholding
            
            %G = fspecial('gaussian',[floor(Obj.Gaussian_filter_size) floor(Obj.Gaussian_filter_size)],2);
            %Img = imfilter(Img,G,'same');       
            %Img = imnoise(Img,'gaussian');
            %imshow(Img)

            %Img = im2double(Img); Img = Img(:,:,2); 

            %Img = histeq(Img);
            %imshow(edge(Img,'canny'))
            %Img = medfilt2(rgb2gray(Img), [7 7]);
            %if(strcmp(Camera.lens_identifier, 'Zurich2_Lite_30') || strcmp(Camera.lens_identifier, 'Zurich2_Lite_25') )
%                BW = ~im2bw(Img(:,:,3),graythresh(Img(:,:,3))); %JJT operate on the Green Channel for Xurich 2 Lite
            %else
%                Img = medfilt2(rgb2gray(Img), [7 7]);
                BW = ~im2bw(Img,graythresh(Img));
            %end
            
            
            imshow(BW);
            % connected components 
            CC_Dots = regionprops(BW, 'Centroid', 'Area', 'BoundingBox', 'Perimeter' );
        
            % Perimeter in the regionprops is less than 40 for inner Dots
            % MajorAxisLength in the regionprops is less than 10 for inner Dots
            
            % Removing dots found on the border of the image
            Dots = [];
            for i=1:size(CC_Dots,1)
                if (CC_Dots(i).BoundingBox(1)>=1 && CC_Dots(i).BoundingBox(1)+CC_Dots(i).BoundingBox(3)<=size(Img,2)-1 &&...
                    CC_Dots(i).BoundingBox(2)>=1 && CC_Dots(i).BoundingBox(2)+CC_Dots(i).BoundingBox(4)<=size(Img,1)-1)    
                    Dots = [Dots; CC_Dots(i).Centroid CC_Dots(i).Area CC_Dots(i).BoundingBox CC_Dots(i).Perimeter];
                end
            end
            


        end
 
        
        % =================================================================
        %> @brief Refine the position of imfindcircle based detected Dots
        % using regionprops, take care that some Dots may be detected
        % double dots usign imfindcircles
        %>
        %> @param Obj       Own object
        %> @param Dots      All dot list
        %> @param Img       Image array to check the color information
        %> @param Size      Size of image [rows, columns]
        %> @retval Dots     Remaining Dots without left and right dot
        % =================================================================
        function [Dots] = RefineDotsPositions1 (Obj, Dots, Img, Size, Debug)
        
            
            %Dots = Dots(:,1:2);
            Dots(:, 5:6) = 0; % Assigning empty column for later Area and Perimeter assignment. Dots which dont satisfy the later conditions will keep the initial value, i.e. 0.
            DotsFloor = floor(Dots);

            
            for iDots = 1: size(Dots,1)            
                %rectangle('Position',[Dots(iDots,1)-Obj.BorderThreshold,...
                %                      Dots(iDots,2)-Obj.BorderThreshold,...
                %                      2*Obj.BorderThreshold,2*Obj.BorderThreshold]); 
                roundingDiff = Dots(iDots,1:2) - DotsFloor(iDots,1:2);
                
                img = Img(DotsFloor(iDots,2)-Obj.BorderThreshold:DotsFloor(iDots,2)+Obj.BorderThreshold,...
                          DotsFloor(iDots,1)-Obj.BorderThreshold:DotsFloor(iDots,1)+Obj.BorderThreshold);
                bw = ~im2bw(img,graythresh(img));         
                CC_Dots = regionprops(bw, 'Centroid', 'Area', 'BoundingBox', 'Perimeter' );
                newDots = [];
                for iRegion=1:size(CC_Dots,1)
                    x1 = Obj.BorderThreshold;
                    y1 = Obj.BorderThreshold;
                    x2 = CC_Dots(iRegion).Centroid(1);
                    y2 = CC_Dots(iRegion).Centroid(2);
                    d = sqrt((x2-x1)^2+(y2-y1)^2); % Trying to find out the region which is the center. Just to avoid the situation when a small portion of adjoining dot is visible.
                    if (d<5) % There might be more regions detected due to adjoining Dots visible part. So keep only center Dot.
                        newDots = [newDots; CC_Dots(iRegion).Centroid CC_Dots(iRegion).Area CC_Dots(iRegion).Perimeter]; % BoundingBox is not needed
%                       newDots = [newDots; CC_Dots(iRegion).Centroid CC_Dots(iRegion).Area CC_Dots(iRegion).BoundingBox CC_Dots(iRegion).Perimeter]; %
                    end
                end
                if(size(newDots,1)~=0) % In case the Dot is not detected properly in this step
                    refineShift = [newDots(1)-Obj.BorderThreshold-1, newDots(2)-Obj.BorderThreshold-1] - roundingDiff;
                    Dots(iDots, 1:2) = Dots(iDots, 1:2) + refineShift;
                    Dots(iDots, 5:6) = newDots(3:4);
                end
                showInBetween = 0;
                if(showInBetween)
                    figure(10)
                    pause(0.5)
                    imshow(bw)                
                    hold on, plot(newDots(1), newDots(2), 'r.');
                    hold on, plot(size(img,1)/2, size(img,2)/2, 'b.');
                    figure(11)
                    imshow(img)
                
                end
                
            
            end
            % unique will remove one Dot detected as double dots in imfindcircles
            doubleDots1 = size(Dots,1);
            Dots = unique(Dots,'rows');
            doubleDots2 = size(Dots,1);
            %if (Debug == 1)
                fprintf(1,'\nNumber of double dots occurances (RefineDotsPositions1): %d', doubleDots1-doubleDots2);
            %end
            
        end
        
        % =================================================================
        %> @brief Check if still some double dots are there even after
        %> Dots = unique(Dots,'rows');
        %>
        %> @param Obj       Own object
        %> @param Dots      All dot list
        %> @param Img       Image array to check the color information
        %> @param Size      Size of image [rows, columns]
        %> @retval Dots     Remaining Dots without left and right dot
        % =================================================================
        function [Dots] = RefineDotsPositions2 (Obj, Dots, Img, Size, Debug)
            
            if (Debug == 1)
                hold on, plot (Dots(:,1), Dots(:,2), 'go');
            end
            
            for iDots = 1: size(Dots,1)
    
                for jDots = iDots+1: size(Dots,1)   
                    x1 = Dots(iDots, 1);
                    y1 = Dots(iDots, 2);
                    x2 = Dots(jDots, 1);
                    y2 = Dots(jDots, 2);
                    d = sqrt((x2-x1)^2+(y2-y1)^2); % Trying to find out the if some double Dots are still there
                    if (d<11) % just in case RefineDotsPositions1 was not sucessful as Dots were somehow overlapping but not exactly
                        if (Debug == 1)
                            hold on, plot(Dots(iDots,1), Dots(iDots,2), 'r+', 'Markersize', 15);
                            hold on, plot(Dots(jDots,1), Dots(jDots,2), 'bx', 'Markersize', 15);
                        end
                        %Dots(iDots,:)
                        %Dots(jDots,:)
                        if(Dots(iDots, 5) == 0)
                            Dots(iDots, :) = Dots(jDots, :);
                        end
                        if(Dots(jDots, 5) == 0)
                            Dots(jDots, :) = Dots(iDots, :);
                        end
                        if(Dots(iDots, 5) ~= 0 && Dots(jDots, 5) ~= 0 && Dots(iDots, 5) < Dots(jDots, 5))
                            Dots(iDots, :) = Dots(jDots, :);
                        end
                        if(Dots(iDots, 5) ~= 0 && Dots(jDots, 5) ~= 0 && Dots(jDots, 5) < Dots(iDots, 5))
                            Dots(jDots, :) = Dots(iDots, :);
                        end
                        if(Dots(iDots, 5) ~= 0 && Dots(jDots, 5) ~= 0 && Dots(jDots, 5) == Dots(iDots, 5))
                            Dots(jDots, :) = Dots(iDots, :); % In this case its irrelevant which Dot is rejected 
                        end
                        
                    end
                end
                
            end
            
            % unique will remove one Dot detected as double dots in imfindcircles
            doubleDots1 = size(Dots,1);
            Dots = unique(Dots,'rows');
            doubleDots2 = size(Dots,1);
            if (Debug == 1)
                hold on, plot (Dots(:,1), Dots(:,2), 'g+');
            end
            %if (Debug == 1)
                fprintf(1,'\nNumber of double dots occurances (RefineDotsPositions2): %d', doubleDots1-doubleDots2);
            %end
            
        end
        
        
        
        % =================================================================
        %> @brief Filter out other calibration dots which might be wrongly
        %  detected due to errors in image processing
        %>
        %> @param Obj       Own object
        %> @param Dots      All dot list
        %> @param Img       Image array to check the color information
        %> @param Size      Size of image [rows, columns]
        %> @retval Dots     Remaining Dots without left and right dot
        % =================================================================
        function [Dots] = DetectFilterOtherDots (Obj, Img, Size, Debug)
%        function [Dots] = DetectFilterOtherDots (Obj, Dots, Img, Size, Debug)
            
            Circular_Hough_Transform_Based = 1;

            if(Circular_Hough_Transform_Based)
                Img1 = Img;   
                %Img1 = rgb2gray(Img1);
                Img1 = medfilt2(rgb2gray(Img1), [floor(Obj.median_filter_size) floor(Obj.median_filter_size)]);

                for i = Obj.RectMacBethChart(1):Obj.RectMacBethChart(1)+Obj.RectMacBethChart(3)
                    for j = Obj.RectMacBethChart(2):Obj.RectMacBethChart(2)+Obj.RectMacBethChart(4)    
                            Img1(j,i,1) = Obj.MacBethChart_mask_value(1);
                            % (j,i,2) and (j,i,3) commented below as
                            % already converted into grayscale
                            %Img1(j,i,2) = Obj.MacBethChart_mask_value(2);
                            %Img1(j,i,3) = Obj.MacBethChart_mask_value(3);
                            %for ci = 1:size(Img,3)
                            %    Img(j,i,ci) = 255;
                            %end        
                    end
                end
                %Img1 = Img;    
                if (Debug == 1)
                    imshow(Img);
                end
                % Default 'Method' is 'PhaseCode'
                % It detects dots close to Dots detection using regionprops
                [centers, radii, metric] = imfindcircles(Img1, Obj.Radius_range_imfindcircles, 'ObjectPolarity','dark','EdgeThreshold',Obj.EdgeThreshold, 'Method', 'PhaseCode');
                %[centers, radii, metric] = imfindcircles(Img1, Obj.Radius_range_imfindcircles, 'ObjectPolarity','dark', 'Method', 'PhaseCode');
                % 'TwoStage' method has much more difference to regionprops
                %[centers, radii, metric] = imfindcircles(Img1,[1 5], 'ObjectPolarity','dark','EdgeThreshold',0.2, 'Method', 'TwoStage'); % a lot 
                
                if (Debug == 1)
                    hold on
                    viscircles(centers, radii,'EdgeColor','m' );
                    hold on, plot (centers(:,1), centers(:,2), 'm.');
                end
                
                Dots = [centers ...
                        radii ...       
                        metric ...      
                        ];
                    
                Dots = Dots(find((Dots(:,2)>Obj.BorderThreshold+1           &...   % Filtering the dots which are very close to the border
                                  Dots(:,2)<Size(1)-(Obj.BorderThreshold+1) &...
                                  Dots(:,1)>Obj.BorderThreshold+1           &...
                                  Dots(:,1)<Size(2)-Obj.BorderThreshold+1   )),:);     
                              
                              
                              
    
            else
                      
                Dots = Dots(find((Dots(:,3)>Obj.DotAreaThreshold(1)        & ...   % Filtering out all other
                                  Dots(:,3)<Obj.DotAreaThreshold(2)        & ...   % non required dots
                                  Dots(:,8)<100                             )),:); % Perimeter of the Dots cannnot be more than 100             
                Dots = Dots(find((Dots(:,8)<100)),:); % Perimeter of the Dot cannnot be more than 100

            end
            
            %size(Dots)
            % (1) Centroid_x (2) Centroid_y (3) Area (4) BB ul_corner_x (5) BB ul_corner y (6) BB x_width (7) BB y_width (8) Perimeter
            % 8. ???
            
                     
%            if(Debug)
%             for iDot = 1:size(Dots,1)
%                 if(Dots(iDot,3) >100)
%                     hold on, text(2+Dots(iDot,1) ,2+Dots(iDot,2) , num2str(Dots(iDot,3)), 'FontSize', 7,  'Color', 'm', 'rotation', 40 ) 
%                 end
%             end
%           end

            if(Debug)
                hold on, text(2+Dots(:,1) ,2+Dots(:,2) , num2str(Dots(:,4)), 'FontSize', 7,  'Color', 'm', 'rotation', 40 ) 
            end

        end
        
        % =================================================================
        %> @brief Refine the position of Haugh transform based detected Dot
        %>        using regionprops method
        %>
        %> @param Obj       Own object
        %> @param Img       Image array to check the color information
        %> @param intrinsicBox2D      Dots positions from Haugh transform based method
        %> @param calib_config        Structure defined by operator for controling image processing
        %> @retval intrinsicBox2D     Refined Dots positions
        % =================================================================
        function [intrinsicBox2D] = RefineDotsPositions0 (Obj, Img, intrinsicBox2D)


            intrinsicBox2DFloor = floor(intrinsicBox2D);
            
            for iDots = 1: size(intrinsicBox2D,1)            
%                 rectangle('Position',[intrinsicBox2D(iDots,1)-Obj.BorderThreshold,...
%                                       intrinsicBox2D(iDots,2)-Obj.BorderThreshold,...
%                                       2*Obj.BorderThreshold,2*Obj.BorderThreshold]); 
                roundingDiff = intrinsicBox2D(iDots,:) - intrinsicBox2DFloor(iDots,:);
                
                img = Img(intrinsicBox2DFloor(iDots,2)-Obj.BorderThreshold:intrinsicBox2DFloor(iDots,2)+Obj.BorderThreshold,...
                          intrinsicBox2DFloor(iDots,1)-Obj.BorderThreshold:intrinsicBox2DFloor(iDots,1)+Obj.BorderThreshold);
                bw = ~im2bw(img,graythresh(img));         
                CC_Dots = regionprops(bw, 'Centroid', 'Area', 'BoundingBox', 'Perimeter' );
                Dots = [];
                for iRegion=1:size(CC_Dots,1)
                    x1 = Obj.BorderThreshold;
                    y1 = Obj.BorderThreshold;
                    x2 = CC_Dots(iRegion).Centroid(1);
                    y2 = CC_Dots(iRegion).Centroid(2);
                    d = sqrt((x2-x1)^2+(y2-y1)^2); % Trying to find out the region which is the center. Just to avoid the situation when a small portion of adjoining dot is visible.
                    if (d<5) % There might be more regions detected due to adjoining Dots visible part. So keep only center Dot.
                        Dots = [Dots; CC_Dots(iRegion).Centroid CC_Dots(iRegion).Area CC_Dots(iRegion).BoundingBox CC_Dots(iRegion).Perimeter]; %
                    end
                end
                if(size(Dots,1)~=0) % In case the Dot is not detected properly in this step
                    refineShift = [Dots(1)-Obj.BorderThreshold-1, Dots(2)-Obj.BorderThreshold-1] - roundingDiff;
                    intrinsicBox2D(iDots, :) = intrinsicBox2D(iDots, :) + refineShift;
                end
                
                showInBetween = 0;
                if(showInBetween)
                    figure(10)
                    pause(0.5)
                    imshow(bw)                
                    hold on, plot(Dots(1), Dots(2), 'r.');
                    hold on, plot(size(img,1)/2, size(img,2)/2, 'b.');
                    figure(11)
                    imshow(img)
                end
                
            end
            
            

        
        end

        
                    
        
        % =================================================================
        %> @brief Filter out center dots (left and right dots)
        %>
        %> @param Obj       Own object
        %> @param Dots      All dot list
        %> @param Size      Size of image [rows, columns]
        %> @retval Left     Left dot
        %> @retval Right    Right dot
        %> @retval Dots     Remaining Dots without left and right dot
        % =================================================================
        function [Left, Right, Dots] = DetectFilterCenterDots (Obj, Dots, Size)
            

            

            Left = Dots(find((Dots(:,3)>=Obj.CenterDotsAreaThreshold(1) & ...
                              Dots(:,3)<=Obj.CenterDotsAreaThreshold(2) & ...
                              Dots(:,1)<Size(2)/2                       & ...  % Looking for the dot on left side of center
                              Dots(:,1)>Size(2)/2 - (128)               & ...  % which cannot be far far left from center
                              Dots(:,2)>Size(1)/2 - (64)                & ...  % has to be somewhere close below to center 
                              Dots(:,2)<Size(1)/2 + (64)                & ...  % or has to be somewhere close above to center 
                              Dots(:,8)<100                             )),:); % with perimeter less than 100 pixels.
                      
            %hold on, text(2+Left(1) ,2+Left(2) , num2str(Left(3)), 'FontSize', 7,  'Color', 'm', 'rotation', 40 ) 

            Right = Dots(find((Dots(:,3)>=Obj.CenterDotsAreaThreshold(1)& ...
                               Dots(:,3)<=Obj.CenterDotsAreaThreshold(2)& ...
                               Dots(:,1)>Size(2)/2                      & ...  % Looking for the dot on right side of center
                               Dots(:,1)<Size(2)/2 + (128+0)            & ...  % which cannot be far far right from center
                               Dots(:,2)>Size(1)/2 - (64)               & ...  % has to be somewhere close below to center 
                               Dots(:,2)<Size(1)/2 + (64)               & ...  % or has to be somewhere close above to center 
                               Dots(:,8)<100                            )),:); % with perimeter less than 100 pixels.
            
            %hold on, text(2+Right(1) ,2+Right(2) , num2str(Right(3)), 'FontSize', 7,  'Color', 'm', 'rotation', 40 ) 
              
            %Left
            %Right
            
            % Removing Left and Right central dots from further search
            Dots = setdiff(Dots, Left, 'rows');
            Dots = setdiff(Dots, Right, 'rows');
                           

        end
       
       
        % =================================================================
        %> @brief Generate a virtual grid on MacBeth chart 
        %>
        %> @param Obj       Own object
        %> @param Left      Left dot 
        %> @param Right     Right dot 
        %> @param Debug     Show debug screen
        %> @retval GridMacbeth Structure containing virtual points on Macbeth
        % =================================================================
        function [GridMacbeth] = DetectGridMacbeth (Obj, Left, Right, Debug)
 
            GridMacbeth.Left = Left(1:2);
            GridMacbeth.Right = Right(1:2);
            
            GridMacbeth.Center = [(GridMacbeth.Left(1) + GridMacbeth.Right(1))/2 , (GridMacbeth.Left(2) + GridMacbeth.Right(2))/2];
            
            %Get an imaginary approximate MacBeth Pattern
            theta = atan2(GridMacbeth.Right(2)-GridMacbeth.Left(2),GridMacbeth.Left(1)-GridMacbeth.Right(1));
            dp = [GridMacbeth.Left(1), GridMacbeth.Left(2)]- [GridMacbeth.Center(1), GridMacbeth.Center(2)];
            H = hypot(dp(1),dp(2)) - 10; 
            % Making arbitrarily 10 pixels smaller to keep it properly inside the MacBeth Pattern

            % Following four points define a rectangle just inside the
            % boundary of MacBeth pattern
            GridMacbeth.LowerLeft = [GridMacbeth.Left(1)-H*sin(theta) GridMacbeth.Left(2)-H*cos(theta)];
            GridMacbeth.UpperLeft = [GridMacbeth.Left(1)+H*sin(theta) GridMacbeth.Left(2)+H*cos(theta)];
            GridMacbeth.LowerRight = [GridMacbeth.Right(1)-H*sin(theta) GridMacbeth.Right(2)-H*cos(theta)];
            GridMacbeth.UpperRight = [GridMacbeth.Right(1)+H*sin(theta) GridMacbeth.Right(2)+H*cos(theta)];

            h = 2.5*H/5; % h = 3*H/5;
            % Following points lie on a line through LowerLeft and UpperLeft
            GridMacbeth.LowerMidLeft = [GridMacbeth.Left(1)-h*sin(theta) GridMacbeth.Left(2)-h*cos(theta)];
            GridMacbeth.UpperMidLeft = [GridMacbeth.Left(1)+h*sin(theta) GridMacbeth.Left(2)+h*cos(theta)];
            % Following points lie on a line through LowerRight and UpperRight
            GridMacbeth.LowerMidRight = [GridMacbeth.Right(1)-h*sin(theta) GridMacbeth.Right(2)-h*cos(theta)];
            GridMacbeth.UpperMidRight = [GridMacbeth.Right(1)+h*sin(theta) GridMacbeth.Right(2)+h*cos(theta)];

                        
            h = 1.25*H/5; % h = 3*H/5; % onefourth
            % Following points lie on a line through LowerLeft and UpperLeft
            GridMacbeth.LowerMidLeft_onefourth = [GridMacbeth.Left(1)-h*sin(theta) GridMacbeth.Left(2)-h*cos(theta)];
            GridMacbeth.UpperMidLeft_onefourth = [GridMacbeth.Left(1)+h*sin(theta) GridMacbeth.Left(2)+h*cos(theta)];
            % Following points lie on a line through LowerRight and UpperRight
            GridMacbeth.LowerMidRight_onefourth = [GridMacbeth.Right(1)-h*sin(theta) GridMacbeth.Right(2)-h*cos(theta)];
            GridMacbeth.UpperMidRight_onefourth = [GridMacbeth.Right(1)+h*sin(theta) GridMacbeth.Right(2)+h*cos(theta)];

            h = 3.75*H/5; % h = 3*H/5; % threefourth
            % Following points lie on a line through LowerLeft and UpperLeft
            GridMacbeth.LowerMidLeft_threefourth = [GridMacbeth.Left(1)-h*sin(theta) GridMacbeth.Left(2)-h*cos(theta)];
            GridMacbeth.UpperMidLeft_threefourth = [GridMacbeth.Left(1)+h*sin(theta) GridMacbeth.Left(2)+h*cos(theta)];
            % Following points lie on a line through LowerRight and UpperRight
            GridMacbeth.LowerMidRight_threefourth = [GridMacbeth.Right(1)-h*sin(theta) GridMacbeth.Right(2)-h*cos(theta)];
            GridMacbeth.UpperMidRight_threefourth = [GridMacbeth.Right(1)+h*sin(theta) GridMacbeth.Right(2)+h*cos(theta)];

            % Upper and lower central dot, above and below the center dot
            GridMacbeth.Upper = [(GridMacbeth.UpperLeft(1) + GridMacbeth.UpperRight(1))/2 , (GridMacbeth.UpperLeft(2) + GridMacbeth.UpperRight(2))/2];
            GridMacbeth.Lower = [(GridMacbeth.LowerLeft(1) + GridMacbeth.LowerRight(1))/2 , (GridMacbeth.LowerLeft(2) + GridMacbeth.LowerRight(2))/2];

            
                        
            % Following points lie on a line through LowerLeft and LowerRight
            GridMacbeth.LowerLeftMid = [(GridMacbeth.Lower(1) + GridMacbeth.LowerLeft(1))/2 , (GridMacbeth.Lower(2) + GridMacbeth.LowerLeft(2))/2];
            GridMacbeth.LowerRightMid = [(GridMacbeth.Lower(1) + GridMacbeth.LowerRight(1))/2 , (GridMacbeth.Lower(2) + GridMacbeth.LowerRight(2))/2];
            % Following points lie on a line through UpperLeft and UpperRight
            GridMacbeth.UpperLeftMid = [(GridMacbeth.Upper(1) + GridMacbeth.UpperLeft(1))/2 , (GridMacbeth.Upper(2) + GridMacbeth.UpperLeft(2))/2];
            GridMacbeth.UpperRightMid = [(GridMacbeth.Upper(1) + GridMacbeth.UpperRight(1))/2 , (GridMacbeth.Upper(2) + GridMacbeth.UpperRight(2))/2];

            % Following points lie on a line through LowerLeft and LowerRight
            GridMacbeth.LowerLeft_onefourth = [(GridMacbeth.Lower(1) + GridMacbeth.LowerLeftMid(1))/2 , (GridMacbeth.Lower(2) + GridMacbeth.LowerLeftMid(2))/2];
            GridMacbeth.LowerRight_onefourth = [(GridMacbeth.Lower(1) + GridMacbeth.LowerRightMid(1))/2 , (GridMacbeth.Lower(2) + GridMacbeth.LowerRightMid(2))/2];
            % Following points lie on a line through UpperLeft and UpperRight
            GridMacbeth.UpperLeft_onefourth = [(GridMacbeth.Upper(1) + GridMacbeth.UpperLeftMid(1))/2 , (GridMacbeth.Upper(2) + GridMacbeth.UpperLeftMid(2))/2];
            GridMacbeth.UpperRight_onefourth = [(GridMacbeth.Upper(1) + GridMacbeth.UpperRightMid(1))/2 , (GridMacbeth.Upper(2) + GridMacbeth.UpperRightMid(2))/2];

            % Following points lie on a line through LowerLeft and LowerRight
            someNumber = 5;
            GridMacbeth.LowerLeft_threefourth = [(GridMacbeth.LowerLeft(1) + GridMacbeth.LowerLeftMid(1))/2.05+ someNumber, (GridMacbeth.LowerLeft(2) + GridMacbeth.LowerLeftMid(2))/2];
            GridMacbeth.LowerRight_threefourth = [(GridMacbeth.LowerRight(1) + GridMacbeth.LowerRightMid(1))/1.96-someNumber, (GridMacbeth.LowerRight(2) + GridMacbeth.LowerRightMid(2))/2];
            % Following points lie on a line through UpperLeft and UpperRight
            GridMacbeth.UpperLeft_threefourth = [(GridMacbeth.UpperLeft(1) + GridMacbeth.UpperLeftMid(1))/2.05+someNumber , (GridMacbeth.UpperLeft(2) + GridMacbeth.UpperLeftMid(2))/2];
            GridMacbeth.UpperRight_threefourth = [(GridMacbeth.UpperRight(1) + GridMacbeth.UpperRightMid(1))/1.96-someNumber , (GridMacbeth.UpperRight(2) + GridMacbeth.UpperRightMid(2))/2];

            
            
            %%%%dd = 1*(GridMacbeth.Center(1) - GridMacbeth.Left(1))/2; % dd = 1*(GridMacbeth.Center(1) - GridMacbeth.Left(1))/6;
            % Following points lie on a line through LowerLeft and LowerRight
            %%%%GridMacbeth.LowerLeftMid  = [dd+GridMacbeth.Left(1)-H*sin(theta)  GridMacbeth.Left(2)-H*cos(theta)];
            %%%%GridMacbeth.LowerRightMid = [-dd+GridMacbeth.Right(1)-H*sin(theta) GridMacbeth.Right(2)-H*cos(theta)];
            % Following points lie on a line through UpperLeft and UpperRight
            %%%%GridMacbeth.UpperLeftMid  = [dd+GridMacbeth.Left(1)+H*sin(theta) GridMacbeth.Left(2)+H*cos(theta)];
            %%%%GridMacbeth.UpperRightMid = [-dd+GridMacbeth.Right(1)+H*sin(theta) GridMacbeth.Right(2)+H*cos(theta)];

        
            % Show debug if set
            if (Debug == 1)
                hold on
                plot(GridMacbeth.Left(1), GridMacbeth.Left(2), 'mo', 'Markersize', 15);
                plot(GridMacbeth.Right(1), GridMacbeth.Right(2), 'co', 'Markersize', 15);
                plot(GridMacbeth.Center(1), GridMacbeth.Center(2), 'r*');

                % Upper and lower central doty, above and below the center dot
                plot(GridMacbeth.Upper(1), GridMacbeth.Upper(2), 'r+');
                plot(GridMacbeth.Lower(1), GridMacbeth.Lower(2), 'r+');

                % Following four points define a rectangle just inside the
                % boundary of MacBeth pattern
                plot(GridMacbeth.LowerLeft(1), GridMacbeth.LowerLeft(2), 'm+');
                plot(GridMacbeth.UpperLeft(1), GridMacbeth.UpperLeft(2), 'm+');
                plot(GridMacbeth.LowerRight(1), GridMacbeth.LowerRight(2), 'c+');
                plot(GridMacbeth.UpperRight(1), GridMacbeth.UpperRight(2), 'c+');

                % Following points lie on a line through LowerLeft and UpperLeft
                plot(GridMacbeth.LowerMidLeft(1), GridMacbeth.LowerMidLeft(2), 'yo');
                plot(GridMacbeth.UpperMidLeft(1), GridMacbeth.UpperMidLeft(2), 'yo');
                % Following points lie on a line through LowerRight and UpperRight
                plot(GridMacbeth.LowerMidRight(1), GridMacbeth.LowerMidRight(2), 'yo');
                plot(GridMacbeth.UpperMidRight(1), GridMacbeth.UpperMidRight(2), 'yo');

                % Following points lie on a line through LowerLeft and UpperLeft
                plot(GridMacbeth.LowerMidLeft_onefourth(1), GridMacbeth.LowerMidLeft_onefourth(2), 'y+');
                plot(GridMacbeth.UpperMidLeft_onefourth(1), GridMacbeth.UpperMidLeft_onefourth(2), 'y+');
                % Following points lie on a line through LowerRight and UpperRight
                plot(GridMacbeth.LowerMidRight_onefourth(1), GridMacbeth.LowerMidRight_onefourth(2), 'y+');
                plot(GridMacbeth.UpperMidRight_onefourth(1), GridMacbeth.UpperMidRight_onefourth(2), 'y+');

                % Following points lie on a line through LowerLeft and UpperLeft
                plot(GridMacbeth.LowerMidLeft_threefourth(1), GridMacbeth.LowerMidLeft_threefourth(2), 'y.');
                plot(GridMacbeth.UpperMidLeft_threefourth(1), GridMacbeth.UpperMidLeft_threefourth(2), 'y.');
                % Following points lie on a line through LowerRight and UpperRight
                plot(GridMacbeth.LowerMidRight_threefourth(1), GridMacbeth.LowerMidRight_threefourth(2), 'y.');
                plot(GridMacbeth.UpperMidRight_threefourth(1), GridMacbeth.UpperMidRight_threefourth(2), 'y.');
                
                % Following points lie on a line through LowerLeft and LowerRight
                plot(GridMacbeth.LowerLeftMid(1), GridMacbeth.LowerLeftMid(2), 'mo');
                plot(GridMacbeth.LowerRightMid(1), GridMacbeth.LowerRightMid(2), 'co');
                % Following points lie on a line through UpperLeft and UpperRight
                plot(GridMacbeth.UpperLeftMid(1), GridMacbeth.UpperLeftMid(2), 'mo');
                plot(GridMacbeth.UpperRightMid(1), GridMacbeth.UpperRightMid(2), 'co');
                
                % Following points lie on a line through LowerLeft and LowerRight
                plot(GridMacbeth.LowerLeft_onefourth (1), GridMacbeth.LowerLeft_onefourth (2), 'm.');
                plot(GridMacbeth.LowerRight_onefourth (1), GridMacbeth.LowerRight_onefourth (2), 'c.');
                % Following points lie on a line through UpperLeft and UpperRight
                plot(GridMacbeth.UpperLeft_onefourth (1), GridMacbeth.UpperLeft_onefourth (2), 'm.');
                plot(GridMacbeth.UpperRight_onefourth (1), GridMacbeth.UpperRight_onefourth (2), 'c.');

                % Following points lie on a line through LowerLeft and LowerRight
                plot(GridMacbeth.LowerLeft_threefourth (1), GridMacbeth.LowerLeft_threefourth (2), 'm*');
                plot(GridMacbeth.LowerRight_threefourth (1), GridMacbeth.LowerRight_threefourth (2), 'c*');
                % Following points lie on a line through UpperLeft and UpperRight
                plot(GridMacbeth.UpperLeft_threefourth (1), GridMacbeth.UpperLeft_threefourth (2), 'm*');
                plot(GridMacbeth.UpperRight_threefourth (1), GridMacbeth.UpperRight_threefourth (2), 'c*');

            end
            
        end


        % =================================================================
        %> @brief Filter remaining dots Dots to proper intrinsicBox2D order
        %>
        %> @todo Missing dots in between a rib 
        %>
        %> @param Obj       Own object
        %> @param Dots      
        %> @param GridMacbeth Structure containing virtual points on Macbeth
        %> @param Size      Size of image [rows, columns]
        %> @param Debug     Show debug screen
        %> @retval intrinsicBox2D Center dot image location 
        %> @retval segments Number of dots detected in a particular segment
        %>         Upper
        %>         1 0 2
        %>         | | |
        %>         | | |
        %> Left1---      ---Right1
        %> Left0---      ---Right0
        %> Left2---      ---Right2
        %>         | | |
        %>         | | |
        %>         1 0 2
        %>         Lower
        %> Order of segments:
        %> Left0, Right0, Left1, Right1, Left2, Right2, Upper0, Lower0, Upper1, Lower1, Upper2, Lower2.
        % =================================================================
        function [intrinsicBox2D, segments] = DetectOrderedDots (Obj, Dots, GridMacbeth, Size, Debug)
 
            Left            = GridMacbeth.Left;
            Right           = GridMacbeth.Right;
            Center          = GridMacbeth.Center;
            LowerLeft       = GridMacbeth.LowerLeft;
            UpperLeft       = GridMacbeth.UpperLeft;
            LowerRight      = GridMacbeth.LowerRight;
            UpperRight      = GridMacbeth.UpperRight;
            LowerMidLeft    = GridMacbeth.LowerMidLeft;
            UpperMidLeft    = GridMacbeth.UpperMidLeft;
            LowerMidRight   = GridMacbeth.LowerMidRight;
            UpperMidRight   = GridMacbeth.UpperMidRight;
            
            LowerMidLeft_onefourth    = GridMacbeth.LowerMidLeft_onefourth;
            UpperMidLeft_onefourth    = GridMacbeth.UpperMidLeft_onefourth;
            LowerMidRight_onefourth   = GridMacbeth.LowerMidRight_onefourth;
            UpperMidRight_onefourth   = GridMacbeth.UpperMidRight_onefourth;
            LowerMidLeft_threefourth    = GridMacbeth.LowerMidLeft_threefourth;
            UpperMidLeft_threefourth    = GridMacbeth.UpperMidLeft_threefourth;
            LowerMidRight_threefourth   = GridMacbeth.LowerMidRight_threefourth;
            UpperMidRight_threefourth   = GridMacbeth.UpperMidRight_threefourth;

            LowerLeft_onefourth = GridMacbeth.LowerLeft_onefourth;
            LowerRight_onefourth = GridMacbeth.LowerRight_onefourth;
            UpperLeft_onefourth = GridMacbeth.UpperLeft_onefourth;
            UpperRight_onefourth = GridMacbeth.UpperRight_onefourth;
            LowerLeft_threefourth = GridMacbeth.LowerLeft_threefourth;
            LowerRight_threefourth = GridMacbeth.LowerRight_threefourth;
            UpperLeft_threefourth = GridMacbeth.UpperLeft_threefourth;
            UpperRight_threefourth = GridMacbeth.UpperRight_threefourth;
                
            LowerLeftMid    = GridMacbeth.LowerLeftMid;
            LowerRightMid   = GridMacbeth.LowerRightMid;
            UpperLeftMid    = GridMacbeth.UpperLeftMid;
            UpperRightMid   = GridMacbeth.UpperRightMid;
            Upper           = GridMacbeth.Upper;
            Lower           = GridMacbeth.Lower;
            

            Dots_temp1 = Dots(:,1:2);
            Dots_temp1(:,3) = 0;
%             if(size(Dots,2)>4)
%                 Dots_temp2 = Dots(:,4:8);
%             else
%                 Dots_temp2 = Dots(:,3);
%             end
            
            % add angle and distance to Dots
            Dots = [Dots_temp1 ...
                    atan2d((Dots(:,2)-Center(2)), (Dots(:,1)-Center(1))) ...
                    sqrt((Dots(:,1)-Center(1)).^2 + (Dots(:,2)-Center(2)).^2) ...
                    ];
%                   Dots_temp2];
            

            %Getting left and right center lines, named as 0 lines
            Q1 = Left(1:2); Q1 = Q1';
            Q2 = Right(1:2); Q2 = Q2';
            indexLeft = 1;
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) < Size(2)/2 )
                        DotsLeft0(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                    if ( Dots(i,1) > Size(2)/2)
                        DotsRight0(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            
            % Removing DotsLeft0 and DotsRight0 from further search
            Dots = setdiff(Dots, DotsLeft0, 'rows');
            Dots = setdiff(Dots, DotsRight0, 'rows');
            %Getting left and right upper center lines, named as 1 lines
            % Left first
            Q1 = UpperMidRight(1:2); Q1 = Q1';%%%
            Q2 = UpperMidLeft_threefourth(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                
                
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) < UpperLeft(1))
                        DotsLeft1(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end         
            % Removing DotsLeft1 from further search
            Dots = setdiff(Dots, DotsLeft1, 'rows');
            % Right now
            Q1 = UpperMidLeft(1:2); Q1 = Q1';
            Q2 = UpperMidRight_threefourth(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) > UpperRight(1))
                        DotsRight1(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsRight1 from further search
            Dots = setdiff(Dots, DotsRight1, 'rows');
            %Getting left and right lower center lines, named as 2 lines
            % Left first
            Q1 = LowerMidRight(1:2); Q1 = Q1';
            Q2 = LowerMidLeft_threefourth(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);  
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) < LowerLeft(1))
                        DotsLeft2(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
          
            % Removing DotsLeft2 from further search
            Dots = setdiff(Dots, DotsLeft2, 'rows');
            % Right now
            Q1 = LowerMidLeft(1:2); Q1 = Q1';
            Q2 = LowerMidRight_threefourth(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) > LowerRight(1))
                        DotsRight2(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsRight2 from further search
            Dots = setdiff(Dots, DotsRight2, 'rows');

            %Getting upper and lower center lines, named as 0 lines
            Q1 = Upper(1:2); Q1 = Q1';
            Q2 = Lower(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexUpper = 1;
            indexLower = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) < Size(1)/2)
                        DotsUpper0(indexUpper, :) = Dots(i,:);
                        indexUpper = indexUpper+1;
                    end
                    if ( Dots(i,2) > Size(1)/2)
                        DotsLower0(indexLower, :) = Dots(i,:);
                        indexLower = indexLower+1;
                    end

                end
            end
            % Removing DotsUpper0 and DotsLower0 from further search
            Dots = setdiff(Dots, DotsUpper0, 'rows');
            Dots = setdiff(Dots, DotsLower0, 'rows');
            %Getting upper and lower, left lines, named as 1 lines
            % Upper first
            Q1 = UpperLeft_threefourth(1:2); Q1 = Q1';
            Q2 = LowerLeftMid(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) < UpperLeft(2))
                        DotsUpper1(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
            % Removing DotsUpper1 from further search
            Dots = setdiff(Dots, DotsUpper1, 'rows');
            % Lower now
            Q1 = LowerLeft_threefourth(1:2); Q1 = Q1';
            Q2 = UpperLeftMid(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) > LowerLeft(2))
                        DotsLower1(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsLower1 from further search
            Dots = setdiff(Dots, DotsLower1, 'rows');
            %Getting upper and lower, right lines, named as 2 lines
            % Upper first
            Q1 = UpperRight_threefourth(1:2); Q1 = Q1';
            Q2 = LowerRightMid(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) < UpperLeft(2))
                        DotsUpper2(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
            % Removing DotsUpper2 from further search
            Dots = setdiff(Dots, DotsUpper2, 'rows');
            % Lower now
            Q1 = LowerRight_threefourth(1:2); Q1 = Q1';
            Q2 = UpperRightMid(1:2); Q2 = Q2';
            if(Debug)
                line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            end
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) > LowerLeft(2))
                        DotsLower2(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsLower2 from further search
            Dots = setdiff(Dots, DotsLower2, 'rows'); % Not needed actually becuase it was the last search
          

            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % Sorting out according to distance from Center point
            DotsLeft0  = sortrows(DotsLeft0 ,5);
            DotsRight0 = sortrows(DotsRight0,5);
            DotsLeft1  = sortrows(DotsLeft1 ,5);
            DotsRight1 = sortrows(DotsRight1,5);
            DotsLeft2  = sortrows(DotsLeft2 ,5);
            DotsRight2 = sortrows(DotsRight2,5);
            %--------------------------------------------------------------
            DotsUpper0 = sortrows(DotsUpper0,5);
            DotsLower0 = sortrows(DotsLower0,5);
            DotsUpper1 = sortrows(DotsUpper1,5);
            DotsLower1 = sortrows(DotsLower1,5);
            DotsUpper2 = sortrows(DotsUpper2,5);
            DotsLower2 = sortrows(DotsLower2,5);
            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % Keep only the Maximum possible Dots
            if(size(DotsLeft0,1) > Obj.maxDotsLeftRight)
                DotsLeft0 = DotsLeft0(1:Obj.maxDotsLeftRight,:);
            end;% Keeping only the maximum possible dots
            if(size(DotsRight0,1) > Obj.maxDotsLeftRight)
                DotsRight0 = DotsRight0(1:Obj.maxDotsLeftRight,:);
            end;% Keeping only the maximum possible dots
            
            if(size(DotsLeft1,1) > Obj.maxDotsLeftRight)
                DotsLeft1 = DotsLeft1(1:Obj.maxDotsLeftRight,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsRight1,1) > Obj.maxDotsLeftRight)
                DotsRight1 = DotsRight1(1:Obj.maxDotsLeftRight,:);
            end % Keeping only the maximum possible dots

            if(size(DotsLeft2,1) > Obj.maxDotsLeftRight)
                DotsLeft2 = DotsLeft2(1:Obj.maxDotsLeftRight,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsRight2,1) > Obj.maxDotsLeftRight)
                DotsRight2 = DotsRight2(1:Obj.maxDotsLeftRight,:);
            end % Keeping only the maximum possible dots
            %--------------------------------------------------------------
            if(size(DotsUpper0,1) > Obj.maxDotsUpperLower)
                DotsUpper0 = DotsUpper0(1:Obj.maxDotsUpperLower,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsLower0,1) > Obj.maxDotsUpperLower)
                DotsLower0 = DotsLower0(1:Obj.maxDotsUpperLower,:);
            end % Keeping only the maximum possible dots

            if(size(DotsUpper1,1) > Obj.maxDotsUpperLower)
                DotsUpper1 = DotsUpper1(1:Obj.maxDotsUpperLower,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsLower1,1) > Obj.maxDotsUpperLower)
                DotsLower1 = DotsLower1(1:Obj.maxDotsUpperLower,:);
            end % Keeping only the maximum possible dots
            
            if(size(DotsUpper2,1) > Obj.maxDotsUpperLower)
                DotsUpper2 = DotsUpper2(1:Obj.maxDotsUpperLower,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsLower2,1) > Obj.maxDotsUpperLower)
                DotsLower2 = DotsLower2(1:Obj.maxDotsUpperLower,:);
            end % Keeping only the maximum possible dots
            %--------------------------------------------------------------
            %--------------------------------------------------------------
            
            
            
            
            

            if (Debug == 1)
                plot(DotsLeft0(:,1), DotsLeft0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsRight0(:,1), DotsRight0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsLeft1(:,1), DotsLeft1(:,2), 'co-', 'MarkerSize',8);
                plot(DotsRight1(:,1), DotsRight1(:,2), 'co-', 'MarkerSize',8);
                plot(DotsLeft2(:,1), DotsLeft2(:,2), 'go-', 'MarkerSize',8);
                plot(DotsRight2(:,1), DotsRight2(:,2), 'co-', 'MarkerSize',8);

                plot(DotsUpper0(:,1), DotsUpper0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsLower0(:,1), DotsLower0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsUpper1(:,1), DotsUpper1(:,2), 'mo-', 'MarkerSize',8);
                plot(DotsLower1(:,1), DotsLower1(:,2), 'co-', 'MarkerSize',8);
                plot(DotsUpper2(:,1), DotsUpper2(:,2), 'go-', 'MarkerSize',8);
                plot(DotsLower2(:,1), DotsLower2(:,2), 'mo-', 'MarkerSize',8);
            end




            segments = [size(DotsLeft0,1), size(DotsRight0,1), ...
                        size(DotsLeft1,1), size(DotsRight1,1), ...
                        size(DotsLeft2,1), size(DotsRight2,1), ...
                        size(DotsUpper0,1), size(DotsLower0,1),...
                        size(DotsUpper1,1), size(DotsLower1,1),...
                        size(DotsUpper2,1), size(DotsLower2,1),];
            intrinsicBox2D = [DotsLeft0(:,1:2); DotsRight0(:,1:2);...
                              DotsLeft1(:,1:2); DotsRight1(:,1:2);...
                              DotsLeft2(:,1:2); DotsRight2(:,1:2);...
                              DotsUpper0(:,1:2); DotsLower0(:,1:2);...
                              DotsUpper1(:,1:2); DotsLower1(:,1:2);...
                              DotsUpper2(:,1:2); DotsLower2(:,1:2)];

                         
        end
        
        
        

        
        % =================================================================
        %> @brief Get ideal grid position in camera image
        %>
        %> @param Obj       Own object
        %> @param Cam       Use camera model
        %> @retval DotsRef  Image pixel position of every ideal grid point
        % =================================================================
        function [DotsRef] = GetIdealGrid (Obj, Cam, Dots)
            % create 3d points of ref box
            P_3d = [0 0 750 1];
            RibPos = [0 0];
            
            for b=0:-30:-360
                for a=10:5:85
                    P_3d = [P_3d ; Obj.Radius*[sind(a)*cosd(b) sind(a)*sind(b) cosd(a)] 1];
                    RibPos = [ RibPos ; -b/30+1 a/5-1];
                end
            end
            DotsRef = Cam.world2image(P_3d');
            DotsRef = [DotsRef' RibPos];
            
            DotsRef2 = [];
            for iDot = 1:size(Dots,1)
                DotsRef2 = [DotsRef2 ; DotsRef(find(DotsRef(:,3)==Dots(iDot,6) & DotsRef(:,4)==Dots(iDot,7)),:)];             
            end
            DotsRef = DotsRef2;
        end


           

        % =================================================================
        %> @brief Get intrinsicBox3D from the 3D points measured with
        % Scan-reference software
        %>
        %> @param Obj       Own object
        %> @param segments  
        %> @param calib_config       calib_config used for defining lens
        %> @retval intrinsicBox3D  Image pixel position of every ideal grid point
        % =================================================================
        function intrinsicBox3D = Overlay3DDots (Obj, segments, calib_config)
            
           
            %segments = [17 17 17 17 17 17 14 14 14 14 14 14]
            %segments = [19 19 21 21 21 21 13 13 13 13 13 13];
            %segments = [18 18 18 18 18 18 14 14 14 14 14 14];
            
            fname = calib_config.scan_reference_obc_file;
     
% config %            
%             switch lens
%                 case 1
%                     fname = strcat('lens_identifier_backdoor_4063.obc');
%                     fprintf(1,'\nUsing 3D points for lens 4063');
%                 case 2
%                     fname = strcat('lens_identifier_backdoor_4075.obc');
%                     fprintf(1,'\nUsing 3D points for lens 4075');
%             end
% config %            
            

            
            Debug = 0;
            fid = fopen(fname);
            

            index = 1;
            while ~feof(fid)
                point = str2num(fscanf(fid, '%s\n', 1));
                x_pos = str2num(fscanf(fid, '%s\n', 1))- calib_config.roundtableOffset.x;
                y_pos = str2num(fscanf(fid, '%s\n', 1))- calib_config.roundtableOffset.y;
                z_pos = str2num(fscanf(fid, '%s\n', 1)) - calib_config.principal_plane_offset - calib_config.roundtableOffset.z;
                % z_pos is moved to compensate for the different principal
                % plane than measured plane
                % (-) calib_config.principal_plane_offset 
                % (-) roundtableOffset

                
                dump = fscanf(fid, '%s\n', 7); % Ignoring the last 7 columns in the .obc file
%               if(point > 1000 & point ~= 3023 & point ~= 2058) % We know that our points (uncoded markers) will have index number more than 1000
                if(point > 1000) % We know that our points (uncoded markers) will have index number more than 1000
                    FFT3d(index, 1:4) = [point, x_pos, y_pos, z_pos];
                    index = index+1;
                end
            end
            fclose(fid);

            if (Debug == 1)
                figure
                for iDot=1:size(FFT3d,1)
                    hold on, plot3(FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4), 'r.');
                    hold on, text(2+FFT3d(iDot,2) ,2+FFT3d(iDot,3) , num2str(FFT3d(iDot,1)), 'FontSize', 7,  'Color', 'b', 'rotation', 40 ) 
                end
            end
            
%            FFT3d = FFT3d
%            save('FFT3d.mat','FFT3d');
%            FFT3dChry = FFT3d;
%            save('FFT3dChry.mat','FFT3dChry');
%            FFT3dFord = FFT3d;
%            save('FFT3dFord.mat','FFT3dFord');
%            return

% config %            
%            fid = fopen('scan_reference_order_backdoor.txt');
% config %            
            fid = fopen(calib_config.cross_reference_txt_file);


%            while ~feof(fid)
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsLeft0(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsRight0(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsLeft1(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsRight1(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsLeft2(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsRight2(i) = str2num(fscanf(fid, '%s\n', 1));  end
                
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsUpper0(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsLower0(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsUpper1(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsLower1(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsUpper2(i) = str2num(fscanf(fid, '%s\n', 1));  end
                numPoint = str2num(fscanf(fid, '%s\n', 1));
                for i=1:numPoint    DotsLower2(i) = str2num(fscanf(fid, '%s\n', 1));  end
%            end
            fclose(fid);


            index = 1;
            for i = 1:segments(1)%length(DotsLeft0)
                for iDot=1:size(FFT3d,1)
                    if(DotsLeft0(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(2)%length(DotsRight0)
                for iDot=1:size(FFT3d,1)
                    if(DotsRight0(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(3)%length(DotsLeft1)
                for iDot=1:size(FFT3d,1)
                    if(DotsLeft1(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(4)%length(DotsRight1)
                for iDot=1:size(FFT3d,1)
                    if(DotsRight1(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(5)%length(DotsLeft2)
                for iDot=1:size(FFT3d,1)
                    if(DotsLeft2(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(6)%length(DotsRight2)
                for iDot=1:size(FFT3d,1)
                    if(DotsRight2(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(7)%length(DotsUpper0)
                for iDot=1:size(FFT3d,1)
                    if(DotsUpper0(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(8)%length(DotsLower0)
                for iDot=1:size(FFT3d,1)
                    if(DotsLower0(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(9)%length(DotsUpper1)
                for iDot=1:size(FFT3d,1)
                    if(DotsUpper1(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(10)%length(DotsLower1)
                for iDot=1:size(FFT3d,1)
                    if(DotsLower1(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(11)%length(DotsUpper2)
                for iDot=1:size(FFT3d,1)
                    if(DotsUpper2(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end
            for i = 1:segments(12)%length(DotsLower2)
                for iDot=1:size(FFT3d,1)
                    if(DotsLower2(i) == FFT3d(iDot,1))
                        intrinsicBox3D(index, 1:3) = [FFT3d(iDot,2), FFT3d(iDot,3), FFT3d(iDot,4)];
                        index = index+1;
                    end
                end
            end


        end

  
    
    
        % =================================================================
        %> @brief Generate a virtual grid on MacBeth pattern 
        %>
        %> @param Obj       Own object
        %> @param Left      Left dot 
        %> @param Right     Right dot 
        %> @param Debug     Show debug screen
        %> @retval GridMacbeth Structure containing virtual points on Macbeth
        % =================================================================
        function [GridMacbeth] = DetectGridMacbethOLD (Obj, Left, Right, Debug)
 
            GridMacbeth.Left = Left(1:2);
            GridMacbeth.Right = Right(1:2);
            
            GridMacbeth.Center = [(GridMacbeth.Left(1) + GridMacbeth.Right(1))/2 , (GridMacbeth.Left(2) + GridMacbeth.Right(2))/2];
            
            %Get an imaginary approximate MacBeth Pattern
            theta = atan2(GridMacbeth.Right(2)-GridMacbeth.Left(2),GridMacbeth.Left(1)-GridMacbeth.Right(1));
            dp = [GridMacbeth.Left(1), GridMacbeth.Left(2)]- [GridMacbeth.Center(1), GridMacbeth.Center(2)];
            H = hypot(dp(1),dp(2)) - 10; 
            % Making arbitrarily 10 pixels smaller to keep it properly inside the MacBeth Pattern

            % Following four points define a rectangle just inside the
            % boundary of MacBeth pattern
            GridMacbeth.LowerLeft = [GridMacbeth.Left(1)-H*sin(theta) GridMacbeth.Left(2)-H*cos(theta)];
            GridMacbeth.UpperLeft = [GridMacbeth.Left(1)+H*sin(theta) GridMacbeth.Left(2)+H*cos(theta)];
            GridMacbeth.LowerRight = [GridMacbeth.Right(1)-H*sin(theta) GridMacbeth.Right(2)-H*cos(theta)];
            GridMacbeth.UpperRight = [GridMacbeth.Right(1)+H*sin(theta) GridMacbeth.Right(2)+H*cos(theta)];

            h = 3*H/5; % h = 3*H/5;
            % Following points lie on a line through LowerLeft and UpperLeft
            GridMacbeth.LowerMidLeft = [GridMacbeth.Left(1)-h*sin(theta) GridMacbeth.Left(2)-h*cos(theta)];
            GridMacbeth.UpperMidLeft = [GridMacbeth.Left(1)+h*sin(theta) GridMacbeth.Left(2)+h*cos(theta)];
            % Following points lie on a line through LowerRight and UpperRight
            GridMacbeth.LowerMidRight = [GridMacbeth.Right(1)-h*sin(theta) GridMacbeth.Right(2)-h*cos(theta)];
            GridMacbeth.UpperMidRight = [GridMacbeth.Right(1)+h*sin(theta) GridMacbeth.Right(2)+h*cos(theta)];

            dd = 1*(GridMacbeth.Center(1) - GridMacbeth.Left(1))/3; % dd = 1*(GridMacbeth.Center(1) - GridMacbeth.Left(1))/6;
            % Following points lie on a line through LowerLeft and LowerRight
            
            GridMacbeth.LowerLeftMid  = [dd+GridMacbeth.Left(1)-H*sin(theta)  GridMacbeth.Left(2)-H*cos(theta)];
            GridMacbeth.LowerRightMid = [-dd+GridMacbeth.Right(1)-H*sin(theta) GridMacbeth.Right(2)-H*cos(theta)];
            % Following points lie on a line through UpperLeft and UpperRight
            GridMacbeth.UpperLeftMid  = [dd+GridMacbeth.Left(1)+H*sin(theta) GridMacbeth.Left(2)+H*cos(theta)];
            GridMacbeth.UpperRightMid = [-dd+GridMacbeth.Right(1)+H*sin(theta) GridMacbeth.Right(2)+H*cos(theta)];

            % Upper and lower central doty, above and below the center dot
            GridMacbeth.Upper = [(GridMacbeth.UpperLeft(1) + GridMacbeth.UpperRight(1))/2 , (GridMacbeth.UpperLeft(2) + GridMacbeth.UpperRight(2))/2];
            GridMacbeth.Lower = [(GridMacbeth.LowerLeft(1) + GridMacbeth.LowerRight(1))/2 , (GridMacbeth.LowerLeft(2) + GridMacbeth.LowerRight(2))/2];
        
            % Show debug if set
            if (Debug == 1)
                hold on
                plot(GridMacbeth.Left(1), GridMacbeth.Left(2), 'mo', 'Markersize', 15);
                plot(GridMacbeth.Right(1), GridMacbeth.Right(2), 'co', 'Markersize', 15);
                plot(GridMacbeth.Center(1), GridMacbeth.Center(2), 'r*');

                % Upper and lower central doty, above and below the center dot
                plot(GridMacbeth.Upper(1), GridMacbeth.Upper(2), 'r+');
                plot(GridMacbeth.Lower(1), GridMacbeth.Lower(2), 'r+');

                % Following four points define a rectangle just inside the
                % boundary of MacBeth pattern
                plot(GridMacbeth.LowerLeft(1), GridMacbeth.LowerLeft(2), 'm+');
                plot(GridMacbeth.UpperLeft(1), GridMacbeth.UpperLeft(2), 'm+');
                plot(GridMacbeth.LowerRight(1), GridMacbeth.LowerRight(2), 'c+');
                plot(GridMacbeth.UpperRight(1), GridMacbeth.UpperRight(2), 'c+');

                % Following points lie on a line through LowerLeft and UpperLeft
                plot(GridMacbeth.LowerMidLeft(1), GridMacbeth.LowerMidLeft(2), 'y.');
                plot(GridMacbeth.UpperMidLeft(1), GridMacbeth.UpperMidLeft(2), 'y.');
                % Following points lie on a line through LowerRight and UpperRight
                plot(GridMacbeth.LowerMidRight(1), GridMacbeth.LowerMidRight(2), 'y.');
                plot(GridMacbeth.UpperMidRight(1), GridMacbeth.UpperMidRight(2), 'y.');

                % Following points lie on a line through LowerLeft and LowerRight
                plot(GridMacbeth.LowerLeftMid(1), GridMacbeth.LowerLeftMid(2), 'm.');
                plot(GridMacbeth.LowerRightMid(1), GridMacbeth.LowerRightMid(2), 'c.');
                % Following points lie on a line through UpperLeft and UpperRight
                plot(GridMacbeth.UpperLeftMid(1), GridMacbeth.UpperLeftMid(2), 'm.');
                plot(GridMacbeth.UpperRightMid(1), GridMacbeth.UpperRightMid(2), 'c.');
            end
            
        end


        % =================================================================
        %> @brief Filter remaining dots Dots to proper intrinsicBox2D order
        %>
        %> @todo Missing dots in between a rib 
        %>
        %> @param Obj       Own object
        %> @param Dots      
        %> @param GridMacbeth Structure containing virtual points on Macbeth
        %> @param Size      Size of image [rows, columns]
        %> @param Debug     Show debug screen
        %> @retval intrinsicBox2D Center dot image location 
        %> @retval segments Number of dots detected in a particular segment
        %>         Upper
        %>         1 0 2
        %>         | | |
        %>         | | |
        %> Left1---      ---Right1
        %> Left0---      ---Right0
        %> Left2---      ---Right2
        %>         | | |
        %>         | | |
        %>         1 0 2
        %>         Lower
        %> Order of segments:
        %> Left0, Right0, Left1, Right1, Left2, Right2, Upper0, Lower0, Upper1, Lower1, Upper2, Lower2.
        % =================================================================
        function [intrinsicBox2D, segments] = DetectOrderedDotsOLD (Obj, Dots, GridMacbeth, Size, Debug)
 
            Left            = GridMacbeth.Left;
            Right           = GridMacbeth.Right;
            Center          = GridMacbeth.Center;
            LowerLeft       = GridMacbeth.LowerLeft;
            UpperLeft       = GridMacbeth.UpperLeft;
            LowerRight      = GridMacbeth.LowerRight;
            UpperRight      = GridMacbeth.UpperRight;
            LowerMidLeft    = GridMacbeth.LowerMidLeft;
            UpperMidLeft    = GridMacbeth.UpperMidLeft;
            LowerMidRight   = GridMacbeth.LowerMidRight;
            UpperMidRight   = GridMacbeth.UpperMidRight;
            LowerLeftMid    = GridMacbeth.LowerLeftMid;
            LowerRightMid   = GridMacbeth.LowerRightMid;
            UpperLeftMid    = GridMacbeth.UpperLeftMid;
            UpperRightMid   = GridMacbeth.UpperRightMid;
            Upper           = GridMacbeth.Upper;
            Lower           = GridMacbeth.Lower;
            

            Dots_temp1 = Dots(:,1:3);
            Dots_temp2 = Dots(:,4:8);
            
            % add angle and distance to Dots
            Dots = [Dots_temp1 ...
                    atan2d((Dots(:,2)-Center(2)), (Dots(:,1)-Center(1))) ...
                    sqrt((Dots(:,1)-Center(1)).^2 + (Dots(:,2)-Center(2)).^2) ...
                    Dots_temp2];
            

            %Getting left and right center lines, named as 0 lines
            Q1 = Left(1:2); Q1 = Q1';
            Q2 = Right(1:2); Q2 = Q2';
            indexLeft = 1;
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) < Size(2)/2 )
                        DotsLeft0(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                    if ( Dots(i,1) > Size(2)/2)
                        DotsRight0(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsLeft0 and DotsRight0 from further search
            Dots = setdiff(Dots, DotsLeft0, 'rows');
            Dots = setdiff(Dots, DotsRight0, 'rows');

            %Getting left and right upper center lines, named as 1 lines
            % Left first
            Q1 = UpperLeft(1:2); Q1 = Q1';
            Q2 = UpperMidRight(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) < UpperLeft(1))
                        DotsLeft1(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
            % Removing DotsLeft1 from further search
            Dots = setdiff(Dots, DotsLeft1, 'rows');
            % Right now
            Q1 = UpperRight(1:2); Q1 = Q1';
            Q2 = UpperMidLeft(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)] )
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) > UpperRight(1))
                        DotsRight1(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsRight1 from further search
            Dots = setdiff(Dots, DotsRight1, 'rows');
            %Getting left and right lower center lines, named as 2 lines
            % Left first
            Q1 = LowerLeft(1:2); Q1 = Q1';
            Q2 = LowerMidRight(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);  
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) < LowerLeft(1))
                        DotsLeft2(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
            % Removing DotsLeft2 from further search
            Dots = setdiff(Dots, DotsLeft2, 'rows');
            % Right now
            Q1 = LowerRight(1:2); Q1 = Q1';
            Q2 = LowerMidLeft(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)] )
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,1) > LowerRight(1))
                        DotsRight2(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsRight2 from further search
            Dots = setdiff(Dots, DotsRight2, 'rows');

            
            %Getting upper and lower center lines, named as 0 lines
            Q1 = Upper(1:2); Q1 = Q1';
            Q2 = Lower(1:2); Q2 = Q2';
            indexUpper = 1;
            indexLower = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) < Size(1)/2)
                        DotsUpper0(indexUpper, :) = Dots(i,:);
                        indexUpper = indexUpper+1;
                    end
                    if ( Dots(i,2) > Size(1)/2)
                        DotsLower0(indexLower, :) = Dots(i,:);
                        indexLower = indexLower+1;
                    end

                end
            end
            % Removing DotsUpper0 and DotsLower0 from further search
            Dots = setdiff(Dots, DotsUpper0, 'rows');
            Dots = setdiff(Dots, DotsLower0, 'rows');

            %Getting upper and lower, left lines, named as 1 lines
            % Upper first
            Q1 = UpperLeft(1:2); Q1 = Q1';
            Q2 = LowerLeftMid(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) < UpperLeft(2))
                        DotsUpper1(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
            % Removing DotsUpper1 from further search
            Dots = setdiff(Dots, DotsUpper1, 'rows');
            % Lower now
            Q1 = LowerLeft(1:2); Q1 = Q1';
            Q2 = UpperLeftMid(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)] )
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) > LowerLeft(2))
                        DotsLower1(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsLower1 from further search
            Dots = setdiff(Dots, DotsLower1, 'rows');
            %Getting upper and lower, right lines, named as 2 lines
            % Upper first
            Q1 = UpperRight(1:2); Q1 = Q1';
            Q2 = LowerRightMid(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)])
            indexLeft = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) < UpperLeft(2))
                        DotsUpper2(indexLeft, :) = Dots(i,:);
                        indexLeft = indexLeft+1;
                    end
                end
            end
            % Removing DotsUpper2 from further search
            Dots = setdiff(Dots, DotsUpper2, 'rows');
            % Lower now
            Q1 = LowerRight(1:2); Q1 = Q1';
            Q2 = UpperRightMid(1:2); Q2 = Q2';
            %line([Q1(1) Q2(1)], [Q1(2) Q2(2)] )
            indexRight = 1;
            for i = 1:size(Dots,1)
                P = Dots(i,1:2);
                P = P';
                d = abs(det([Q2-Q1,P-Q1]))/abs(Q2-Q1);    
                if (d<Obj.DistanceThreshold)
                    if ( Dots(i,2) > LowerLeft(2))
                        DotsLower2(indexRight, :) = Dots(i,:);
                        indexRight = indexRight+1;
                    end
                end
            end
            % Removing DotsLower2 from further search
            Dots = setdiff(Dots, DotsLower2, 'rows'); % Not needed actually becuase it was the last search
            

            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % Sorting out according to distance from Center point
            DotsLeft0  = sortrows(DotsLeft0 ,5);
            DotsRight0 = sortrows(DotsRight0,5);
            DotsLeft1  = sortrows(DotsLeft1 ,5);
            DotsRight1 = sortrows(DotsRight1,5);
            DotsLeft2  = sortrows(DotsLeft2 ,5);
            DotsRight2 = sortrows(DotsRight2,5);
            %--------------------------------------------------------------
            DotsUpper0 = sortrows(DotsUpper0,5);
            DotsLower0 = sortrows(DotsLower0,5);
            DotsUpper1 = sortrows(DotsUpper1,5);
            DotsLower1 = sortrows(DotsLower1,5);
            DotsUpper2 = sortrows(DotsUpper2,5);
            DotsLower2 = sortrows(DotsLower2,5);
            %--------------------------------------------------------------
            %--------------------------------------------------------------
            % Keep only the Maximum possible Dots
            if(size(DotsLeft0,1) > Obj.maxDotsLeftRight)
                DotsLeft0 = DotsLeft0(1:Obj.maxDotsLeftRight,:);
            end;% Keeping only the maximum possible dots
            if(size(DotsRight0,1) > Obj.maxDotsLeftRight)
                DotsRight0 = DotsRight0(1:Obj.maxDotsLeftRight,:);
            end;% Keeping only the maximum possible dots
            
            if(size(DotsLeft1,1) > Obj.maxDotsLeftRight)
                DotsLeft1 = DotsLeft1(1:Obj.maxDotsLeftRight,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsRight1,1) > Obj.maxDotsLeftRight)
                DotsRight1 = DotsRight1(1:Obj.maxDotsLeftRight,:);
            end % Keeping only the maximum possible dots

            if(size(DotsLeft2,1) > Obj.maxDotsLeftRight)
                DotsLeft2 = DotsLeft2(1:Obj.maxDotsLeftRight,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsRight2,1) > Obj.maxDotsLeftRight)
                DotsRight2 = DotsRight2(1:Obj.maxDotsLeftRight,:);
            end % Keeping only the maximum possible dots
            %--------------------------------------------------------------
            if(size(DotsUpper0,1) > Obj.maxDotsUpperLower)
                DotsUpper0 = DotsUpper0(1:Obj.maxDotsUpperLower,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsLower0,1) > Obj.maxDotsUpperLower)
                DotsLower0 = DotsLower0(1:Obj.maxDotsUpperLower,:);
            end % Keeping only the maximum possible dots

            if(size(DotsUpper1,1) > Obj.maxDotsUpperLower)
                DotsUpper1 = DotsUpper1(1:Obj.maxDotsUpperLower,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsLower1,1) > Obj.maxDotsUpperLower)
                DotsLower1 = DotsLower1(1:Obj.maxDotsUpperLower,:);
            end % Keeping only the maximum possible dots
            
            if(size(DotsUpper2,1) > Obj.maxDotsUpperLower)
                DotsUpper2 = DotsUpper2(1:Obj.maxDotsUpperLower,:); 
            end % Keeping only the maximum possible dots
            if(size(DotsLower2,1) > Obj.maxDotsUpperLower)
                DotsLower2 = DotsLower2(1:Obj.maxDotsUpperLower,:);
            end % Keeping only the maximum possible dots
            %--------------------------------------------------------------
            %--------------------------------------------------------------
            
            
            
            
            

            if (Debug == 1)
                plot(DotsLeft0(:,1), DotsLeft0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsRight0(:,1), DotsRight0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsLeft1(:,1), DotsLeft1(:,2), 'bo-', 'MarkerSize',8);
                plot(DotsRight1(:,1), DotsRight1(:,2), 'co-', 'MarkerSize',8);
                plot(DotsLeft2(:,1), DotsLeft2(:,2), 'go-', 'MarkerSize',8);
                plot(DotsRight2(:,1), DotsRight2(:,2), 'bo-', 'MarkerSize',8);

                plot(DotsUpper0(:,1), DotsUpper0(:,2), 'bo-', 'MarkerSize',8);
                plot(DotsLower0(:,1), DotsLower0(:,2), 'ro-', 'MarkerSize',8);
                plot(DotsUpper1(:,1), DotsUpper1(:,2), 'mo-', 'MarkerSize',8);
                plot(DotsLower1(:,1), DotsLower1(:,2), 'ko-', 'MarkerSize',8);
                plot(DotsUpper2(:,1), DotsUpper2(:,2), 'go-', 'MarkerSize',8);
                plot(DotsLower2(:,1), DotsLower2(:,2), 'mo-', 'MarkerSize',8);
            end


            
            DotsLeft0 = DotsLeft0(2:size(DotsLeft0,1)-2,:);
            DotsRight0 = DotsRight0(2:size(DotsRight0,1)-2,:);
            DotsLeft1 = DotsLeft1(2:size(DotsLeft1,1)-15,:);
            DotsRight1 = DotsRight1(2:size(DotsRight1,1)-15,:);
            DotsLeft2 = DotsLeft2(2:size(DotsLeft2,1)-15,:);
            DotsRight2 = DotsRight2(2:size(DotsRight2,1)-15,:);
            DotsUpper0 = DotsUpper0(2:size(DotsUpper0,1)-4,:);
            DotsLower0 = DotsLower0(2:size(DotsLower0,1)-4,:);
            DotsUpper1 = DotsUpper1(2:size(DotsUpper1,1)-4,:);
            DotsLower1 = DotsLower1(2:size(DotsLower1,1)-4,:);
            DotsUpper2 = DotsUpper2(2:size(DotsUpper2,1)-4,:);
            DotsLower2 = DotsLower2(2:size(DotsLower2,1)-4,:);
            
%             DotsLeft0 = DotsLeft0(1:size(DotsLeft0,1)-4,:);
%             DotsRight0 = DotsRight0(1:size(DotsRight0,1)-4,:);
%             DotsLeft1 = DotsLeft1(1:size(DotsLeft1,1)-4,:);
%             DotsRight1 = DotsRight1(1:size(DotsRight1,1)-4,:);
%             DotsLeft2 = DotsLeft2(1:size(DotsLeft2,1)-4,:);
%             DotsRight2 = DotsRight2(1:size(DotsRight2,1)-4,:);
%             DotsUpper0 = DotsUpper0(1:size(DotsUpper0,1)-4,:);
%             DotsLower0 = DotsLower0(1:size(DotsLower0,1)-4,:);
%             DotsUpper1 = DotsUpper1(1:size(DotsUpper1,1)-4,:);
%             DotsLower1 = DotsLower1(1:size(DotsLower1,1)-4,:);
%             DotsUpper2 = DotsUpper2(1:size(DotsUpper2,1)-4,:);
%             DotsLower2 = DotsLower2(1:size(DotsLower2,1)-4,:);
            

            segments = [size(DotsLeft0,1), size(DotsRight0,1), ...
                        size(DotsLeft1,1), size(DotsRight1,1), ...
                        size(DotsLeft2,1), size(DotsRight2,1), ...
                        size(DotsUpper0,1), size(DotsLower0,1),...
                        size(DotsUpper1,1), size(DotsLower1,1),...
                        size(DotsUpper2,1), size(DotsLower2,1),];
            intrinsicBox2D = [DotsLeft0(:,1:2); DotsRight0(:,1:2);...
                              DotsLeft1(:,1:2); DotsRight1(:,1:2);...
                              DotsLeft2(:,1:2); DotsRight2(:,1:2);...
                              DotsUpper0(:,1:2); DotsLower0(:,1:2);...
                              DotsUpper1(:,1:2); DotsLower1(:,1:2);...
                              DotsUpper2(:,1:2); DotsLower2(:,1:2)];

                         
        end
        
        
        
    end % end methode

end

