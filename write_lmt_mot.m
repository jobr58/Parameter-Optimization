function [] = write_lmt_mot(folder, JointLabel, a, b, n, Labels, lmtData, tag)
%printData(folder,time,EMGsData,EMGsLabels, tag)
%Data =[time MotData];

nRows = (n+1).^length(Labels);%length(Data);
nCols = length(Labels);   % plus time

fid = fopen([folder, filesep 'lmt' tag], 'w');

%fprintf(fid,'Coordinates\n');

% fprintf(fid,'nRows=%g\n', nRows);
% fprintf(fid,'nColumns=%g\n',nCols); 
% fprintf(fid, 'inDegrees=yes\n');
% fprintf(fid,'endheader\n');
for i=1:length(JointLabel)
    fprintf(fid,'%10s %d %d %d\n',JointLabel{i},a(i),b(i),n);
end
for i = 1:nCols
	fprintf(fid, '%10s\t', Labels{i});
end
% Write data.
for i = 1:nRows
    fprintf(fid, '\n');
    for j=1:nCols
        fprintf(fid,'%10f\t',lmtData(i,j));       
    end
end

fclose(fid);