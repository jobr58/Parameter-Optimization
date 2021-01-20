clc; clear variables; close all;
addpath E:\'Parameter Optimization Project'\'US Decompressed'\'MATLAB Code'\SharedCode
input_path = './Input Data/';
output_path = './Output Data/';
mkdir(output_path, 'Normalized EMG')
mkdir(output_path, 'Result Plots')

%% Adjustable variables

subject = '1';
muscle_names = ["GM", "Sol", "TA1", "TA2"];
degrees = ["0", "10", "20", "-5"];
marker_indices = [  2650, 2008, 1810, 1990, ...          % GM:   0 10 20 -5
                    2227, 2128, 1820, 1952, ...          % SOL:  0 10 20 -5
                    1530, 1728, 1957, 2059, ...          % TA1:  0 10 20 -5
                    1601, 1562, 2260, 1950];             % TA2:  0 10 20 -5
plot_bool_filter = 0;
plot_bool_norm = 0;
plot_bool_res = 1;

%% Prepare EMG data
%---Load raw EMG and filter---
mkdir(strcat(output_path, 'Filtered EMG'))
for i=1:1%length(muscle_names)
    for j=1:length(degrees)
        filename = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i));
        load(strcat(input_path, filename))
        EMG_raw = [GM.values, SOL.values, TA.values];
        figure
        plot(EMG_raw)
        legend(["GM", "SOL", "TA"])
        title(strcat(muscle_names(i), degrees(j)))
        EMG_filtered = Filter_function(filename, EMG_raw, plot_bool_filter);
        save(strcat(output_path, 'Filtered EMG/', filename, '_Filtered'), 'EMG_filtered')
    end
end

%---Find MVC (max)---
MVC = get_MVC(subject);

%% Synchronise data files
n=1;
for i=1:1%length(muscle_names)
    for j = 1:length(degrees)
        filename = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i));
        disp(strcat('Iteration number: ', num2str(n)))
        
        %---Load US---
        US_filename = strcat('US_MVC35_', degrees(j), 'deg_', muscle_names(i));
        US = load(strcat(input_path, US_filename));
        US_fiber_length = US.Fdat.Region.FL';
        
        if muscle_names(i) == "GM"
            US_rate = 16;
        elseif muscle_names(i) == "Sol"
            US_rate = 16;
        elseif muscle_names(i) == "TA1"
            US_rate = 33;
        elseif muscle_names(i) == "TA2"
            US_rate = 33;
        end
        
        if US_rate > 30
            US_rate = 30;
        end
        
        %---Load Marker---
        % Path ex: Input Data\Markers\SC2_MVC35_0deg_GM
%         marker_folder_name = strcat('SC', subject, '_MVC35_', degrees(j), 'deg_', muscle_names(i), '/');
%         marker_path = strcat(input_path, 'Markers/', marker_folder_name);
%         load(strcat(marker_path, 'Markers'));
        marker_index = marker_indices(n);
        %---Synchronize US---
        marker_rate = Markers.Rate; 
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
        figure
        plot(EMG_filtered)
        title(strcat(muscle_names(i), degrees(j)))
        EMG_normalized = Normalize_function(filename, EMG_filtered, MVC, plot_bool_norm);
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
        figure
        plot(torque)
        title(strcat(muscle_names(i), degrees(j)))
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
        %---Low Pass Filter---
        fn=EMG_rate/2;
        [b,a]=butter(2,6/fn);
        R_TorqueData0=filtfilt(b,a,R_TorqueData0);
        %R_AngleData0=filtfilt(b,a,R_AngleData0);

        
        
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
        printEMGmot(output_path,R_time0,R_EMG_data0,EMG_muscle_labels, EMG_file_format, muscle_names(i), degrees(j));
        
        if plot_bool_res == 1
            figure()
            subplot(3,1,1), plot(R_time0,R_TorqueData0);
            xlabel('Time')
            ylabel('Torque')
            saveas(gca, fullfile(plot_path, strcat('Torque_', muscle_names(i), '_', degrees(j))),'fig');
            saveas(gca, fullfile(plot_path, strcat('Torque_', muscle_names(i), '_', degrees(j))),'jpg');
            
            subplot(3,1,2)
            plot(R_time0, R_EMG_data0); legend('GM','Sol','TA');
            xlabel('Time')
            ylabel('EMG Data')
            saveas(gca, fullfile(plot_path, strcat('EMG_', muscle_names(i), '_', degrees(j))),'fig');
            saveas(gca, fullfile(plot_path, strcat('EMG_', muscle_names(i), '_', degrees(j))),'jpg');
            
            subplot(3,1,3)
            plot(R_time0, US_fiber_length); legend(muscle_names(i));
            xlabel('Time')
            ylabel('US Data')
            saveas(gca, fullfile(plot_path, strcat('US_', muscle_names(i), '_', degrees(j))),'fig');
            saveas(gca, fullfile(plot_path, strcat('US_', muscle_names(i), '_', degrees(j))),'jpg');
            sgtitle(strcat(muscle_names(i), ' ', degrees(j), 'deg'))
        end
        disp('-------------------------')
        disp(' ')
        n=n+1;
    end
end
