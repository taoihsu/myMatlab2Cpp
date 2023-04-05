function create_database(calib_settings)



dbpath = '';
username = '';
pwd = '';
URL = strcat('jdbc:sqlite:',calib_settings.database);
conn = database(dbpath,username,pwd,'org.sqlite.JDBC',URL);

sqlquery = ['CREATE TABLE camera_info(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, OEM TEXT, Capture TEXT, Magna_Serial_Number TEXT, Final_Assembly_Serial_Number TEXT, Final_Assembly_Part_Number TEXT, EEPROM_Map_Revision TEXT, Intrinsic_Algo_Revision TEXT)'];
curs = exec(conn,sqlquery); close(curs);

sqlquery = ['CREATE TABLE calib_info(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, Image_file_path TEXT, Width INTEGER, Height INTEGER, Pixel_size_x FLOAT, Pixel_size_y FLOAT, Focal_length FLOAT)'];
curs = exec(conn,sqlquery); close(curs);

sqlquery = ['CREATE TABLE poly_image2world(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, a0 FLOAT NOT NULL, a1 FLOAT NOT NULL, a2 FLOAT NOT NULL, a3 FLOAT NOT NULL, a4 FLOAT NOT NULL, a5 FLOAT NOT NULL )'];
curs = exec(conn,sqlquery); close(curs);
sqlquery = ['CREATE TABLE poly_world2image(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, a0 FLOAT NOT NULL, a1 FLOAT NOT NULL, a2 FLOAT NOT NULL, a3 FLOAT NOT NULL, a4 FLOAT NOT NULL, a5 FLOAT NOT NULL )'];
curs = exec(conn,sqlquery); close(curs);

sqlquery = ['CREATE TABLE scaramuzza_dirpol(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, a0 FLOAT NOT NULL, a1 FLOAT NOT NULL, a2 FLOAT NOT NULL, a3 FLOAT NOT NULL, a4 FLOAT NOT NULL, a5 FLOAT NOT NULL )'];
curs = exec(conn,sqlquery); close(curs);
sqlquery = ['CREATE TABLE scaramuzza_invpol(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, a0 FLOAT NOT NULL, a1 FLOAT NOT NULL, a2 FLOAT NOT NULL, a3 FLOAT NOT NULL, a4 FLOAT NOT NULL, a5 FLOAT NOT NULL )'];
curs = exec(conn,sqlquery); close(curs);

sqlquery = ['CREATE TABLE principal_point(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, OEM TEXT, Capture TEXT, design_pp_x FLOAT, estimated_pp_x FLOAT, design_pp_y FLOAT, estimated_pp_y FLOAT)'];
curs = exec(conn,sqlquery); close(curs);

sqlquery = ['CREATE TABLE reprojection_error(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, OEM TEXT, Capture TEXT, error_avg FLOAT, error_x FLOAT, error_y FLOAT)'];
curs = exec(conn,sqlquery); close(curs);



sqlquery = ['CREATE TABLE calib_error(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY, OEM TEXT, Capture TEXT, repro_error_avg FLOAT, repro_error_x FLOAT, repro_error_y FLOAT, rmse_poly_i2w FLOAT, rmse_poly_w2i FLOAT)'];
curs = exec(conn,sqlquery); close(curs);



