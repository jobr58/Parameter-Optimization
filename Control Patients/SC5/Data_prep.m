clc; clear variables; close all;
addpath E:\'Parameter Optimization Project'\'US Decompressed'\'MATLAB Code'\SharedCode
input_path = './Input Data/';
output_path = './Output Data/';
mkdir(output_path, 'Normalized EMG')
mkdir(output_path, 'Result Plots')

%% Adjustable variables

file_prefix = 'SC5_MVC35_';
US_file_prefix = 'US_MVC35_';
muscles = [ "GM",   "GM",   "GM",   "GM",      ...
            "SOL",  "SOL",  "SOL",  "SOL",         ...
            "TA1",  "TA1",  "TA1",  "TA1", ...
            "TA2",  "TA2",  "TA2",  "TA2"];
        
degrees = [ "0", "10", "20", "-5",    ...
            "0", "10", "20", "-5",    ...
            "0", "10", "20", "-5",    ...
            "0", "10", "20", "-5"];
        
muscle_names = strings(size(muscles));
for i = 1:length(muscles)
   muscle_names(i) = strcat(degrees(i), 'deg_', muscles(i));
end


% Same order as muscle_names
marker_indices = [  1755, 1822, 1930, 1968, ...       GM:  0 10 20 -5 
                    1905, 1922, 1929, 1978, ...       SOL: 0 10 20 -5
                    1824, 1943, 1839, 1932, ...       TA1:  0 10 20 -5 
                    1818, 1871, 1705, 2094]; ...      TA2: 0 10 20 -5
                    
% Same order as muscle_names
frequencies = [     14, 16, 14, 14, ...       GM:  0 10 20 -5 
                    14, 16, 14, 14, ...       SOL: 0 10 20 -5
                    33, 33, 33, 33, ...       TA1:  0 10 20 -5 
                    33, 33, 33, 33]; ...      TA2: 0 10 20 -5
                    
US_muscle_labels = {'med_gas_r', 'med_gas_r', 'med_gas_r', 'med_gas_r', ...
                    'soleus_r',  'soleus_r',  'soleus_r',  'soleus_r',...
                    'tib_ant_r', 'tib_ant_r', 'tib_ant_r', 'tib_ant_r',...
                    'tib_ant_r', 'tib_ant_r', 'tib_ant_r', 'tib_ant_r'};

plot_bool_filter = 0;
plot_bool_norm = 0;
plot_bool_res = 1;

%% Prepare EMG data
%---Load raw EMG and filter---
mkdir(strcat(output_path, 'Filtered EMG'))
for i=1:length(muscle_names)
    filename = strcat(file_prefix, muscle_names(i));
    load(strcat(input_path, filename))
    EMG_raw = [GM.values, SOL.values, TA.values];
    EMG_filtered = Filter_EMG(filename, EMG_raw, plot_bool_filter);
    save(strcat(output_path, 'Filtered EMG/', filename, '_Filtered'), 'EMG_filtered')
end

%---Find MVC (max)---
MVC = get_MVC_local()

%% Synchronise data files
for i=1:length(muscle_names)
    
    filename = strcat(file_prefix, muscle_names(i));
    load(strcat(input_path, filename))
    disp(strcat('Iteration number: ', num2str(i)))
    
    
    %---Load US---
    US_filename = strcat(US_file_prefix, muscle_names(i));
    US = load(strcat(input_path, US_filename));
    US_fiber_length = US.Fdat.Region.FL';
    
%     if i == 12
%         disp(filename)
%        US_fiber_length = US_fiber_length(1:200, :); 
%     end
    
    US_rate = frequencies(i);
    
    if US_rate > 30
        US_rate = 30;
    end
    
    
    %---Load Marker---
    marker_index = marker_indices(i);
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
    EMG_t_full = zeros(size(GM.values));
    for k=1:length(GM.values)-1
        EMG_t_full(k+1) = EMG_t_full(k) + GM.interval; 
    end
    %---Delay and cut data----
    EMG_N_samples = 1/GM.interval;
    C_downsampling = round(EMG_N_samples/US_rate);
    EMG_data_ds = downsample(EMG_normalized, C_downsampling); % From 1/GM.invertals to US_rate
    disp(['downsampled emg length: ', num2str(length(EMG_data_ds))])
    EMG_time_ds = downsample(EMG_t_full, C_downsampling);
    disp(['downsampled emg time length: ', num2str(length(EMG_time_ds))])
    EMG_rate = US_rate;
    EMG_time_adjust = marker_time_start_delta + abs(marker_time_adjust);
    CutFrame = int32(EMG_time_adjust*EMG_rate);% int32((marker_time_start_delta-EMG_time_ds(1))*EMG_rate);
    EMG_time_ds(1:CutFrame,:)=[];
    EMG_data_ds(1:CutFrame,:)=[];
    disp(['us_vector_length ', num2str(length(US_fiber_length))])
    R_EMG_data0 = EMG_data_ds(1:length(US_fiber_length),:);
    R_EMG_time0 = EMG_time_ds(1:length(US_fiber_length),:);
    %---Disp---
    disp(strcat('Cut Frame: ', num2str(CutFrame), ' Muscle: ', muscles(i), ' Deg: ', degrees(i)))
    %---Low Pass Filter---
    fn0 = EMG_rate/2;
    [c, d] = butter(2, 2/fn0);
    R_EMG_data0 = filtfilt(c, d, R_EMG_data0);
    
    
    %---Load Torque, Angle---
    torque = -Moment.values;
    angle = Vinkel.values;
    time = EMG_t_full;
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
    write_ik_mot(output_path, R_time0,R_AngleData0,Angle_muscle_label, Angle_file_format, muscles(i), degrees(i));
    %---Torque---
    Torque_file_format = '.sto';
    Torque_muscle_label = {'ankle_angle_r_moment'};
    write_id_sto(output_path,R_time0,R_TorqueData0,Torque_muscle_label, Torque_file_format, muscles(i), degrees(i));
    %---US---
    US_file_format = '.mot';
    US_muscle_label = US_muscle_labels(i);
    write_US_mot(output_path,R_time0,US_fiber_length,US_muscle_label, US_file_format, muscles(i), degrees(i));
    %---EMG---
    EMG_file_format = '.mot';
    EMG_muscle_labels = {'med_gas_r', 'soleus_r', 'tib_ant_r'};
    write_EMG_mot(output_path,R_time0,R_EMG_data0,EMG_muscle_labels, EMG_file_format, muscles(i), degrees(i));
    
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
        sgtitle(muscle_names(i))
        saveas(gca, fullfile(plot_path, strcat('Results_', muscles(i), '_', degrees(i))),'fig');
        saveas(gca, fullfile(plot_path, strcat('Results__', muscles(i), '_', degrees(i))),'jpg');
        
    end
    disp('-------------------------')
    disp(' ')
    
end
