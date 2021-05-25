
file_prefix = 'SC3_MVC35_';
muscles = [ "GM",   "GM",   "GM",   "GM",      ...
            "SOL",  "SOL",  "SOL",  "SOL",         ...
            "TA1",  "TA1",  "TA1",  "TA1", ...
            "TA2",  "TA2",  "TA2",  "TA2"];
        
degrees = [ "0", "10", "20", "5",    ...
            "0", "10", "20", "5",    ...
            "0", "10", "20", "5",    ...
            "0", "10", "20", "5"];
        
muscle_names = strings(size(muscles));
for i = 1:length(muscles)
   muscle_names(i) = strcat(degrees(i), 'deg_', muscles(i));
end

for i=1:length(muscle_names)
        filepath = strcat(file_prefix, muscle_names(i), '/');
        load(strcat(filepath, 'Markers'))
        figure()
        subplot(3,1,1), plot(Markers.RawData(:,22))
        title(strcat(file_prefix, muscle_names(i)))
        subplot(3,1,2), plot(Markers.RawData(:,23))
        subplot(3,1,3), plot(Markers.RawData(:,24))
        
end