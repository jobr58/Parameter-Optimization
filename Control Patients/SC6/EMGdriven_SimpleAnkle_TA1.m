%% Example EMG driven simulation for the ankle joint

% In this example we estimate parameters of the calf muscles and tibialis
% anterior using an EMG driven simulation for the ankle joint only.

% clear variables and command window
clear; clc;close all;
addpath(genpath('C:\Users\foo\Documents\All\Parameter Optimization Project\MuscleRedundancySolver'));
addpath('C:\Users\foo\Documents\All\Parameter Optimization Project\casadi-windows-matlabR2016a-v3.5.5');
%% Input information
% Add here the paths of IK, ID , US and EMG data trials you want to work with
% Misc.IKfile  = {fullfile(pwd,'ik.mot')};
% Misc.IDfile  = {fullfile(pwd,'inverse_dynamics.sto')};
% Misc.EMGfile = {fullfile(pwd,'emg.mot')};
% Misc.USfile = {fullfile(pwd,'US.mot')};
DataPath = ['./Output Data/'];

% Add here the paths of IK, ID and US data trials you want to work with
% As example we use trial 1 2 & 4 
Misc.IKfile = {     fullfile(DataPath,'ik_TA1_0.mot'); ...
                    fullfile(DataPath,'ik_TA1_10.mot'); ...
                    fullfile(DataPath,'ik_TA1_20.mot'); ...
                    fullfile(DataPath,'ik_TA1_-5.mot')};
            
Misc.IDfile = {     fullfile(DataPath,'inverse_dynamics_TA1_0.sto'); ...
                    fullfile(DataPath,'inverse_dynamics_TA1_10.sto'); ...
                    fullfile(DataPath,'inverse_dynamics_TA1_20.sto'); ...
                    fullfile(DataPath,'inverse_dynamics_TA1_-5.sto')};
            
Misc.EMGfile = {    fullfile(DataPath,'emg_TA1_0.mot'); ...
                    fullfile(DataPath,'emg_TA1_10.mot'); ...
                    fullfile(DataPath,'emg_TA1_20.mot'); ...
                    fullfile(DataPath,'emg_TA1_-5.mot')};
                
Misc.USfile = {     fullfile(DataPath,'US_TA1_0.mot'); ...
                    fullfile(DataPath,'US_TA1_10.mot'); ...
                    fullfile(DataPath,'US_TA1_20.mot'); ...
                    fullfile(DataPath,'US_TA1_-5.mot')}; % in mm


%-------------
model_path   = {fullfile(pwd, 'S6.osim')};
Out_path     = fullfile(pwd,'Results_SimpeAnkle_TA1'); % folder to store results
plot_path = strcat(Out_path, '\figures');
%time         = [7.05 17.5]; 
% Get start and end time of the different files (you can also specify this
% manually)
time = zeros(size(Misc.IKfile,1),2);
for i = 1:size(Misc.IKfile,1)
    IK = importdata(Misc.IKfile{i});
    time(i,:) = [IK.data(1,1) IK.data(end,1)];
end
%% Settings

% name of the resuls file
Misc.OutName ='MVC_TA1_';

% select degrees of freedom
Misc.DofNames_Input={'ankle_angle_r'};    % select the DOFs you want to include in the optimization

% select muscles
Misc.MuscleNames_Input = {'med_gas_r','soleus_r','tib_ant_r'};

% Set the tendon stiffness of all muscles
Misc.kT = [];      % default way to set tendon stiffenss (default values is 35)

% Settings for estimating tendon stiffness
Misc.Estimate_TendonStiffness = {'med_gas_r','soleus_r'}; % Names of muscles of which tendon stifness is estimated
Misc.lb_kT_scaling = 0.1; % Lower bound for scaling generic tendon stiffness
Misc.ub_kT_scaling = 2.2; % Upper bound for scaling generic tendon stiffness
Misc.Coupled_TendonStiffness = {'med_gas_r','soleus_r'}; % Couple muscles that should have equal tendon stifness

% Settings for estimating optimal fiber length
Misc.Estimate_OptimalFiberLength = {'med_gas_r','soleus_r','tib_ant_r'}; % Names of muscles of which optimal fiber length is estimated - slack length is estimated for these muscles as well
Misc.lb_lMo_scaling = 0.1; % Lower bound for scaling optimal fiber length
Misc.ub_lMo_scaling = 2.2; % Upper bound for scaling optimal fiber length
Misc.lb_lTs_scaling = 0.1; % Lower bound for scaling tendon slack length
Misc.ub_lTs_scaling = 2.2; % Upper bound for scaling tendon slack length
Misc.Coupled_fiber_length = {'med_gas_r','soleus_r'}; % Couple muscles that should have equal optimal fiber length
Misc.Coupled_slack_length = {'med_gas_r','soleus_r'}; % Couple muscles that should have equal tendon slack length

% Select muscle for which you want the fiberlengths to track the US data
%-------------------------
Misc.UStracking  = 1;            % Boolean to select US tracking option
Misc.USSelection = {'tib_ant_r'};%%

% Provide the correct headers in case you EMG file has not the same
% headers as the muscle names in OpenSim (leave empty when you don't want
% to use this)
Misc.EMGheaders = {'time','med_gas_r','soleus_r','tib_ant_r'};

% channels you want to use for EMG constraints
Misc.EMGSelection = {'med_gas_r','soleus_r','tib_ant_r'};

% information for the EMG constraint
Misc.EMGconstr  = 1;     		% Boolean to select EMG constrained option
Misc.EMGbounds  = [-0.3 0.3];  	% upper and lower bound for difference between simulated and measured muscle activity
Misc.BoundsScaleEMG = [0.1 1.9];
% Set weights
Misc.wEMG   = 0.001;   % weight on tracking EMG
Misc.wAct   = 0.1;
Misc.wTres  = 10;
Misc.wVm    = 0.1;
% Set weights
Misc.wlM    = [1; 1; 1; 1];          	% weight on tracking fiber length


% Plotter Bool: Boolean to select if you want to plot lots of output information of intermediate steps in the script
Misc.PlotBool = 1;
% MRS Bool: Select if you want to run the generic muscle redundancy solver
Misc.MRSBool = 1;
% Validation Bool: Select if you want to run the muscle redundancy solver with the optimized parameters
Misc.ValidationBool = 1; 	% TO DO: we should report results of EMG driven simulation as well


% set mesh frequency
Misc.Mesh_Frequency = 40;%%

%% Run muscle tendon estimator:
[Results,DatStore,Misc] = solveMuscleRedundancy(model_path,time,Out_path,Misc);

%% Plot ID moment and moment generated by muscles
for i = 1:4
    muscles = ["0", "10", "20", "-5"];
    figure();
    % inverse dynamic moments
    plot(DatStore(i).time,DatStore(i).T_exp); hold on;
    % moments generated by the muscles (Force times moment arm)
    Tmus = sum(Results.TForce(i).MTE'.*DatStore(i).MAinterp,2);
    plot(Results.Time(i).MTE,Tmus);
    xlabel('time  [s]');
    ylabel('Ankle moment [Nm]');
    legend('Inverse dynamics','EMG driven');
    title(strcat('TA1, ', muscles(i), 'degrees'))
    saveas(gca, fullfile(plot_path, strcat('TA1_', muscles(i), 'deg')),'jpg');
end
