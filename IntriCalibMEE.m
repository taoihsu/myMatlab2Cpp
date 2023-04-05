function Parameters  = IntriCalibMEE(Camera)
warning off; 




fname = Camera.image_fname;
config_fname = Camera.config_fname;
lens_identifier = Camera.lens_identifier;
%roundtableOffset = Camera.roundtable_offset;

Debug = Camera.debug;

calib_config = import_OcamCalib3D_config(config_fname);
calib_config.lens_identifier = lens_identifier;

calib_config.roundtableOffset.x = Camera.roundtable_offset(1);
calib_config.roundtableOffset.y = Camera.roundtable_offset(2);
calib_config.roundtableOffset.z = Camera.roundtable_offset(3);

calib_config.left_dot_cognex.x = Camera.leftDot(1); % if 9999, auto detection will be performed
calib_config.left_dot_cognex.y = Camera.leftDot(2); % if 9999, auto detection will be performed
calib_config.right_dot_cognex.x = Camera.rightDot(1); % if 9999, auto detection will be performed
calib_config.right_dot_cognex.y = Camera.rightDot(2); % if 9999, auto detection will be performed


% Following is set for IntriCalibMEE that it will always run in production mode
% Principal point estimation mode is production means pp is searched close to center of Macbeth chart
calib_config.pp_mode = 'production';


Parameters.fname = fname;

fprintf(1,'\n===================================================');
% Intrinsic camera calibration algorithm version
% Version 1.0 was the software by Uwe which didn't go into product line
% Version 2.0 starts with Scaramuzza based 3D calibration points algorithm
Intrinsic_algo_major_rev = 2.0;
Intrinsic_algo_minor_rev = 3.0;

% EEPROM Map revision
% Version 0.1 is the initial test revision
EEPROM_Map_major_rev = 1.0;
EEPROM_Map_minor_rev = 0.0;

fprintf(1,'\nMagna Intrisic Camera Calibration (IntriCalibMEE v%d.%d)',Intrinsic_algo_major_rev, Intrinsic_algo_minor_rev);
fprintf(1,'\nImage for calibration: %s', fname);
fprintf(1,'\nConfiguration file: %s', config_fname);
%fprintf(1,'\nRoundtable offset (mm): %f', roundtableOffset);
fprintf(1,'\nRoundtable offsets (mm): x: %f, y: %f, z: %f', calib_config.roundtableOffset.x, calib_config.roundtableOffset.y, calib_config.roundtableOffset.z);
fprintf(1,'\nLeft dot from Cognex (pixels): x: %f, y: %f', calib_config.left_dot_cognex.x, calib_config.left_dot_cognex.y);
fprintf(1,'\nRight dot from Cognex (pixels): x: %f, y: %f', calib_config.right_dot_cognex.x, calib_config.right_dot_cognex.y);
fprintf(1,'\nDebug option: %d\n', Debug);



calib_input = calibration_prepare(calib_config, fname, Debug);

calib_input.fast = 1; % = 1 Require mex files for compilation
calib_output = calibration_scaramuzza_singh(calib_input);
[calib_output.RMSE_Poly_I2W, calib_output.RMSE_Poly_W2I]= compare_with_design(calib_config, calib_output.Poly_Image2World, calib_output.Poly_World2Image);
fprintf(1,'\nRMSE error (design and calibration Poly_Image2World and Poly_World2Image): %f, %f', calib_output.RMSE_Poly_I2W, calib_output.RMSE_Poly_W2I);

Parameters.EEPROM_Map_revision = [EEPROM_Map_major_rev EEPROM_Map_minor_rev];

Parameters.intrinsic_algo_revision = [Intrinsic_algo_major_rev Intrinsic_algo_minor_rev];

Parameters.principal_point = calib_output.PP_measured;
Parameters.RMSE = [calib_output.RMSE_Poly_I2W, calib_output.RMSE_Poly_W2I];
Parameters.err = [calib_output.err(1), calib_output.err(2), calib_output.err(3), calib_output.stderr(1), calib_output.stderr(2), calib_output.stderr(3)];
Parameters.pixelwise_err = [calib_output.pixelwise_err(1), calib_output.pixelwise_err(2), calib_output.pixelwise_err(3), calib_output.pixelwise_err(4), 0, 0];
Parameters.Poly_Image2World = calib_output.Poly_Image2World(end:-1:1);
Parameters.Poly_World2Image = calib_output.Poly_World2Image(end:-1:1);
Parameters.scaramuzza_dirpol = calib_output.scaramuzza_dirpol;
Parameters.scaramuzza_invpol = calib_output.scaramuzza_invpol;
Parameters.intrinsicBox2D = calib_input.intrinsicBox2D;

Parameters.Cam_translations = calib_output.Cam_translations;
%Not needed in OCamCalib3D% Parameters.Cam_rotations = calib_output.Cam_rotations;

Parameters.effective_focal_length = 1.00;%calib_output.effective_focal_length; % should be different for directional cameras
Parameters.field_of_view = calib_config.field_of_view;
Parameters.image_size = [calib_input.width, calib_input.height];
Parameters.pixel_size = [calib_input.pixel_pitch_mm, calib_input.pixel_pitch_y_mm]; % pixel_pitch_x_mm is defined simply as pixel_pitch_mm


Parameters.sucess = sucessDecision(Parameters, calib_config);

% Below speciality of Version 2.2
% Systamatic shift of 2 pixels in y-direction is introduced due to inconsistancy in Greenbox software image and ECU image
Parameters.principal_point = Parameters.principal_point + [0, 2];


fprintf(1,'===================================================\n');
warning on; 
clearvars -except Parameters

end

%mcc -v -W cpplib:libMagnaIC -T link:lib MagnaIC
%mcc -v -W cpplib:MagnaICexe -T link:lib MagnaICexe


