clc; clear variables; close all;
addpath E:\'Parameter Optimization Project'\'US Decompressed'\'MATLAB Code'\SharedCode
input_path = './Input Data/';
output_path = './Output Data/';
mkdir(output_path, 'Normalized EMG')
mkdir(output_path, 'Result Plots')

%% Adjustable variables

subject = '2';
muscle_names = ["GM", "Sol", "TA1", "TA2"];
degrees = ["0", "10", "20", "-5"];
marker_indices = [  2188, 1622, 1839, 2030, ...          % GM:   0 10 20 -5
                    1800, 1690, 2007, 1900, ...          % SOL:  0 10 20 -5
                    1778, 1757, 1974, 1995, ...          % TA1:  0 10 20 -5
                    1942, 1975, 1807, 1871];             % TA2:  0 10 20 -5
frequencies = [ 14, 14, 14, 14, ...                      % same as above
                14, 14, 14, 14, ...
                33, 33, 33, 33, ...
                33, 33, 33, 33];
plot_bool_filter = 0;
plot_bool_norm = 0;
plot_bool_res = 1;

%% Prepare EMG data
%---Load raw EMG and filter---
mkdir(strcat(output_path, 'Filtered EMG'))
for i=1:length(muscle_names)
    for j=1:length(degrees)
        filename = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i));
        load(strcat(input_path, filename))
        EMG_raw = [GM.values, SOL.values, TA.values];
        EMG_filtered = Filter_EMG(filename, EMG_raw, plot_bool_filter);
        save(strcat(output_path, 'Filtered EMG/', filename, '_Filtered'), 'EMG_filtered')
    end
end

%---Find MVC (max)---
MVC = get_MVC(subject)

%% Synchronise data files
n=1;
for i=1:length(muscle_names)
    for j = 1:length(degrees)
        filename = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i));
        disp(strcat('Iteration number: ', num2str(n)))
        
        
        %---Load US---
        US_filename = strcat('US_MVC35_', degrees(j), 'deg_', muscle_names(i));
        US = load(strcat(input_path, US_filename));
        US_fiber_length = US.Fdat.Region.FL';
        
        US_rate = frequencies(n);
        
        if US_rate > 30
            US_rate = 30;
        end
        
        
        %---Load Marker---
        marker_index = marker_indices(n);
        %---Synchronize US---
        marker_rate = 200; 
        marker_time_adjust = 2; % Seconds, Time between EMG start and Marker start
        marker_index_adjust = marker_time_adjust*marker_rate;
        US_time_end = length(US_fiber_length)/US_rate;        
        marker_time_end = marker_index/marker_rate; % EMG
        marker_time_start_delta = marker_time_end-US_time_end;
        %---Disp---
        disp(strcat('Marker End Index: ', num2str(marker_index)))

        
        %---Load Filtered EMG---
        load(strcat(output_path, 'Filtered EMG/', filename, '_Filtered'))
        disp(strcat('Filtered EMG: ', num2str(length(EMG_filtered))))
        %---Normalize EMG---
        EMG_normalized = Normalize_EMG(filename, EMG_filtered, MVC, plot_bool_norm);
        %---Convert EMG from mat to mot---
        EMG_t_full = GM.times;
        %---Delay and cut data----
        EMG_N_samples = 1/GM.interval;
        C_downsampling = round(EMG_N_samples/US_rate);
        EMG_data_ds = downsample(EMG_normalized, C_downsampling); % From 1/GM.invertals to US_rate
        EMG_time_ds = downsample(EMG_t_full, C_downsampling);
        EMG_rate = US_rate;
        EMG_time_adjust = marker_time_start_delta + abs(marker_time_adjust);
        CutFrame = int32(EMG_time_adjust*EMG_rate);% int32((marker_time_start_delta-EMG_time_ds(1))*EMG_rate);
        EMG_time_ds(1:CutFrame,:)=[];
        EMG_data_ds(1:CutFrame,:)=[];
        R_EMG_data0 = EMG_data_ds(1:length(US_fiber_length),:);
        R_EMG_time0 = EMG_time_ds(1:length(US_fiber_length),:);
        %---Disp---
        disp(strcat('Cut Frame: ', num2str(CutFrame), ' Muscle: ', num2str(muscle_names(i)), ' Deg: ', num2str(degrees(j))))
        %---Low Pass Filter---
        fn0 = EMG_rate/2;
        [c, d] = butter(2, 2/fn0);
        R_EMG_data0 = filtfilt(c, d, R_EMG_data0);
        
        
        %---Load Torque, Angle---
        filename = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i));
        load(strcat(input_path, filename));
        torque = -Moment.values;
        disp(strcat('torque: ', num2str(length(torque))))
        angle = Vinkel.values;
        time = Moment.times;
        %---Downsample Torque, Angle---
        R_torque_data = downsample(torque, C_downsampling); % From 1/GM.invertal to US_rate
        R_angle_data = downsample(angle, C_downsampling);
        R_time = downsample(time, C_downsampling);
        %---Delay and cut data----
        R_time(1:CutFrame,:)=[]; % Remove data before US start
        R_angle_data(1:CutFrame,:)=[];
        R_torque_data(1:CutFrame,:)=[];
        R_time0=R_time(1:length(US_fiber_length),:); % Remove data after US end
        R_AngleData0=R_angle_data(1:length(US_fiber_length),:);
        R_TorqueData0=R_torque_data(1:length(US_fiber_length),:);
        
        
        %----Output Files---
        plot_path = strcat(output_path, 'Result Plots');
        %---Angle---
        Angle_file_format = '.mot'; 
        Angle_muscle_label = {'ankle_angle_r'};
        write_ik_mot(output_path, R_time0,R_AngleData0,Angle_muscle_label, Angle_file_format, muscle_names(i), degrees(j));
        %---Torque---
        Torque_file_format = '.sto'; 
        Torque_muscle_label = {'ankle_angle_r_moment'};
        write_id_sto(output_path,R_time0,R_TorqueData0,Torque_muscle_label, Torque_file_format, muscle_names(i), degrees(j));
        %---US---
        US_file_format = '.mot'; 
        US_muscle_labels = {'med_gas_r', 'soleus_r', 'tib_ant_r', 'tib_ant_r'};
        US_muscle_label = US_muscle_labels(i);
        write_US_mot(output_path,R_time0,US_fiber_length,US_muscle_label, US_file_format, muscle_names(i), degrees(j));
        %---EMG---
        EMG_file_format = '.mot'; 
        EMG_muscle_labels = {'med_gas_r', 'soleus_r', 'tib_ant_r'};
        write_EMG_mot(output_path,R_time0,R_EMG_data0,EMG_muscle_labels, EMG_file_format, muscle_names(i), degrees(j));
        
        if plot_bool_res == 1
            figure()
            subplot(3,1,1), plot(R_time0,R_TorqueData0);
            xlabel('Time')
            ylabel('Torque')
            
            subplot(3,1,2)
            plot(R_time0, R_EMG_data0); legend('GM','Sol','TA');
            xlabel('Time')
            ylabel('EMG Data')
            
            subplot(3,1,3)
            plot(R_time0, US_fiber_length); legend(muscle_names(i));
            xlabel('Time')
            ylabel('US Data')
            sgtitle(strcat(muscle_names(i), ', ', degrees(j), 'deg'))
            saveas(gca, fullfile(plot_path, strcat('Results_', muscle_names(i), '_', degrees(j))),'fig');
            saveas(gca, fullfile(plot_path, strcat('Results__', muscle_names(i), '_', degrees(j))),'jpg');
            
        end
        disp('-------------------------')
        disp(' ')
        n=n+1;
    end
end
