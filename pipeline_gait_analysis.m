% pipeline_gait_analysis.m
% Sarah West
% 7/3/23

% Uses extracted and behavior-segmented traces of paw/body part velocities from
% DeepLabCut to find locomotion strides. Then uses those strides to run
% gait analysis.

%% Initial Setup  
% Put all needed paramters in a structure called "parameters", which you
% can then easily feed into your functions. 
% Use correlations, Fisher transformed, mean removed within mice (mean
% removed for at least the cases when you aren't using mice as response
% variables).

clear all; 

% Create the experiment name.
parameters.experiment_name='Random Motorized Treadmill';

% Output directory name bases
parameters.dir_base='Y:\Sarah\Analysis\Experiments\';
parameters.dir_exper=[parameters.dir_base parameters.experiment_name '\']; 

% Load mice_all, pass into parameters structure
load([parameters.dir_exper '\mice_all.mat']);
parameters.mice_all = mice_all;

% ****Change here if there are specific mice, days, and/or stacks you want to work with**** 
parameters.mice_all = parameters.mice_all; %:7); %(6); %[1 3:end]);

% Other parameters
parameters.digitNumber = 2;
parameters.yDim = 256;
parameters.xDim = 256;
parameters.number_of_sources = 32; 
parameters.indices = find(tril(ones(parameters.number_of_sources), -1));

% Load periods_nametable.m for motorized & spontaneous. Concatenate
% together

load([parameters.dir_exper 'periods_nametable.mat']);
periods_motorized = periods;
  
load([parameters.dir_exper 'periods_nametable_spontaneous.mat']);
periods_spontaneous = periods;

parameters.periods = [periods_motorized; periods_spontaneous];

clear periods periods_motorized periods_spontaneous;

% Names of all continuous variables.
parameters.continuous_variable_names = {'speed', 'accel', 'duration', 'pupil_diameter', 'tail', 'nose', 'FL', 'HL'};

% Put relevant variables into loop_variables.
parameters.loop_variables.mice_all = parameters.mice_all;
parameters.loop_variables.periods = parameters.periods.condition; 
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.conditions_stack_locations = {'stacks'; 'spontaneous'};
parameters.loop_variables.variable_type = {'response variables', 'correlations'};
parameters.loop_variables.paws = {'FL', 'HL'};

parameters.average_and_std_together = false;

%% Find peaks & depressions in total_magnitude velocity traces for both left paws
% Using peakdet.m 
% this worked well; a is a paw velocity trace:
% b = a - mean(a);
% [pks,dep,pid,did] = peakdet(b, 0.05 , 'zero', 2);

% For continued walk, use the not-brokendown timeseries (because 1 s is too
% short to get good strides)

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods'}, 'period_iterator';
                };

% Inputs
% from pipeline_paw_velocity.m 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\concatenated velocity\'], 'paw', '\', 'total_magnitude', '\both conditions\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs

