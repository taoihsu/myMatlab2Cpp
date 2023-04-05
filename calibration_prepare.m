function calib_input = calibration_prepare(calib_config, fname, Debug)


    %load calib_settings; % Loading the calibration settings which must have been set using settings option in the very first run
 
    %img = histeq(flipud(imread(fname)));
    img = ((imread(fname)));

%     test = 0;
%     if(test)
%         size(img)
%         imgStrech(:,:,1) = imresize(img(:,:,1), [480, 720]);
%         imgStrech(:,:,2) = imresize(img(:,:,2), [480, 720]);
%         imgStrech(:,:,3) = imresize(img(:,:,3), [480, 720]);
%         img = imgStrech; 
%         size(img)
%     end
    
    %img = flipud(fliplr(img));
    %img = imcomplement(img);
    %JJT modified to lower the Guasian Blur for the Zurich 2 Lite cameras
    %for PSA
    if(strcmp(calib_config.lens_identifier, 'Zurich2_Lite_30') || strcmp(calib_config.lens_identifier, 'Zurich2_Lite_25') )
      G = fspecial('gaussian',[5 5],2); %[5 5],2)
    else
      G = fspecial('gaussian',[5 5],2);
    end
    img = imfilter(img,G,'same'); %JJT
    imwrite(img,'guassianimage.bmp');
    
%   img = flipud(fliplr(img));
%     if(strcmp(calib_settings.Capture,'fals'))
%         img = (fliplr(img));
%         img = imnoise(img,'gaussian');
%     end
    
    verifyImageProc = Debug;
    
    %[intrinsicBox2D, segments] = getIntrinsicBox2D_FFT(img, lens, verifyImageProc);
    
    tStartOverall = tic;
        
    %if(verifyImageProc)
%        [intrinsicBox2D, segments] = getIntrinsicBox2D_FFT_interactive(img, lens, verifyImageProc);
%        intrinsicBox3D = getIntrinsicBox3D_FFT_selfregulated(segments, lens);
    %else
        DotPseudoSphere = made.getIntrinsicBox_FFT();
        [intrinsicBox2D, intrinsicBox3D, PP_mechanical] = DotPseudoSphere.DetectGrid(calib_config, img, Debug);
        
        %save('intrinsicBox3D.mat','intrinsicBox3D');
    %end
    
    tEndOverall = toc(tStartOverall);
    calib_input.time_elapsed_in_seconds = tEndOverall;
    fprintf(1,'\nTime elapsed in image processing for calibration preperation: %f seconds.\n',calib_input.time_elapsed_in_seconds);
    fprintf(1,'\nCenter of Macbeth chart is at: (%f, %f).\n',(PP_mechanical(1)), (PP_mechanical(2)));

    
    Xp_abs = intrinsicBox2D(:, 1);
    Yp_abs = intrinsicBox2D(:, 2);

    width = size(img,2);
    height = size(img,1);
    
    
    switch calib_config.pp_mode
        case 'engineering'
            xc = (width/2)-0.5;
            yc = (height/2)-0.5;
        case 'production'
            xc = (PP_mechanical(1));
            yc = (PP_mechanical(2));
    end

%            xc = (width)/2;
%            yc = (height)/2;
     
    % Show debug if set
    if (Debug == 1)
        figure(1)
        %imshow(flipud(fliplr(img)));
        imshow(img);
        set(gca,'xtick',[0:size(img,2)/10:size(img,2)])
        set(gca,'ytick',[0:size(img,1)/10:size(img,1)])
        % Original points
        hold on, plot(xc, yc,'c+');
        hold on, plot(Xp_abs, Yp_abs,'c.');
        axis on
        grid on
        pause(0.1)
    end

    
    calib_input.width = width;
    calib_input.height = height;
    calib_input.xc = xc;
    calib_input.yc = yc;
    calib_input.intrinsicBox2D = intrinsicBox2D;
    calib_input.intrinsicBox3D = intrinsicBox3D;
    
    calib_input.pixel_pitch_mm = calib_config.pixel_pitch_mm;
    calib_input.pixel_pitch_y_mm = calib_config.pixel_pitch_y_mm;
    calib_input.Debug = Debug;
    
    calib_input.Image_file_path = fname;
    calib_input.Pixel_size_x = 0.003;
    calib_input.Pixel_size_y = 0.003;
    calib_input.Focal_length = 1.00;
    calib_input.field_of_view = calib_config.field_of_view;

    
end

