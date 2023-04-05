%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2014 Magna Electronics Europe GmbH & Co. KG
%
%   Author: Jagmal Singh - email: Jagmal.Singh@magna.de
%   
%   This program carries out intrinsic (as well as extrinisic) camera
%   calibration. It is an update3d version of scaramuzza's model.
%   
%   Theoretical detials can be found in
%   IC_Evaluation_Scaramuzza_Algorithm.doc
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%--------------------------------------------------------------------------
% Structure for calib_input
%--------------------------------------------------------------------------
% calib_input.width             Number of columns of captures/rendered image
% calib_input.height            Number of rows of captures/rendered image
% calib_input.xc                Design principal point in x-axies
% calib_input.yc                Design principal point in y-axis
% calib_input.fast              Want to execute faster version (fast=1) or tested version (fast=0)?
% calib_input.intrinsicBox2D    
% calib_input.intrinsicBox3D    
% calib_input.Debug             Debug=1 shows the results in image, Debug=0 no display
% calib_input.lens              Lens identifier, Ford (Lens=1), Chrysler (Lens=2)
%--------------------------------------------------------------------------
function calib_output = calibration_scaramuzza_singh(calib_input) 

tStartOverall = tic;

width = calib_input.width;
height = calib_input.height;
xc = calib_input.xc;
yc = calib_input.yc;

fast = calib_input.fast; % Taking the value of faster or tested version option

intrinsicBox2D = calib_input.intrinsicBox2D;
intrinsicBox3D = calib_input.intrinsicBox3D;
Debug = calib_input.Debug;

%save('intrinsicBox2D','intrinsicBox2D');
%save('intrinsicBox3D','intrinsicBox3D');
%calib_output.lens = calib_input.lens;


poly_order = 5; % Set it always 5
% IPR = 0; % IPR = 1 is for Intrinsic Parameter Reference Box
% FFT = 1; % FFT = 1 is for Final Functional Tester

%config% pixel_pitch = 3e-6;             % [m]
%config% pixel_pitch = pixel_pitch*1e3;  % conversion in [mm]
pixel_pitch = calib_input.pixel_pitch_mm; % Will use operator suppled values instead of fxed ones

format long g

% if(FFT)
%     img = imread(fname);
%     %img = imcomplement(img);
%     %G = fspecial('gaussian',[3 3],2);
%     %img = imfilter(img,G,'same');
%     % Show debug if set
%     if (Debug == 1)
%         figure(1)
%         %imshow(flipud(fliplr(img)));
%         imshow(img);
%         set(gca,'xtick',[0:size(img,2)/10:size(img,2)])
%         set(gca,'ytick',[0:size(img,1)/10:size(img,1)])
%         axis on
%         grid on
%     end
% 
%     pause(1)
%     % Setting up the initial sizes
%     width = size(img,2);
%     height = size(img,1);
%     xc = (width)/2;
%     yc = (height)/2; 
% end

% if(IPR)
%     fname = 'C:\Users\MEE_JaSin\Desktop\goldStandard\POV-Ray\RENDERED\Scene_IPR_1878454260.png';
%     img = imread(fname);
%     %img = fname;
%     img = imcomplement(img);
%     G = fspecial('gaussian',[3 3],2);
%     img = imfilter(img,G,'same');
% 
%     % Show debug if set
%     if (Debug == 1)
%         figure(1)
%         imshow(flipud(fliplr(img)));
%         %imshow(img);
%         set(gca,'xtick',[0:size(img,2)/10:size(img,2)])
%         set(gca,'ytick',[0:size(img,1)/10:size(img,1)])
%         axis on
%         grid on
%     end
% 
%     pause(1)
%     % Setting up the initial sizes
%     width = size(img,2);
%     height = size(img,1);
%     xc = (width)/2;
%     yc = (height)/2;
% 
% 
%     [intrinsicBox2D, segments] = getIntrinsicBox2D_IPR(img); % 2D intrinsic box will always be the same, sphere or psedo-sphere
%     intrinsicBox3D = getIntrinsicBox3D_IPR(segments, pseudosphere);
% end



