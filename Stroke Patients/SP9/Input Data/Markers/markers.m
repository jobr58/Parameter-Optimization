
subject = 'SP9';
file_prefix = strcat(subject, '_MVC35_');
muscles = [ "GM", "GM", "GM",       ...
            "SOL", "SOL",           ...
            "TA1", "TA1", "TA1",    ...
            "TA2",                  ...
            "TA3"];
        
degrees = [ "0", "5", "20",     ...
            "0", "5",           ...
            "0", "5", "20",     ...
            "0",                ...
            "20"];
        
muscle_names = strings(size(muscles));
for i = 1:length(muscles)
   muscle_names(i) = strcat(degrees(i), 'deg_', muscles(i));
end

for i=1:length(muscle_names)
        filepath = strcat(file_prefix, muscle_names(i), '/');
        load(strcat(filepath, 'Markers'))
        figure()
        subplot(3,1,1), plot(Markers.RawData(:,end-2))
        title(strcat(subject, ', ', muscle_names(i)))
        subplot(3,1,2), plot(Markers.RawData(:,end-1))
        subplot(3,1,3), plot(Markers.RawData(:,end))
end