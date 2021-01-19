function [EMG] = Normalize_function(filename, data, MVC, plot_bool)

    muscle_names = ["GM", "Sol", "TA"];
    EMG = zeros(size(data));
    
    for i=1:3
        EMG(:,i) = data(:,i)/MVC(i);
    end
    save(strcat('./Output Data/Normalized EMG/', filename,'_Normalized'), 'EMG');
    
    if plot_bool == 1
        figure()
        subplot(3,1,1)
        plot(EMG(:,1))
        title(muscle_names(1))
        grid on;
        
        subplot(3,1,2)
        plot(EMG(:,2))
        title(muscle_names(2))
        grid on;
        
        subplot(3,1,3)
        plot(EMG(:,3))
        title(muscle_names(3))
        grid on;
        
        sgtitle(strcat('Normalized EMG: ', filename))
        
        saveas(gcf, fullfile('./Output Data/Normalized EMG/', strcat(filename,'_Normalized')), 'fig');
    end
end