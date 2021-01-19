function [] = write_US_mot(folder, time, MotData, Labels, tag, muscle, degree)
%printData(folder,time,EMGsData,EMGsLabels, tag)
Data =[time MotData];

nRows = length(Data);
nCols = length(Labels)+1;   % plus time

filename = strcat('US_', muscle, '_', degree);
fid = fopen(strcat(folder, filename, tag), 'w');

fprintf(fid,'USFL\n');

fprintf(fid,'nRows=%g\n', nRows);
fprintf(fid,'nColumns=%g\n',nCols); 
fprintf(fid, 'inDegrees=yes\n');
fprintf(fid,'endheader\n');

% Write column labels.
%fprintf(fid, '%20s\t', 'time');
fprintf(fid,'time');
fprintf(fid, '\t');
for i = 1:nCols-1
	fprintf(fid,'%s\t',Labels{i});
end

% Write data.
for i = 1:nRows
    fprintf(fid, '\n');
    for j=1:nCols
        if j == 1
            fprintf(fid,'%g\t',Data(i));
        else
            fprintf(fid,'%10f\t',Data(i,j));
        end
    end
end

fclose(fid);