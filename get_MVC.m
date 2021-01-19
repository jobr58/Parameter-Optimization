function [MVC] = get_MVC(subject)

subfolder = './Output Data/Filtered EMG/';
muscle_names = ["GM", "Sol", "TA1", "TA2"];
degrees = ["0", "10", "-5", "20"];

MVC = zeros(1,3);
m = 0;
for i=1:length(muscle_names)
    for j=1:length(degrees)
        filename = strcat(subfolder, 'SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i), '_Filtered');
        f = load(filename);
        for column = 1:3
            m = max(f.EMG_filtered(:,column));
            if m > MVC(column)
                MVC(column) = m;
                
            end
        end
    end
end

%save(strcat('SC',subject,'_MVC'), 'MVC');
