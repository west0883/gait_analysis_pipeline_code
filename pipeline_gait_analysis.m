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
parameters.loop_variables.periods = parameters.periods.condition(1:194); % Don't include full_onset & full_offset 
parameters.loop_variables.conditions = {'motorized'; 'spontaneous'};
parameters.loop_variables.conditions_stack_locations = {'stacks'; 'spontaneous'};
parameters.loop_variables.variable_type = {'response variables', 'correlations'};
parameters.loop_variables.paws = {'FL', 'HL'};
parameters.loop_variables.body_parts =  {'FR', 'FL', 'HL', 'tail', 'nose', 'eye'};
parameters.loop_variables.velocity_directions = {'x', 'y', 'total_magnitude', 'total_angle'};
parameters.loop_variables.type_tags = {'allPeriods', 'longWalk_motorized', 'longWalk_spontaneous'}; % For concatenated majority of peiods and the long versions of motorized & spontaneous walk

parameters.average_and_std_together = false;

%% Segment body velocities based on long periods: Motorized
% (similar to paw_velocity_pipeline_code.m)
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator';
                   'body_part', {'loop_variables.body_parts'}, 'body_part_iterator';
                   'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator' };

% Skip any files that don't exist (spontaneous or problem files)
parameters.load_abort_flag = true; 

% Dimension of different time range pairs.
parameters.rangePairs = 1; 

% 
parameters.segmentDim = 1;
parameters.concatDim = 2;

% Are the segmentations the same length? (If false, will put outputs into
% cell array)
parameters.uniformSegments = false;

% Input values. 
% Extracted timeseries.
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\paw velocity\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'velocity', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'velocity.', 'body_part', '.', 'velocity_direction'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';
% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\motorized\period instances\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'long_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'long_periods.walk'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\body\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\motorized\', 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_longPeriods_walk', '_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'velocity_direction';

RunAnalysis({@SegmentTimeseriesData}, parameters);

%% Segment body velocities based on long periods: Spontaneous
% (similar to paw_velocity_pipeline_code.m)
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator';
                   'body_part', {'loop_variables.body_parts'}, 'body_part_iterator';
                   'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator' };

% Skip any files that don't exist (spontaneous or problem files)
parameters.load_abort_flag = true; 

% Dimension of different time range pairs.
parameters.rangePairs = 1; 

% 
parameters.segmentDim = 1;
parameters.concatDim = 2;

% Are the segmentations the same length? (If false, will put outputs into
% cell array)
parameters.uniformSegments = false;

% Input values. 
% Extracted timeseries.
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\paw velocity\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'velocity', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'velocity.', 'body_part', '.', 'velocity_direction'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';
% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\spontaneous\segmented behavior periods\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'long_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'long_periods.walk'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\body\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\spontaneous\', 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_longPeriods_walk', '_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'velocity_direction';

RunAnalysis({@SegmentTimeseriesData}, parameters);

%% Concatenate long periods -- motorized

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'body_part', {'loop_variables.body_parts'}, 'body_part_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator';
                    };

parameters.concatDim = 1;
%parameters.concatenation_level = 'day';
parameters.concatenate_across_cells = true;

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\motorized',  '\' 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename = {'segmented_timeseries_longPeriods_walk_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\body\concatenated velocity\'], 'body_part', '\', 'velocity_direction', '\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Concatenate long periods -- spontaneous 

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
               'body_part', {'loop_variables.body_parts'}, 'body_part_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').spontaneous'}, 'stack_iterator';
                    };

parameters.concatDim = 1;
%parameters.concatenation_level = 'day';
parameters.concatenate_across_cells = true;

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\spontaneous',  '\' 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename = {'segmented_timeseries_longPeriods_walk_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\body\concatenated velocity\'], 'body_part', '\', 'velocity_direction', '\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Find peaks & depressions in x velocity traces for both left paws: 
% All periods besides long rest & walk; motorized and spontaneous

% Using peakdet.m 
% this worked well; a is a paw velocity trace:
% b = a - mean(a);
% [pks,dep,pid,did] = peakdet(b, 0.05 , 'zero', 2);

% Should use x-velocity only to find strides

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods'}, 'period_iterator';
                };

parameters.timeDim = 1;
parameters.instanceDim = 2;
% Minnimum height from mean to count as a peak
parameters.peakMinHeight = 0.05;
% Minnimum time point separation between peaks to count as different peaks
% (4 = 5 Hz stride)
parameters.peakMinSeparation = 4; 
parameters.instancesAsCells = false;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\concatenated velocity\'], 'paw', '\', 'x', '\both conditions\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% peaks
parameters.loop_list.things_to_save.peaks.dir = {[parameters.dir_exper 'behavior\gait analysis\x peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.peaks.filename = {'x_peaks.mat'};
parameters.loop_list.things_to_save.peaks.variable = {'x_peaks{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.peaks.level = 'mouse';
% velocities segmented into strides
parameters.loop_list.things_to_save.segmentations.dir = {[parameters.dir_exper 'behavior\gait analysis\stride segmentations\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations.filename = {'stride_segmentations_allPeriods.mat'};
parameters.loop_list.things_to_save.segmentations.variable = {'stride_segmentations{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmentations.level = 'mouse';

RunAnalysis({@FindStrides}, parameters);

%% Long walk: find peaks & depressions in x velocity traces for both left paws: 
% motorized and spontaneous as different iterators (?) 

% For continued walk, use the not-brokendown timeseries (because 1 s is too
% short to get good strides)

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'condition', {'loop_variables.conditions'}, 'condition_iterator';
                };

parameters.timeDim = 1;
parameters.instanceDim = 2;
parameters.peakMinHeight = 0.05;
% Minnimum time point separation between peaks to count as different peaks
% (4 = 5 Hz stride)
parameters.peakMinSeparation = 4; 
parameters.instancesAsCells = true; 

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\concatenated velocity\'], 'paw', '\', 'x', '\', 'condition', '\', 'mouse', '\'};
parameters.loop_list.things_to_loagd.data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'condition';

% Outputs
% peaks
parameters.loop_list.things_to_save.peaks.dir = {[parameters.dir_exper 'behavior\gait analysis\x peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.peaks.filename = {'x_peaks_longWalk_', 'condition', '.mat'};
parameters.loop_list.things_to_save.peaks.variable = {'x_peaks'}; 
parameters.loop_list.things_to_save.peaks.level = 'condition';
% velocities segmented into strides
parameters.loop_list.things_to_save.segmentations.dir = {[parameters.dir_exper 'behavior\gait analysis\stride segmentations\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations.filename = {'stride_segmentations_longWalk_', 'condition', '.mat'};
parameters.loop_list.things_to_save.segmentations.variable = {'stride_segmentations'}; 
parameters.loop_list.things_to_save.segmentations.level = 'condition';

RunAnalysis({@FindStrides}, parameters);


%% Concatenate segmentations of long walk motorized, spontaneous to all periods
% So you can run next steps all together

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag',  {'loop_variables.type_tags'}, 'type_tag_iterator';
               };

parameters.concatDim = 1;
parameters.concatenation_level = 'type_tag';
parameters.concatenate_across_cells = true;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\stride segmentations\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations'}; 
parameters.loop_list.things_to_load.data.level = 'type_tag';
% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\stride segmentations\concatenated periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'stride_segmentations', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'stride_segmentations'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);