%intrinsicBox2D(:,1) = width-intrinsicBox2D(:,1); % +1 because width-1280 will be zero!
%intrinsicBox2D(:,2) = height-intrinsicBox2D(:,2)+1; % +1 because height-800 will be zero!
%intrinsicBox2D(:,1) = intrinsicBox2D(:,1); % +1 becuase width-1280 will be zero!
%intrinsicBox2D(:,2) = intrinsicBox2D(:,2); % +1 becuase height-800 will be zero!

% Initialization of calib_data structure
% calib_data.ocam_calib structure will contain calibration parameters

calib_data.pixel_pitch = pixel_pitch;
calib_data.fast = fast;
calib_data.ocam_model.ss = 0; % Coefficients of the Taylor polynomial

calib_data.ocam_model.c = 1;
calib_data.ocam_model.d = 0;
calib_data.ocam_model.e = 0;
calib_data.ocam_model.xc = xc;
calib_data.ocam_model.yc = yc;
calib_data.ocam_model.width = width;
calib_data.ocam_model.height = height;

scale3D = 1/pixel_pitch;
calib_data.Xt = +scale3D*intrinsicBox3D(:,1);
calib_data.Yt = +scale3D*intrinsicBox3D(:,2);
calib_data.Zt = -scale3D*intrinsicBox3D(:,3); % Check this out
calib_data.Xp_abs = intrinsicBox2D(:, 1);
calib_data.Yp_abs = intrinsicBox2D(:, 2);

calib_data.linearflag = 0;
calib_data.findcenterflag = 0;
calib_data.nonlinearflag = 0;
calib_data.idealflag = 0;

calib_data.taylor_order = poly_order;
calib_data.disp = 0;

calib_data.RRfin  = zeros(3,4,1);
calib_data.calibrated = 0;
calib_data.n_ima = 0;
calib_data.ima_proc = 0;

% r =
%         0.0176239575463845        1.00977838572557
%       -0.00202877926900608        -0.116240489677685
%          -3.02620386567362        -173.388709449273
         
% Linear
calib_data = calibration_linear5(calib_data); % Calibration above 4th order is not tested well.. May be unstable some times.
[err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,0);
calib_data = append_calib_data_structure(calib_data,'linear1', MSE, intrinsicBox2Dreprojected);
%calib_data.ocam_model.ss'

% Find Center
calib_data = findcenter5(calib_data);
[err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,0);
calib_data = append_calib_data_structure(calib_data,'findcenter', MSE, intrinsicBox2Dreprojected);

% % Nonlinear
% calib_data = calibration_nonlinearCDE(calib_data);
% [err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,0);
% calib_data = append_calib_data_structure(calib_data,'nonlinear1', MSE, intrinsicBox2Dreprojected);

%fprintf('\nCamera X-position (calibration): %d\n',calib_data.RRfin(1,4)*pixel_pitch);
%fprintf('Camera Y-position (calibration): %d\n',calib_data.RRfin(2,4)*pixel_pitch);
%fprintf('Camera Z-position (calibration): %d\n\n',calib_data.RRfin(3,4)*pixel_pitch);
errIdeal = [0 0 0];
stderrIdeal = [0 0 0];

% Ideal reprojection error computation
%[errIdeal,stderrIdeal,MSE,intrinsicBox2Dreprojected, calib_data, intrinsicBox2D]=reprojectpoints_ideal(calib_data,1);
%calib_data = append_calib_data_structure(calib_data,'ideal', MSE, intrinsicBox2Dreprojected);

