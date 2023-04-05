%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2014 Magna Electronics Europe GmbH & Co. KG
%
%   Author: Jagmal Singh - email: Jagmal.Singh@magna.de
%   
%   This program carries our linear estimation of extrinsic and intrinsic
%   camera calibration parameters. Mathematic behind this program is based
%   on seminal paper of Tsai (August 1987) and Scaramuzza's OCamCalib
%   implementation.
%   
%   Theoretical detials can be found in
%   IC_Evaluation_Scaramuzza_Algorithm.doc
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
function calib_data = calibration_linear5(calib_data)
fast = calib_data.fast; % fast = 1 will use implicit parallel programming of Matlab, fast = 0 will use for loops in estimation
fast = 1;
if(~calib_data.linearflag)
    fprintf(1,'\n------------------------------------------------------------------\n');
    fprintf(1,'Stage-I.');
    fprintf(1,'\nEstimating extrinsic and intrinsic calibration parameters.');
    fprintf(1,'\n(Using linear method).');
%    fprintf(1,'\nInitial guess for image center: (%3.2f,%3.2f)',calib_data.ocam_model.xc,calib_data.ocam_model.yc);
%    fprintf(1,'\nInitial guess for affine parameters (c,d,e):(%3.1f,%3.1f,%3.1f)\n\n',calib_data.ocam_model.c,calib_data.ocam_model.d,calib_data.ocam_model.e);
end

calib_data.disp = 0;

xc = calib_data.ocam_model.xc;
yc = calib_data.ocam_model.yc;

xp_abs =  calib_data.Xp_abs;
yp_abs =  calib_data.Yp_abs;
xp = xp_abs - xc; % We want to shift the origin to the center of image
yp = yp_abs - yc; %

Xt = calib_data.Xt;
Yt = calib_data.Yt;
Zt = calib_data.Zt;

numPkt = length(xp_abs);

if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp('Basic information');
    disp(strcat('Number of segments:  ',num2str(12)))
    disp(strcat('Number of points per segments:  ',num2str(numPkt/12)))
    disp(strcat('Number of total points:  ',num2str(numPkt)))
    %--------------------------------------------------------------------------
end

%solve Eq.-6 for aParam1, aParam2, aParam3, aParam4, aParam5, aParam6, and aParam7
if(fast ==0)
    numPar = 7;
    A=0;
    A = zeros(numPkt, numPar);
    for matRow = 1:1:numPkt

        X_i = calib_data.Xt(matRow);
        Y_i = calib_data.Yt(matRow);
        Z_i = calib_data.Zt(matRow);

        u_i = calib_data.Xp_abs(matRow);
        v_i = calib_data.Yp_abs(matRow);

        u_i = u_i - xc;
        v_i = v_i - yc;

        A(matRow, :) = [v_i*X_i, v_i*Y_i, v_i*Z_i, v_i, -u_i*X_i, -u_i*Y_i, -u_i*Z_i];
        b(matRow, 1) = u_i;

    end
end
if(fast == 1)
    A = [yp.*Xt, yp.*Yt, yp.*Zt, yp, -xp.*Xt, -xp.*Yt, -xp.*Zt];
    b = xp;
end
% A = [yp.*Xt, yp.*Yt, yp.*Zt, yp, -xp.*Xt, -xp.*Yt, -xp.*Zt];
% b = xp;

aParam = 0;
% Since the matrix is (might be) rank deficient, there are infinitely many solutions.
%aParam = A\b; % is one of the infinitely many solutions.

aParam=pinv(A)*b; % is the second one of the infinitely many solutions, but with norm smaller than the norm of any other solution.


%aParam = lsqlin(A, b);
%aParam =(A'*A)\(A'*b);

%calib_data.diff1 =  (A'*A)*aParam - (A'*b);
%aParam = linsolve(A,b);
%calib_data.diff2 =  A*aParam - b;

%figure(10)
%hold on, plot(calib_data.diff1, 'r*')
%hold on, plot(calib_data.diff2, 'b')


aParam1 = aParam(1);
aParam2 = aParam(2);
aParam3 = aParam(3);
aParam4 = aParam(4);
aParam5 = aParam(5);
aParam6 = aParam(6);
aParam7 = aParam(7);

