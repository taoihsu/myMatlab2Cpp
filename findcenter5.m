%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2006 DAVIDE SCARAMUZZA
%   
%   Author: Davide Scaramuzza - email: davsca@tiscali.it
%   
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%   
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%   
%   You should have received a copy of the GNU General Public License
%   along with this program; if not, write to the Free Software
%   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
%   USA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Change history
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2014 Magna Electronics Europe GmbH & Co. KG
%
%   Author: Jagmal Singh - email: Jagmal.Singh@magna.de
%
%   September 2014
%   This program is modified version of Scaramuzza's findcenter.m which now
%   incorporates 3D calibration points with known coordinates instead
%   of chessboard-like pattern.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  


function calib_data = findcenter5(calib_data)
fprintf(1,'\n------------------------------------------------------------------\n');
fprintf(1,'Stage-III.');
fprintf(1,'\nComputing center coordinates.\n');

if isempty(calib_data.ima_proc) | isempty(calib_data.Xp_abs)
    fprintf(1,'\nNo corner data available. Extract grid corners before calibrating.\n');
    return;
end



if isempty(calib_data.taylor_order),
    calib_data.taylor_order = calib_data.taylor_order_default;
end

pxc=calib_data.ocam_model.xc;
pyc=calib_data.ocam_model.yc;
width=calib_data.ocam_model.width;
height=calib_data.ocam_model.height;
regwidth=(width/2); % regwidth=(width/2);
regheight=(height/2);   % regheight=(height/2);
yceil=5;%default is 10, was 5. Value 5 will make it super-fast
xceil=5;%default is 10, was 5. Value 5 will make it super-fast

tol = 10;
%+/-tol below takes care of pp error of #tol pixels only
xregstart=pxc-tol;%(pxc-regheight/2);
xregstop= pxc+tol;%(pxc+regheight/2);
yregstart=pyc-tol;%(pyc-regwidth/2);
yregstop= pyc+tol;%(pyc+regwidth/2);

fprintf(1,'Iteration ');

% yregstart
% (yregstop-yregstart)/yceil
% yregstop+1/yceil
%     
% xregstart
% (xregstop-xregstart)/xceil
% xregstop+1/xceil
    
for glc=1:5
        
    [yreg,xreg]=meshgrid(yregstart:(yregstop-yregstart)/yceil:yregstop+1/yceil, xregstart:(xregstop-xregstart)/xceil:xregstop+1/xceil);
    ic_proc=[ 1:size(xreg,1) ];
    jc_proc=[ 1:size(xreg,2) ];    
    MSEA=inf*ones(size(xreg));
    for ic=ic_proc
        for jc=jc_proc
            calib_data.ocam_model.xc=xreg(ic,jc);
            calib_data.ocam_model.yc=yreg(ic,jc);
%           hold on; plot(yc,xc,'r.');
            
            %[calib_data.RRfin,calib_data.ocam_model.ss]=calibrate(calib_data.Xt, calib_data.Yt, calib_data.Xp_abs, calib_data.Yp_abs, calib_data.ocam_model.xc, calib_data.ocam_model.yc, calib_data.taylor_order, calib_data.ima_proc);
            calib_data = calibration_linear5(calib_data);
            %calib_data = calibration_linear_refine(calib_data);
            %calibration_nonlinear(calib_data);
            if calib_data.RRfin==0
                MSEA(ic,jc)=inf;
                continue;
            end
            
            % now with Z coordinate also % MSE = reprojectpoints_fun(calib_data.Xt, calib_data.Yt, calib_data.Xp_abs, calib_data.Yp_abs, calib_data.ocam_model.xc, calib_data.ocam_model.yc, calib_data.RRfin, calib_data.ocam_model.ss, calib_data.ima_proc, calib_data.ocam_model.width, calib_data.ocam_model.height);
            
            %[MSE, intrinsicBox2DC]  = reprojectpoints_fun(calib_data.Xt, calib_data.Yt, calib_data.Zt, calib_data.Xp_abs, calib_data.Yp_abs, calib_data.ocam_model.xc, calib_data.ocam_model.yc, calib_data.RRfin, calib_data.ocam_model.ss, calib_data.ima_proc, calib_data.ocam_model.width, calib_data.ocam_model.height);
            [err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,0);

                
            %fprintf(1,'(%f, %f): %f\n',calib_data.ocam_model.xc, calib_data.ocam_model.yc, MSE);
            % reprojectpoints_fun is faster than reprojectpoints_adv
            