% Show debug if set
if (Debug == 1)
    %figure(1)
    if (calib_data.linearflag)
       hold on, plot(calib_data.linear1.ocam_model.xc, calib_data.linear1.ocam_model.yc,'ro');
       hold on, plot(calib_data.linear1.intrinsicBox2D_Reprojected(:,1), calib_data.linear1.intrinsicBox2D_Reprojected(:,2),'r+');
    end

    if (calib_data.findcenterflag)
        hold on, plot(calib_data.findcenter.ocam_model.xc, calib_data.findcenter.ocam_model.yc,'g+');
        hold on, plot(calib_data.findcenter.ocam_model.xc+calib_data.T_final_for_evaluation(1)*calib_data.pixel_pitch, calib_data.findcenter.ocam_model.yc+calib_data.T_final_for_evaluation(2)*calib_data.pixel_pitch,'g*');
        hold on, plot(calib_data.findcenter.intrinsicBox2D_Reprojected(:,1), calib_data.findcenter.intrinsicBox2D_Reprojected(:,2),'g+');
    end

    if (calib_data.nonlinearflag)
        hold on, plot(calib_data.nonlinear1.ocam_model.xc, calib_data.nonlinear1.ocam_model.yc,'bo');
        hold on, plot(calib_data.nonlinear1.intrinsicBox2D_Reprojected(:,1), calib_data.nonlinear1.intrinsicBox2D_Reprojected(:,2),'b+');
    end
    
    % Create push button to accept the current values
    btn = uicontrol('Style', 'pushbutton', 'String', 'Accept',...
        'Position', [20 20 50 20],...
        'Callback', @close_pushbutton_Callback);       

    
%     if (calib_data.idealflag)
%         
%         figure(2)
%         imgIdeal = imread('C:\Users\MEE_JaSin\Desktop\goldStandard\ic_eval\ideal.png');        
%         imgIdeal = imcomplement(imgIdeal);
%         G = fspecial('gaussian',[3 3],2);
%         imgIdeal = imfilter(imgIdeal,G,'same');
%         imshow(flipud(fliplr(imgIdeal)));
%         set(gca,'xtick',[0:size(img,2)/10:size(img,2)])
%         set(gca,'ytick',[0:size(img,1)/10:size(img,1)])
%         axis on
%         grid on
%         hold on, plot(intrinsicBox2D(:,1), intrinsicBox2D(:,2),'c.');
%         hold on, plot(calib_data.ideal.intrinsicBox2D_Reprojected(:,1), calib_data.ideal.intrinsicBox2D_Reprojected(:,2),'b.');
%         
%         for iDot=1:size(intrinsicBox2D,1)
%             hold on, plot ([intrinsicBox2D(iDot,1) calib_data.ideal.intrinsicBox2D_Reprojected(iDot,1)], [intrinsicBox2D(iDot,2) calib_data.ideal.intrinsicBox2D_Reprojected(iDot,2)], 'r-');
%             strNum = ( sqrt( (intrinsicBox2D(iDot,1)-calib_data.ideal.intrinsicBox2D_Reprojected(iDot,1))^2 + (intrinsicBox2D(iDot,2)-calib_data.ideal.intrinsicBox2D_Reprojected(iDot,2))^2) );
%              if (strNum < 1)
%                  str = num2str(strNum);
%                  hold on, text(1+intrinsicBox2D(iDot,1) ,1+intrinsicBox2D(iDot,2) , str, 'FontSize', 6,  'Color', 'g' ) 
%              end
%              if (strNum > 1 && strNum < 2)
%                  str = num2str(strNum);
%                  hold on, text(1+intrinsicBox2D(iDot,1) ,1+intrinsicBox2D(iDot,2) , str, 'FontSize', 6,  'Color', 'k' ) 
%              end
%              if (strNum > 2)
%                  str = num2str(strNum);
%                  hold on, text(1+intrinsicBox2D(iDot,1) ,1+intrinsicBox2D(iDot,2) , str, 'FontSize', 6,  'Color', 'r' ) 
%              end
%              
%         end
%         
%     end
    hold off
    
end

%calib_data.ocam_model = export_data(calib_data.ocam_model); % Exporting results in Scaramuzza format
%calib_data.ocam_model.ss'
my.ss = [];
for coeff = 1:poly_order+1
    my.ss = [my.ss, calib_data.ocam_model.ss(coeff)];
