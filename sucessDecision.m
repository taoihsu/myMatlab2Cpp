function sucess = sucessDecision(Parameters, calib_config)

sucess = 0;

% DESIGN
% Any of following calib_output values will lead to calibration failure
% 1. Average reprojection error is more than 0.9 pixels
% or
% 2. RMSE in Poly_I2W is more than 0.01
% or
% 3. RMSE in Poly_W2I is more than 0.01
% or
% 4. Maximal pixelwise error in x-direction is more than 5 pixels
% or
% 5. Maximal pixelwise error in y-direction is more than 5 pixels
% or
% 6. Estimated camera translation in x-direction is more than 4 mm
% or
% 7. Estimated camera translation in y-direction is more than 4 mm

% PRACTICAL
% Any of following calib_output values will lead to calibration failure
% 1. Average reprojection error is more than 1.4 pixels
% or
% 2. RMSE in Poly_I2W is more than 0.05
% or
% 3. RMSE in Poly_W2I is more than 0.05
% or
% 4. Maximal pixelwise error in x-direction is more than 6 pixels
% or
% 5. Maximal pixelwise error in y-direction is more than 6 pixels
% or
% 6. Estimated camera translation in x-direction is more than 4 mm
% or
% 7. Estimated camera translation in y-direction is more than 4 mm



fprintf(1,'\n------------------------------------------------------------------');

if(Parameters.err(1) <= calib_config.Average_reprojection_error_threshold) % Camera calibration is sucessful if average reprojection error is better than 0.9 pixel
    sucess = 1;
else
    fprintf(1, strcat('\nAverage reprojection is more than <', num2str(calib_config.Average_reprojection_error_threshold),'> pixels.')); % Default is 0.9
end

%OR
if(Parameters.RMSE(1) > calib_config.RMSE_in_distortion_polynomials_threshold) % Camera calibration fails when RMSE in Poly_I2W is more than 0.01
%   fprintf(1,'\nWARNING...');
    sucess = 0;
    fprintf(1,strcat('\nRMSE in Poly_I2W is more than <', num2str(calib_config.RMSE_in_distortion_polynomials_threshold),'>.')); % Default is 0.01
end
%OR
if(Parameters.RMSE(2) > calib_config.RMSE_in_distortion_polynomials_threshold) % Camera calibration fails when RMSE in Poly_W2I is more than 0.01
%   fprintf(1,'\nWARNING...');
    sucess = 0;
    fprintf(1,strcat('\nRMSE in Poly_W2I is more than <', num2str(calib_config.RMSE_in_distortion_polynomials_threshold),'>.')); % Default is 0.01
end
% Ford run as Chrysler, or Chrysler run as Ford will fail also with above settings

%OR
if(Parameters.pixelwise_err(1) > calib_config.Maximal_pixelwise_error_threshold) % Camera calibration fails when maximal pixelwise error in x-direction is more than 5 pixels
    sucess = 0;
    fprintf(1, strcat('\nMaximal pixelwise error in x-direction is more than <', num2str(calib_config.Maximal_pixelwise_error_threshold),'> pixels.')); % Default is 0.9
end
%OR
if(Parameters.pixelwise_err(3) > calib_config.Maximal_pixelwise_error_threshold) % Camera calibration fails when maximal pixelwise error in y-direction is more than 5 pixels
    sucess = 0;
    fprintf(1, strcat('\nMaximal pixelwise error in y-direction is more than <', num2str(calib_config.Maximal_pixelwise_error_threshold),'> pixels.')); % Default is 0.9
end

%OR
if(abs(Parameters.Cam_translations(1)) > calib_config.Estimated_camera_translation_threshold) % Camera calibration is sucessful if camera tranlsation in x, i.e. Tx is less than 4 mm
    sucess = 0;
    fprintf(1, strcat('\nEstimated camera translation in x is more than <', num2str(calib_config.Estimated_camera_translation_threshold),'> mm.')); % Default is 4
end
%OR
if(abs(Parameters.Cam_translations(2)) > calib_config.Estimated_camera_translation_threshold) % Camera calibration is sucessful if camera tranlsation in y, i.e. Tx is less than 4 mm
    sucess = 0;
    fprintf(1, strcat('\nEstimated camera translation in y is more than <', num2str(calib_config.Estimated_camera_translation_threshold),'> mm.')); % Default is 4
end


switch sucess
    case 0
        fprintf(1,'\nCALIBRATION FAILED.\n');
    case 1
        fprintf(1,'\nCALIBRATION SUCESSFUL.\n');
end



end