if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp('Stage-I (Estimation of aParam1, aParam2, aParam3, aParam4, aParam5, aParam6, and aParam7)');
    disp(strcat('Number of parameters:  ',num2str(numPar)))
    disp(strcat('Rank of A:  ',num2str(rank(A))))
    if (numPar-rank(A)~=0) 
        disp(strcat('is rank deficient:  YES')) 
    else
        disp(strcat('Is matrix rank deficient?:  NO')) 
    end
    disp(strcat('Norm of parameters:  ',num2str(norm([aParam1, aParam2, aParam3, aParam4, aParam5, aParam6, aParam7]))))
end


p11 = 0; p12 = 0; p13 = 0; p14 = 0;
p21 = 0; p22 = 0; p23 = 0; p24 = 0;
p31 = 0; p32 = 0; p33 = 0; p34 = 0;

absTy = (aParam5^2 + aParam6^2 + aParam7^2)^(-1/2);

% Determine the sign of Ty
% Select the last calibration point to find the sign of Ty, becuase its far from the image center

signTy = +1; % As initial value for the sign of Ty
Ty = signTy*absTy; % Ty = p24

p11 = aParam1*Ty; % r1
p12 = aParam2*Ty; % r2

p21 = aParam5*Ty; % r4
p22 = aParam6*Ty; % r5

p14 = aParam4*Ty; % Tx

p24 = Ty;

Xi = Xt(numPkt);
Yi = Yt(numPkt);


%xptForSign = xp(numPkt); 
%yptForSign = yp(numPkt);

xptForSign = xp_abs(numPkt)-xc; % CHECK THIS
yptForSign = yp_abs(numPkt)-yc; % CHECK THIS
%xptForSign = xp_abs(numPkt); 
%yptForSign = yp_abs(numPkt);
%xptForSign = xp_abs(10)-xc; 
%yptForSign = yp_abs(10)-yc;


xForSign = p11*Xi + p12*Yi + p14;
yForSign = p21*Xi + p22*Yi + p24;

if (sign(xForSign) == sign(xptForSign) && sign(yForSign) == sign(yptForSign)) 
    signTy = +1;
else
    signTy = -1;
end


p24 = signTy*absTy;
%p24 = signTy*Ty;

if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp(strcat('Sign of Ty:  ',num2str(signTy)))
end


Sx = ((aParam1^2 + aParam2^2 + aParam3^2)^(1/2))*absTy;
if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp(strcat('Scale factor sx:  ',num2str(Sx)))
end

p11 = aParam1*p24/Sx; % r1
p12 = aParam2*p24/Sx; % r2
p13 = aParam3*p24/Sx; % r3
p14 = aParam4*p24/Sx; % Tx

p21 = aParam5*p24; % r4
p22 = aParam6*p24; % r5
p23 = aParam7*p24; % r6


% p11 = p11*sx; p12 = p12*sx; p13 = p13*sx; p14 = p14*sx;
% p21 = p21*sx; p22 = p22*sx; p23 = p23*sx; p24 = p24*sx;
% p31 = p31*sx; p32 = p32*sx; p33 = p33*sx; p34 = p34*sx;
% Sx should be anyways equal to 1

% Third row of rotation matrix is cross-product of first rows and second row of the rotation matrix
p31 = p12*p23 - p22*p13;    % r7
p32 = -p11*p23 + p21*p13;   % r8
p33 = p11*p22 - p21*p12;    % r9


% Rotation matrix
if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp('Rotation matrix: ');
end

R = [p11 p12 p13;
     p21 p22 p23;
     p31 p32 p33];
if (calib_data.disp)
    disp(strcat('Det of R:  ',num2str(det(R))))
    disp('------------------------------------------------------------------');
end
% Translation vector
T = [p14, p24, p34]';


% % % %
% % % %
% % % % WE FIX THE Z-Coordinate of camera (p34) = 0
% % % %
% % % %