end
my.ssrevert = [];
for coeff = 1:poly_order+1
    my.ssrevert = [my.ssrevert, calib_data.ocam_model.ss(poly_order+1-coeff+1)];
end
calib_data.ocam_model.invss = findinvpoly(my.ssrevert, sqrt((width/2)^2+(height/2)^2));

fprintf(1,'\n------------------------------------------------------------------\n');
fprintf(1,'Stage-VI.');
fprintf(1,'\nExporting Poly_Image2World and Poly_World2Image in desired format.');
% IN CASE YOU WANT THE POLYNOMIAL IN DESIGN LENS MAP FUNCTION FORM - STARTS
% Fit the polynomial to width only, as we have calibration points approximately only upto there
if (calib_input.field_of_view > pi)
%    poly_fit_size = floor((sqrt(width^2+height^2))*pi/calib_input.field_of_view)
    poly_fit_size = floor(((width))*pi/calib_input.field_of_view);
    fprintf(1,'\nPolynomial fitted upto %d pixels (i.e. 90 degrees FoV).',poly_fit_size);
else
    poly_fit_size = width;
end

%poly_fit_size = sqrt(width^2+height^2); % width+130 is approximately upto 105 degrees
%poly_fit_size = 400; % width+130 is approximately upto 105 degrees
%lensmap(:,1) = atan2(0:floor(poly_fit_size/2),-polyval([calib_data.ocam_model.ss(end:-1:1)],[0:floor(poly_fit_size/2)]))-00;
%CORRECT%lensmap(:,1) = 180/pi*atan2(0:floor(poly_fit_size/2),-polyval([calib_data.ocam_model.ss(end:-1:1)],[0:floor(poly_fit_size/2)]))-00;

% in degrees:
%lensmap(:,1) = 180/pi*atan2((0:floor(poly_fit_size/2)),-polyval([calib_data.ocam_model.ss(end:-1:1)],[(0:floor(poly_fit_size/2))]))-00;
% in radians:
lensmap(:,1) = atan2((0:floor(poly_fit_size/2)),-polyval([calib_data.ocam_model.ss(end:-1:1)],[(0:floor(poly_fit_size/2))]))-00; % LensAngle



%lensmap(:,2) = 180/pi*atan2(0:floor(poly_fit_size/2),-polyval([calib_data.ocam_model.invss(end:-1:1)],[0:floor(poly_fit_size/2)]))-00;
%lensmap(:,2) = (0:floor(poly_fit_size/2))*pixel_pitch;
lensmap(:,2) = (0:floor(poly_fit_size/2))*pixel_pitch; % LensDist

[Poly_Image2World,S] = polyfit0 (lensmap(:,2),lensmap(:,1), poly_order);   %In design case: [Poly_Image2World, S] = polyfit0 (LensDist, LensAngle, poly_order);
[Poly_World2Image,S] = polyfit0 (lensmap(:,1),lensmap(:,2), poly_order);   %In design case: [Poly_World2Image, S] = polyfit0 (LensAngle, LensDist, poly_order);
% IN CASE YOU WANT THE POLYNOMIAL IN DESIGN LENS MAP FUNCTION FORM - ENDS
%Poly_Image2World'
%Poly_World2Image'

%[PIT_Image2World, PIT_World2Image] = compare_with_design(calib_input, Poly_Image2World, Poly_World2Image);

%calib_data.RRfin

