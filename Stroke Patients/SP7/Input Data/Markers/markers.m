
label_id = 13;
muscles = [ "GM",   "GM",   "GM",   "GM",      ...
            "SOL",  "SOL",  "SOL",  "SOL",         ...
            "TA1",  "TA1",  "TA1",  "TA1"];
        
degrees = [ "0", "10", "20", "5",    ...
            "0", "10", "20", "5",    ...
            "0", "10", "20", "5"];
        
muscle_names = strings(size(muscles));
for i = 1:length(muscles)
   muscle_names(i) = strcat(degrees(i), 'deg_', muscles(i));
end

for i=1:length(muscle_names)
        filepath = strcat('MVC35_', muscle_names(i), '/');
        load(strcat(filepath, 'Markers'))
        figure()
        subplot(3,1,1), plot(Markers.RawData(:,3*label_id-2))
        title(strcat('MVC35_', muscle_names(i)))
        subplot(3,1,2), plot(Markers.RawData(:,3*label_id-1))
        subplot(3,1,3), plot(Markers.RawData(:,3*label_id))

end