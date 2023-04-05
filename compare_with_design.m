function [RMSE_Poly_Image2World, RMSE_Poly_World2Image] = compare_with_design(calib_config, Poly_Image2World, Poly_World2Image)


Poly_Image2World_design = calib_config.Poly_Image2World;
Poly_World2Image_design = calib_config.Poly_World2Image;

LensDist = calib_config.size_of_sensor/900:calib_config.size_of_sensor/900:calib_config.size_of_sensor;
LensAngle = 0.05:0.05:90;

RMSE_Poly_Image2World = sqrt(mean((polyval(Poly_Image2World, LensDist)-polyval(Poly_Image2World_design, LensDist)).^2)); % In radians
RMSE_Poly_World2Image = sqrt(mean((polyval(Poly_World2Image, LensAngle*pi/180)-polyval(Poly_World2Image_design, LensAngle*pi/180)).^2)); % In radians

%     switch lens
%         
%         %case '4063' % Ford version with shorter 4063 lens 
%         case 1 % Ford version with shorter 4063 lens 
%                 % Ford % TAKE CARE, HERE ONLY UPTO 90 Degress desine,
%                 % although we have polynomial available for more than 90 degrees 
%                 Poly_Image2World_design1 = [-0.349791717912698 4.34087776725691 -9.53790386414586 -1.08544602203925 63.552148839505 0]; % In degrees
%                 Poly_Image2World_design2 = [-0.00610501717378134 0.0757626094652446 -0.166467826168025 -0.0189446069372634 1.10919424396685 0];% In radians
%                 Poly_World2Image_design1 = [-9.22497704940729e-11 1.13073933865875e-08 -1.83525619351089e-08 1.46762912700803e-05 0.0156781968682944 0]; % In degrees
%                 Poly_World2Image_design2 = [-0.0569611116537413 0.121857715286182 -0.00345195078759037 0.0481794221760597 0.898294510928492 0]; % In radians
%                 load('LensDistFord.mat');  LensDist = LensDistFord;
%                 load('LensAngleFord.mat'); LensAngle = LensAngleFord;
% 
%         %case '4075' % Chrysler version with longer 4075 lens 
%         case 2 % Chrysler version with longer 4075 lens 
%                 %Chrysler % TAKE CARE, HERE ONLY UPTO 90 Degress desine
%                 % although we have polynomial available for more than 90 degrees 
%                 Poly_Image2World_design1 = [0.864311418011627 -0.402457185325417 -3.52806709986954 -0.814469922768524 54.5635983057855 0]; % In degrees
%                 Poly_Image2World_design2 = [0.0150850800068817 -0.00702420298222718 -0.0615763871240279 -0.0142151818107644 0.952314442171556 0]; % In radians
%                 Poly_World2Image_design1 = [-1.26742220183766e-10 1.18377191499547e-08 1.9986389427294e-07 2.73193254998099e-06 0.0183834755269411 0]; % In degrees
%                 Poly_World2Image_design2 = [-0.0782590321522076 0.127572939270311 0.0375925895075277 0.00896840552289037 1.05329556047576 0]; % In radians
%                 load('LensDistChry.mat');  LensDist = LensDistChry;
%                 load('LensAngleChry.mat'); LensAngle = LensAngleChry;
% 
%     end
    
    
%     %sizeSensor = LensDist(end); % in mm % From Excel
%     RMSE1_Poly_Image2World = sqrt(mean((polyval(Poly_Image2World, LensDist)-polyval(Poly_Image2World_design1, LensDist)).^2)); % In degrees
%     RMSE2_Poly_Image2World = sqrt(mean((polyval(Poly_Image2World, LensDist)-polyval(Poly_Image2World_design2, LensDist)).^2)); % In radians
%     RMSE_Poly_Image2World = min(RMSE1_Poly_Image2World, RMSE2_Poly_Image2World); % Just select the one which is smaller, kind of auto selection fo degrees and radians results
%    
%     
%     %sizeSensor = LensAngle(end); % in mm % From Excel
%     RMSE1_Poly_World2Image = sqrt(mean((polyval(Poly_World2Image, LensAngle)-polyval(Poly_World2Image_design1, LensAngle)).^2)); % In degrees
%     RMSE2_Poly_World2Image = sqrt(mean((polyval(Poly_World2Image, LensAngle*pi/180)-polyval(Poly_World2Image_design2, LensAngle*pi/180)).^2)); % In radians
%     RMSE_Poly_World2Image = min(RMSE1_Poly_World2Image, RMSE2_Poly_World2Image); % Just select the one which is smaller, kind of auto selection fo degrees and radians results
   
           
    
    
%     figure(10)
%     hold on, plot (polyval(Poly_Image2World, LensDist), LensDist, 'b-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%     if(RMSE_Poly_Image2World == RMSE1_Poly_Image2World)
%         hold on, plot (polyval(Poly_Image2World_design1, LensDist), LensDist, 'r-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%     end
%     if(RMSE_Poly_Image2World == RMSE2_Poly_Image2World)
%         hold on, plot (polyval(Poly_Image2World_design2, LensDist), LensDist, 'r-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%     end
%
%     figure(10)
%     if(RMSE_Poly_World2Image == RMSE1_Poly_World2Image)
%         hold on, plot (polyval(Poly_World2Image, LensAngle), LensAngle, 'b-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%         hold on, plot (polyval(Poly_World2Image_design1, LensAngle), LensAngle, 'r-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%     end
%     if(RMSE_Poly_World2Image == RMSE2_Poly_World2Image)
%         hold on, plot (polyval(Poly_World2Image, LensAngle*pi/180), LensAngle*pi/180, 'b-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%         hold on, plot (polyval(Poly_World2Image_design2, LensAngle*pi/180), LensAngle*pi/180, 'r-'); % Design grid, which is not the regular grid in LensDist case, plotted BLUE
%     end
    

end