%     fprintf('Image2World Polynomial (Calibration)\n');
%     fprintf('a0 = %2.5e\n', Poly_Image2World(end));
%     fprintf('a1 = %2.5e\n', Poly_Image2World(end-1));
%     fprintf('a2 = %2.5e\n', Poly_Image2World(end-2));
%     fprintf('a3 = %2.5e\n', Poly_Image2World(end-3));
%     fprintf('a4 = %2.5e\n', Poly_Image2World(end-4));
%     fprintf('a5 = %2.5e\n', Poly_Image2World(end-5));
%     fprintf('World2Image Polynomial (Calibration)\n');
%     fprintf('a0 = %2.5e\n', Poly_World2Image(end));
%     fprintf('a1 = %2.5e\n', Poly_World2Image(end-1));
%     fprintf('a2 = %2.5e\n', Poly_World2Image(end-2));
%     fprintf('a3 = %2.5e\n', Poly_World2Image(end-3));
%     fprintf('a4 = %2.5e\n', Poly_World2Image(end-4));
%     fprintf('a5 = %2.5e\n', Poly_World2Image(end-5));

    


calib_output.size = [width height];
calib_output.scaramuzza_dirpol = my.ss;
calib_output.scaramuzza_invpol = findinvpoly(my.ssrevert, sqrt((width/2)^2+(height/2)^2));
calib_output.Poly_Image2World = Poly_Image2World;
calib_output.Poly_World2Image = Poly_World2Image;
%calib_output.c = calib_data.ocam_model.c; % Always 1
%calib_output.d = calib_data.ocam_model.d; % Always 0
%calib_output.e = calib_data.ocam_model.e; % Always 0

% % % % % % % % standaloneMode = 0; % By default release DLL mode
% % % % % % % % if exist('calib_settings.mat', 'file') == 2 % Check if we are using standalone mode or release DLL mode
% % % % % % % %     fprintf(1,'calib_settings loading sucessful.');
% % % % % % % %     load calib_settings; % Loading the calibration settings which must have been set using settings option in the very first run
% % % % % % % %     standaloneMode = 1;
% % % % % % % % end
% % % % % % % % 
% % % % % % % % if (standaloneMode) % in standalone mode we need to check if we use captured image, or rendered image
% % % % % % % %     if(strcmp(calib_settings.Capture,'fals'))
% % % % % % % %         calib_output.PP_measured = [(calib_data.ocam_model.xc-1/2) (calib_data.ocam_model.yc-1/2)];
% % % % % % % %     else
% % % % % % % %         calib_output.PP_measured = [calib_data.ocam_model.xc calib_data.ocam_model.yc];
% % % % % % % %     end
% % % % % % % % else
% % % % % % % %         calib_output.PP_measured = [calib_data.ocam_model.xc calib_data.ocam_model.yc];
% % % % % % % % end

calib_output.Cam_translations = calib_data.T_final_for_evaluation*calib_data.pixel_pitch;
calib_output.Cam_rotations = calib_data.R_final_for_evaluation;

calib_output.PP_measured = [calib_data.ocam_model.xc+calib_data.T_final_for_evaluation(1)*calib_data.pixel_pitch calib_data.ocam_model.yc+calib_data.T_final_for_evaluation(2)*calib_data.pixel_pitch];
%calib_output.PP_measured = [calib_data.ocam_model.xc calib_data.ocam_model.yc];
calib_output.err = err;
calib_output.stderr = stderr;

calib_output.errIdeal = errIdeal;
calib_output.stderrIdeal = stderrIdeal;

calib_output.pixelwise_err = err(4:7);

calib_output.RotationTranslation = calib_data.RRfin;

Prueba = calib_output.RotationTranslation;

tEndOverall = toc(tStartOverall);
Prueba = Prueba / norm(Prueba(:,1));
R = Prueba(:,1:3);
[theta_z, theta_y, theta_x]=EulerAnglesFromR(R)

datevector = datevec(now)';
day = datevec2doy(datevector);

calib_output.time_elapsed_in_seconds = tEndOverall;
fprintf(1,'\n------------------------------------------------------------------\n');
fprintf(1,'\nTime elapsed in calibration :%f seconds.',calib_output.time_elapsed_in_seconds);

calib_output.Calibration_year = datevector(1);
calib_output.Calibration_day = day;

% if (Debug == 1)
%     uiwait 
% end
    

function close_pushbutton_Callback(source, callbackdata)       
    fig = gcf;
    close(fig);
	return;