% % % % % Solve Eq.-23 for a0, a2, a3, a4, and p34
% % % % 
% % % % numPar = 5;
% % % % A = 0;
% % % % A = zeros(numPkt, numPar);
% % % % b = zeros(numPkt, 1);
% % % % for matRow = 1:1:numPkt
% % % %     
% % % %     X_i = calib_data.Xt(matRow);
% % % %     Y_i = calib_data.Yt(matRow);
% % % %     Z_i = calib_data.Zt(matRow);
% % % %     
% % % %     A_i = p21*X_i + p22*Y_i + p23*Z_i + p24;
% % % %     C_i = p11*X_i + p12*Y_i + p13*Z_i + p14;
% % % %  
% % % % 
% % % %     u_i = calib_data.Xp_abs(matRow);
% % % %     v_i = calib_data.Yp_abs(matRow);
% % % % 
% % % %     u_i = u_i - xc;
% % % %     v_i = v_i - yc;
% % % %     
% % % %     b_i = (u_i + v_i)*(p31*X_i + p32*Y_i + p33*Z_i);
% % % % 
% % % %     ro_i = sqrt(u_i^2 + v_i^2); % Now it is required
% % % % 
% % % %     A(matRow, :) = [(A_i + C_i), (A_i + C_i)*ro_i^2, (A_i + C_i)*ro_i^3, (A_i + C_i)*ro_i^4, -1*(v_i + u_i)];
% % % %     b(matRow, 1) = b_i;
% % % % 
% % % % end
% % % % 
% % % % myParam = 0;
% % % % myParam=pinv(A)*b;
% % % % 
% % % % a0 = myParam(1);
% % % % a1 = 0;
% % % % a2 = myParam(2);
% % % % a3 = myParam(3);
% % % % a4 = myParam(4);
% % % % 
% % % % R34 = myParam(5);
% % % % p34 = R34;


% p11 = 1;    p12 = 0;    p13 = 0;    
p14 = 0;
% p21 = 0;    p22 = 1;    p23 = 0;    
p24 = 0;
% p31 = 0;    p32 = 0;    p33 = 1;    p34 = 0;

p34 = 0;

if(fast ==0)
    numPar = 5;
    A = 0;
    A = zeros(numPkt, numPar);
    b = zeros(numPkt, 1);
    for matRow = 1:1:numPkt

        X_i = calib_data.Xt(matRow);
        Y_i = calib_data.Yt(matRow);
        Z_i = calib_data.Zt(matRow);

        A_i = p21*X_i + p22*Y_i + p23*Z_i + p24;
        C_i = p11*X_i + p12*Y_i + p13*Z_i + p14;

        u_i = calib_data.Xp_abs(matRow);
        v_i = calib_data.Yp_abs(matRow);

        u_i = u_i - xc;
        v_i = v_i - yc;

        b_i = (u_i + v_i)*(p31*X_i + p32*Y_i + p33*Z_i) + 1*(v_i + u_i)*p34;

        ro_i = sqrt(u_i^2 + v_i^2); % Now it is required

        A(matRow, :) = [(A_i + C_i)*(ro_i)^0, (A_i + C_i)*(ro_i)^2, (A_i + C_i)*(ro_i)^3, (A_i + C_i)*(ro_i)^4, (A_i + C_i)*(ro_i)^5];
        b(matRow, 1) = b_i;

    end
end

if(fast ==1)
    ro_i = sqrt(xp.^2 + yp.^2); % Now it is required
    At = p21.*Xt + p22.*Yt + p23.*Zt + p24;
    Ct = p11.*Xt + p12.*Yt + p13.*Zt + p14;
    A = [(At + Ct).*(ro_i).^0, (At + Ct).*(ro_i).^2, (At + Ct).*(ro_i).^3, (At + Ct).*(ro_i).^4, (At + Ct).*(ro_i).^5];
    b = (xp+yp).*(p31.*Xt + p32.*Yt + p33.*Zt) + 1*(yp + xp)*p34;
end

myParam = 0;
%myParam=pinv(A)*b;
%myParam=lsqlin(A, b);
%myParam=A\b; % is one of the infinitely many solutions.
%myParam=mldivide(A, b);
%myParam=(A'*A)\(A'*b);
%myParam=bicgstab(A,b), 

