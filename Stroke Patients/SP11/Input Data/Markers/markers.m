clear variables
file_prefix = 'SP11_MVC35_';
US_file_prefix = 'US_MVC35_';
muscles = [ "GM",   "GM",   "GM", ...
            "SOL",  "SOL",  "SOL", ...
            "TA1",  "TA1",  "TA1", ...
            "TA2",  "TA2",  "TA2"];
        
degrees = [ "5", "10", "20",    ...
            "5", "10", "20",    ...
            "5", "10", "20",    ...
            "5", "10", "20"];
        
muscle_names = strings(size(muscles));
for i = 1:length(muscles)
   muscle_names(i) = strcat(file_prefix, degrees(i), 'deg_', muscles(i));
end
%%
for i=1:length(muscle_names)
        filepath = strcat(muscle_names(i), '/');
        load(strcat(filepath, 'Markers'))
        figure()
        subplot(3,1,1), plot(Markers.RawData(:,22))
        title(strcat(muscle_names(i)))
        subplot(3,1,2), plot(Markers.RawData(:,23))
        subplot(3,1,3), plot(Markers.RawData(:,24))
end