%obrand_start 
%speedup removed to compensate for calibration errors
%            if ic>1 & jc>1
%                if MSE>MSEA(ic-1,jc)
%                    jc_proc(find(jc_proc==jc))=inf;
%                    jc_proc=sort(jc_proc);
%                    jc_proc=jc_proc(1:end-1);
%                    continue;
%                elseif MSE>MSEA(ic,jc-1)
%                    break;
%                elseif isnan(MSE)
%                    break;
%                end
%            end
%            MSEA(ic,jc)=MSE;
%obrand_replacement

%         constraint_Tx = 6;
%         constraint_Ty = 9999;
%         if (~isnan(MSE) && abs(calib_data.T(1)*calib_data.pixel_pitch) < constraint_Tx && abs(calib_data.T(2)*calib_data.pixel_pitch) < constraint_Ty)
        if ~isnan(MSE) % X, Y position of the camera is not constrained, may give unstable results in certain critical parts.
            MSEA(ic,jc)=MSE;
        end
%obrand_end
        end
    end
%    drawnow;
    indMSE=find(min(MSEA(:))==MSEA);
    calib_data.ocam_model.xc=xreg(indMSE(1));
    calib_data.ocam_model.yc=yreg(indMSE(1));
    dx_reg=abs((xregstop-xregstart)/xceil);
    dy_reg=abs((yregstop-yregstart)/yceil);
    xregstart=calib_data.ocam_model.xc-dx_reg;
    xregstop =calib_data.ocam_model.xc+dx_reg;
    yregstart=calib_data.ocam_model.yc-dy_reg;
    yregstop =calib_data.ocam_model.yc+dy_reg;
    fprintf(1,'%d...',glc);
end
            [err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,1);

calib_data = calibration_linear5_RxyzTxyz(calib_data);
T_final_for_evaluation = calib_data.T;
R_final_for_evaluation = calib_data.R_rodrigues;
fprintf('\nFinal Tx (in mm): %f', T_final_for_evaluation(1)*calib_data.pixel_pitch);
fprintf('\nFinal Ty (in mm): %f', T_final_for_evaluation(2)*calib_data.pixel_pitch);

calib_data = calibration_linear5(calib_data);

calib_data.T_final_for_evaluation = T_final_for_evaluation;
calib_data.R_final_for_evaluation = R_final_for_evaluation;
T_final_for_evaluation = calib_data.T;
fprintf('\nFinal Tx (in mm): %f', T_final_for_evaluation(1)*calib_data.pixel_pitch);
fprintf('\nFinal Ty (in mm): %f', T_final_for_evaluation(2)*calib_data.pixel_pitch);

fprintf(1,'\nImage center after find center: (%3.3f,%3.3f)',calib_data.ocam_model.xc+calib_data.T_final_for_evaluation(1)*calib_data.pixel_pitch,...
                                                            calib_data.ocam_model.yc+calib_data.T_final_for_evaluation(2)*calib_data.pixel_pitch);
%fprintf(1,'\nImage center after find center: (%3.2f,%3.2f)',calib_data.ocam_model.xc,calib_data.ocam_model.yc);
%J% M=[calib_data.Xt,calib_data.Yt,calib_data.Zt]; % As we already know the Z coordinates of our 3D points, which are not Zero
%J% [err,stderr,MSE] = reprojectpoints_adv(calib_data.ocam_model, calib_data.RRfin, calib_data.ima_proc, calib_data.Xp_abs, calib_data.Yp_abs, M);


%J% reprojectpoints(calib_data);
%J% xc = calib_data.ocam_model.xc;
%J% yc = calib_data.ocam_model.yc;

%disp(strcat('Image center after find center:  ',num2str([calib_data.ocam_model.xc, calib_data.ocam_model.yc])))

calib_data.calibrated = 1; %This flag is 1 when the camera has been calibrated
calib_data.findcenterflag = 1; %This flag is 1 when the findcenter has been done

  
[err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,1);
license('inuse')
