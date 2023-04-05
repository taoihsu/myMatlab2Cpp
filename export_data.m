function ocam_model = export_data(ocam_model)
fprintf(1,'\n------------------------------------------------------------------\n');
fprintf(1,'Stage-V.');
fprintf(1,'\nExporting calibration parameters to a text file.');

invpol = findinvpoly(ocam_model.ss, sqrt((ocam_model.width/2)^2+(ocam_model.height/2)^2));
ocam_model.invpol = invpol;
%invpol'

%fid = fopen('calib_results_Zuerich_using3Dpoints.txt', 'w');
fid = fopen('Z:\Source code\Matlab\Scaramuzza_OCamCalib_v3.0_win\undistortFunctions\undistort\undistort\calib_results_POVRay_IPR.txt', 'w');

fprintf(fid,'#polynomial coefficients for the DIRECT mapping function (ocam_model.ss in MATLAB). These are used by cam2world\n\n');

fprintf(fid,'%d ',length(ocam_model.ss)); %write number of coefficients
for i = 1:length(ocam_model.ss)
    fprintf(fid,'%e ',ocam_model.ss(i));
end

fprintf(fid,'\n\n');

fprintf(fid,'#polynomial coefficients for the inverse mapping function (ocam_model.invpol in MATLAB). These are used by world2cam\n\n');

fprintf(fid,'%d ',length(invpol)); %write number of coefficients
for i = 1:length(invpol)
    fprintf(fid,'%f ',invpol(end-i+1));
end

fprintf(fid,'\n\n');

fprintf(fid,'#center: "row" and "column", starting from 0 (C convention)\n\n');

fprintf(fid,'%f %f\n\n',ocam_model.yc-1, ocam_model.xc-1);

fprintf(fid,'#affine parameters "c", "d", "e"\n\n');

fprintf(fid,'%f %f %f\n\n',ocam_model.c, ocam_model.d, ocam_model.e);

fprintf(fid,'#image size: "height" and "width"\n\n');

fprintf(fid,'%d %d\n\n',ocam_model.height, ocam_model.width);

fclose(fid);