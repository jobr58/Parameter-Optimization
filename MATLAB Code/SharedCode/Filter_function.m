function [emg4] = Filter_function(filename, data, plot_bool)

    muscle_names = ["GM", "Sol", "TA"];
    if plot_bool == 1
        figure()
    end
    
    for i=1:3
        emg = data(:,i);
        % Apply the Bandpass filter
        fn = 1500;
        [b,a] = butter(6,[20 500]/fn);
        emg2(:,i) = filter(b,a,emg);
        
        % Rectification of the Signal
        emg3(:,i) = abs(emg2(:,i));
        
        % Apply nth order, 0-lag, Butterworth low-pass filter
        [b,a] = butter(6, 6/fn);
        emg4(:,i) = filtfilt(b,a,emg3(:,i));
        
        % Plot emg
        if plot_bool == 1
            if i == 1
                x = [1 4 7 10];
            elseif i == 2
                x = [2 5 8 11];
            else
                x = [3 6 9 12];
            end
            
            subplot(4,3,x(1))
            plot(abs(emg))
            title(muscle_names(i))
            sgtitle(filename)
            grid on;
            
            subplot(4,3,x(2))
            plot(emg2(:,i))
            grid on;
            
            subplot(4,3,x(3))
            plot(emg3(:,i))
            grid on;
            
            subplot(4,3,x(4))
            plot (emg4(:,i))
            grid on;
        end
    end
    if plot_bool == 1
        saveas(gcf, fullfile('./Output Data/Filtered EMG/', strcat(filename,'_Filter')), 'fig');
    end
end