% All the above methods of solving linear equations gave unstable results
%[U,S,V]=svd(A,'econ');

[U,S,V]=svd(A,0);
myParam= V*((U'*b)./diag(S));

a0 = myParam(1);
a1 = 0;
a2 = myParam(2);
a3 = myParam(3);
a4 = myParam(4);
a5 = myParam(5);

myParam = [a0, a1, a2, a3, a4, a5];


myParam = myParam;

if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp('Stage-III (Estimation of a0, a2, a3, and a4)');
    disp(strcat('Number of parameters:  ',num2str(numPar)))
    disp(strcat('Rank of A:  ',num2str(rank(A))))
    disp(strcat('Norm of parameters:  ',num2str(norm(myParam))))
    if (numPar-rank(A)~=0) 
        disp(strcat('is rank deficient:  YES')) 
    else
        disp(strcat('Is matrix rank deficient?:  NO')) 
    end
    disp(strcat('Sign of p34, i.e. of Tz:  ',num2str(sign(p34))))

    disp('------------------------------------------------------------------');
    disp('Testing (Estimation of a0, a2, a3, and a4)');
    disp('-Using 3D points on Magna intrinsic box-');
    disp('Polynomial coefficients: ')
    disp(strcat('a0: ',num2str(myParam(1))));
    disp(strcat('a1: ',num2str(myParam(2))));
    disp(strcat('a2: ',num2str(myParam(3))));
    disp(strcat('a3: ',num2str(myParam(4))));
    disp(strcat('a4: ',num2str(myParam(5))));
    disp(strcat('Norm of estimated parameters:  ',num2str(norm(myParam))))
end


if (calib_data.disp)
    % Inverse polynomial
    invpol = findinvpoly(myParam, sqrt((calib_data.ocam_model.width/2)^2+(calib_data.ocam_model.height/2)^2));
    disp('------------------------------------------------------------------');
    disp(strcat('Inverse polynomial: ',num2str(invpol)));
end

P = [p11, p12, p13, p14; p21, p22, p23, p24; p31, p32, p33, p34];
% Projection matrix
if (calib_data.disp)
    disp('------------------------------------------------------------------');
    disp('Projection matrix: ');
    P = [p11, p12, p13, p14; p21, p22, p23, p24; p31, p32, p33, p34]
end

calib_data.intitialProjection = P;


RRfin = zeros(3,4,1);
RRfin(:,:,1) = P(:,:);

calib_data.R = RRfin(:,1:3);
calib_data.T = RRfin(:,4);
calib_data.Sx = Sx;


calib_data.ocam_model.ss = myParam;
calib_data.RRfin = RRfin;

calib_data.calibrated = 1;
calib_data.n_ima = 1;
calib_data.ima_proc = 1;
calib_data.signTy = signTy;

if(~calib_data.linearflag)
    %M=[calib_data.Xt,calib_data.Yt,calib_data.Zt]; % As we already know the Z coordinates of our 3D points, which are not Zero
    %[err,stderr,MSE] = reprojectpoints_adv(calib_data.ocam_model, calib_data.RRfin, calib_data.ima_proc, calib_data.Xp_abs, calib_data.Yp_abs, M);
    
    %MSE = reprojectpoints_fun(calib_data.Xt, calib_data.Yt, calib_data.Zt, calib_data.Xp_abs, calib_data.Yp_abs, calib_data.ocam_model.xc, calib_data.ocam_model.yc, calib_data.RRfin, calib_data.ocam_model.ss, calib_data.ima_proc, calib_data.ocam_model.width, calib_data.ocam_model.height);
    
    [err,stderr,MSE,intrinsicBox2Dreprojected]=reprojectpoints(calib_data,1);

%     disp('------------------------------------------------------------------');
%     fprintf(1,'Stage-II.');
%     fprintf(1,'\nEstimating extrinsic and intrinsic calibration parameters.');
%     fprintf(1,'\n(Using linear refinement method).');
%     fprintf(1,'\nNot implemented in the version 1.0.\n\n');
 
end
calib_data.linearflag = 1; %This flag is 1 when the linear 1st level has been done
license('inuse')
%calibration_linear2(calib_data);

