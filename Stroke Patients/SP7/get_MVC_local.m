function [MVC] = get_MVC_local()

subfolder = './Output Data/Filtered EMG/';
file_prefix = 'MVC35_';
muscles = [ "GM",   "GM",   "GM",   "GM",      ...
            "SOL",  "SOL",  "SOL",  "SOL",         ...
            "TA1",  "TA1",  "TA1",  "TA1"];
        
degrees = [ "0", "10", "20", "-5",    ...
            "0", "10", "20", "-5",    ...
            "0", "10", "20", "-5"];
        
muscle_names = strings(size(muscles));
for i = 1:length(muscles)
   muscle_names(i) = strcat(degrees(i), 'deg_', muscles(i));
end

MVC = zeros(1,3);
MVC_found = zeros(3,2);
for i=1:length(muscle_names)
    for j=1:length(degrees)
        filename = strcat(subfolder, file_prefix, muscle_names(i), '_Filtered');
        f = load(filename);
        for column = 1:3
            m = max(f.EMG_filtered(:,column));
            if m > MVC(column)
                MVC(column) = m;
                MVC_found(column,:) = [i, j];
            end
        end
    end
end
disp(MVC_found)
disp(strcat('GM MVC found in: ', muscle_names(MVC_found(1,1)), ',', degrees(MVC_found(1,2))))
disp(strcat('SOL MVC found in: ', muscle_names(MVC_found(2,1)), ',', degrees(MVC_found(2,2))))
disp(strcat('TA MVC found in: ', muscle_names(MVC_found(3,1)), ',', degrees(MVC_found(3,2))))

%save(strcat('SC',subject,'_MVC'), 'MVC');