sqlquery = ['CREATE TABLE twoD_points(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY)'];
curs = exec(conn,sqlquery); close(curs)
for pt = 1:200
    Point = strcat('Point_',num2str(pt));
    sqlquery = ['ALTER TABLE twoD_points ADD' '''' Point '''' 'TEXT']; 
    curs = exec(conn,sqlquery); close(curs)
end

sqlquery = ['CREATE TABLE threeD_points(camera_id TEXT UNIQUE NOT NULL PRIMARY KEY)'];
curs = exec(conn,sqlquery); close(curs)

for pt = 1:200
    Point = strcat('Point_',num2str(pt));
    sqlquery = ['ALTER TABLE threeD_points ADD' '''' Point '''' 'TEXT']; 
    curs = exec(conn,sqlquery); close(curs)
end

close(conn)



% break
% 
% 
% 
% 
% 
% 
% 
% conn
% curs = exec(conn,'select * from Poly_Image2World');
% curs = fetch(curs);
% curs.Data
% 
% % cd Database\mksqlite
% % mksqlite('open', 'testdb.db') 
% % %mksqlite('create table tbl1(one varchar(10), two smallint)');
% % %mksqlite('insert into tbl1 values(''hello'',10)');
% % %mksqlite('insert into tbl1 values(''goodbye'', 20)');
% 
% symbols = ['a':'z' 'A':'Z' '0':'9'];  MAX_ST_LENGTH = 10; stLength = randi(MAX_ST_LENGTH); nums = randi(numel(symbols),[1 stLength]); st = symbols (nums);
%  
% insertString = strcat('INSERT INTO Poly_Image2World VALUES (''', st,'''',...
%                                                             ',', num2str(calib_output.Poly_Image2World(6)),...
%                                                             ',', num2str(calib_output.Poly_Image2World(5)+rand/10),...
%                                                             ',', num2str(calib_output.Poly_Image2World(4)+rand/100),...
%                                                             ',', num2str(calib_output.Poly_Image2World(3)+rand/1000),...
%                                                             ',', num2str(calib_output.Poly_Image2World(2)+rand/10000),...
%                                                             ',', num2str(calib_output.Poly_Image2World(1)),')')                                                                                         
% curs = exec(conn, insertString);
% curs = exec(conn,'select * from Poly_Image2World');
% curs = fetch(curs);
% curs.Data
% close(curs)
% 
% %curs = exec(conn, '.tables');
% %curs = fetch(curs);
% %curs.Data
% 
% %T = tables(conn)
% %curs = exec(conn, 'DROP TABLE 2D_points_t2');
% 
% %curs = exec(conn, 'CREATE TABLE t7(a TEXT PRIMARY KEY UNIQUE, b TEXT, d INTEGER, e INTEGER, Ff INTEGER)');
% %close(curs)
% %curs = exec(conn, 'CREATE TABLE t8(a TEXT PRIMARY KEY UNIQUE, b TEXT, d INTEGER, e INTEGER, Ff INTEGER)');
% % 
% % 
% % part1 = '''CREATE TABLE TwoD_points_t14(camera_id TEXT PRIMARY KEY';
% % part2 = [];
% % for i = 1:2
% %     part2 = strcat(part2, ', ', ' point_',num2str(i), ' INTEGER');
% % end
% % part3 = ')''';
% % insertString = strcat(part1, part2, part3)
% 
% % sqlquery = ['select * from productTable'...
% % 'where productDescription = ' '''' productdesc '''']; 
% 
% %sqlquery = ['CREATE TABLE TwoD_points(camera_id TEXT PRIMARY KEY)'];
% % sqlquery = ['DROP TABLE TwoD_points'];
% % curs = exec(conn,sqlquery);
% % close(curs)
% %sqlquery = ['CREATE TABLE Person2(LastName TEXT PRIMARY KEY, FirstName TEXT,Address TEXT,Age INTEGER)'];
%     
% sqlquery = ['CREATE TABLE TwoD_points(camera_id TEXT)'];
% curs = exec(conn,sqlquery);
% close(curs)
% 
% for pt = 1:200
%     Point = strcat('Point_',num2str(pt));
%     sqlquery = ['ALTER TABLE TwoD_points ADD' '''' Point '''' 'FLOAT']; 
%     curs = exec(conn,sqlquery);
%     close(curs)
% end
% 
% % sqlquery = [insertString];
% % curs = exec(conn, sqlquery);
% %curs = exec(conn, 'CREATE TABLE TwoD_points_t14(camera_id TEXT PRIMARY KEY, point_1 INTEGER, point_2 INTEGER)');
% 
% close(conn)
% 
% 
% 
% 
% 
% % cd Database\mksqlite
% % mksqlite('open', 'testdb.db') 
% % %mksqlite('CREATE TABLE TwoD_points_t6(camera_id TEXT PRIMARY KEY UNIQUE, point_1 INTEGER, point_2 INTEGER, point_3 INTEGER, point_4 INTEGER)');
% % mksqlite(sqlquery);
% % mksqlite('close')   
% % cd ..
% % cd ..
% 
% % %mksqlite('INSERT INTO EEPROM_Block_ID_0 VALUES (''test3'', %d, %d)', calib_output.size(1), calib_output.size(2));
% % mksqlite(insertString);
% % mksqlite('close')   
% 
% 
% 
% 
% 
% %cd ..
% %cd ..
% 
% 
% 
% %end

 