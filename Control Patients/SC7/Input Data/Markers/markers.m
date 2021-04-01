
subject = '7';
muscle_names = ["GM", "Sol", "TA1", "TA2"];
degrees = ["0", "10", "20", "5"];

for i=1:length(muscle_names)
    for j=1:length(degrees)
        filepath = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i), '/');
        load(strcat(filepath, 'Markers'))
        figure()
        subplot(3,1,1), plot(Markers.RawData(:,22))
        title(strcat('SC', subject, ', ', degrees(j), 'deg, ', muscle_names(i)))
        subplot(3,1,2), plot(Markers.RawData(:,23))
        subplot(3,1,3), plot(Markers.RawData(:,24))
        
    end
end