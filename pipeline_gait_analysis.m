% pipeline_gait_analysis.m
% Sarah West
% 7/3/23

% Uses extracted and behavior-segmented traces of paw/body part velocities from
% DeepLabCut to find locomotion strides. Then uses those strides to run
% gait analysis.

% NOTE: From DLC, positive x is RIGHT, positive y is DOWN

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
parameters.loop_variables.conditions_stack_locations_long = {'spontaneous', 'stacks', 'stacks', 'stacks', 'stacks'}; 
parameters.loop_variables.variable_type = {'response variables', 'correlations'};
parameters.loop_variables.paws =  {'FL', 'HL', 'tail'};
parameters.loop_variables.body_parts = {'FL', 'HL', 'tail', 'nose'}; % {'FR', 'FL', 'HL', 'tail', 'nose', 'eye'};
parameters.loop_variables.velocity_directions = {'x', 'y', 'total_magnitude'}; %'total_angle'};
parameters.loop_variables.type_tags = {'longWalk_spontaneous', 'longWalk_motorized1600', 'longWalk_motorized2000', 'longWalk_motorized2400', 'longWalk_motorized2800'}; % No "allPeriods" anymore; For concatenated majority of peiods and the long versions of motorized & spontaneous walk
parameters.loop_variables.type_tags2 = {'longWalk_spontaneous', 'longWalk_motorized_1600', 'longWalk_motorized_2000', 'longWalk_motorized_2400', 'longWalk_motorized2800'};
parameters.loop_variables.motorSpeeds = {'1600', '2000', '2400', '2800'};
parameters.loop_variables.periods_withLongs = [parameters.periods.condition(1:194); {'walkLong_spon'}; {'walkLong_1600'}; {'walkLong_2000'}; {'walkLong_2400'}; {'walkLong_2800'}];
parameters.loop_variables.periods_longsOnly = [{'walkLong_spon'}; {'walkLong_1600'}; {'walkLong_2000'}; {'walkLong_2400'}; {'walkLong_2800'}];
parameters.loop_variables.peak_depression = {'depression'}; % {'peak', 'depression'};
parameters.loop_variables.velocity_directions_sublist = {'y', 'total_magnitude', 'total_angle'};
parameters.loop_variables.paws_sublist =  {'HL', 'tail'};
parameters.loop_variables.segmentation_types =  { 'stride segmentations from own x depressions', 'stride segmentations from FL x depressions'};
parameters.loop_variables.position_directions = {'x', 'y'};

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
                   'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator' ;
                   'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator';
                   };

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
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\paw velocity normalized with total magnitude\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'velocity', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'velocity.', 'body_part', '.', 'velocity_direction'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';
% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\motorized\period instances\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'long_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'long_periods.walk_', 'motorSpeed'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\motorized\', 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_longPeriods_walk_', 'motorSpeed', '_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'motorSpeed';

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
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\paw velocity normalized with total magnitude\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'velocity', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'velocity.', 'body_part', '.', 'velocity_direction'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';
% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\spontaneous\segmented behavior periods\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'long_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'long_periods.walk'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\spontaneous\', 'mouse', '\', 'day', '\'};
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
               'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator';
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
               'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator';
                    };

parameters.concatDim = 1;
%parameters.concatenation_level = 'day';
parameters.concatenate_across_cells = true;

% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\motorized',  '\' 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename = {'segmented_timeseries_longPeriods_walk_', 'motorSpeed', '_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'body_part', '\', 'velocity_direction', '\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'motorSpeed';

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
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented velocities\'], 'body_part', '\', 'velocity_direction', '\spontaneous',  '\' 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename = {'segmented_timeseries_longPeriods_walk_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Output
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'body_part', '\', 'velocity_direction', '\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Find peaks & depressions in x velocity traces for both left paws: 
% All periods besides long rest & walk, motorized and spontaneous

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
parameters.peakMinHeight = 0.1;
% Minnimum time point separation between peaks to count as different peaks
% (4 = 5 Hz stride)
parameters.peakMinSeparation = 5; 
parameters.instancesAsCells = false;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'x', '\both conditions\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_all_periods.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% peaks
parameters.loop_list.things_to_save.peaks.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.peaks.filename = {'x_peaks.mat'};
parameters.loop_list.things_to_save.peaks.variable = {'x_peaks{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.peaks.level = 'mouse';
% velocities segmented from depressions
parameters.loop_list.things_to_save.segmentations_peak.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_peak.filename = {'stride_segmentations_allPeriods.mat'};
parameters.loop_list.things_to_save.segmentations_peak.variable = {'stride_segmentations_peak{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmentations_peak.level = 'mouse';
% segmented from depressions
parameters.loop_list.things_to_save.segmentations_depression.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_depression.filename = {'stride_segmentations_allPeriods.mat'};
parameters.loop_list.things_to_save.segmentations_depression.variable = {'stride_segmentations_depression{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmentations_depression.level = 'mouse';

RunAnalysis({@FindStrides}, parameters);

%% Spontaneous long walk: find peaks & depressions in x velocity traces for both left paws

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
                };

parameters.timeDim = 1;
parameters.instanceDim = 2;
parameters.peakMinHeight = 0.1;
% Minnimum time point separation between peaks to count as different peaks
% (5 = 4 Hz stride)
parameters.peakMinSeparation = 5; 
parameters.instancesAsCells = true; 

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'x', '\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% peaks
parameters.loop_list.things_to_save.peaks.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.peaks.filename = {'x_peaks_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.peaks.variable = {'x_peaks'}; 
parameters.loop_list.things_to_save.peaks.level = 'mouse';
% velocities segmented into strides
parameters.loop_list.things_to_save.segmentations_peak.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_peak.filename = {'stride_segmentations_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.segmentations_peak.variable = {'stride_segmentations_peak'}; 
parameters.loop_list.things_to_save.segmentations_peak.level = 'mouse';

parameters.loop_list.things_to_save.segmentations_depression.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_depression.filename = {'stride_segmentations_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.segmentations_depression.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_save.segmentations_depression.level = 'mouse';

RunAnalysis({@FindStrides}, parameters);


%% Motorized long walk: find peaks & depressions in x velocity traces for both left paws

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator';
                };

parameters.timeDim = 1;
parameters.instanceDim = 2;
parameters.peakMinHeight = 0.1;
% Minnimum time point separation between peaks to count as different peaks
% (4 = 5 Hz stride)
parameters.peakMinSeparation = 5; 
parameters.instancesAsCells = true; 

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'x', '\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'motorSpeed';

% Outputs
% peaks
parameters.loop_list.things_to_save.peaks.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.peaks.filename = {'x_peaks_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.peaks.variable = {'x_peaks'}; 
parameters.loop_list.things_to_save.peaks.level = 'motorSpeed';
% velocities segmented into strides from peaks
parameters.loop_list.things_to_save.segmentations_peak.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from peaks\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_peak.filename = {'stride_segmentations_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.segmentations_peak.variable = {'stride_segmentations_peak'}; 
parameters.loop_list.things_to_save.segmentations_peak.level = 'motorSpeed';
% velocities segmented into strides from depressions
parameters.loop_list.things_to_save.segmentations_depression.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_depression.filename = {'stride_segmentations_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.segmentations_depression.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_save.segmentations_depression.level = 'motorSpeed';

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
               'peak_depression', {'loop_variables.peak_depression'}, 'peak_depression_iterator';
               'type_tag',  {'loop_variables.type_tags'}, 'type_tag_iterator';
               };

parameters.concatDim = 1;
parameters.concatenation_level = 'type_tag';
parameters.concatenate_across_cells = true;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\all periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_' 'peak_depression'}; 
parameters.loop_list.things_to_load.data.level = 'type_tag';
% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'stride_segmentations', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'stride_segmentations'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'peak_depression';

RunAnalysis({@ConcatenateData}, parameters);

%% For each period, plot, resample, take means & standard deviations 

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'peak_depression', {'loop_variables.peak_depression'}, 'peak_depression_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

% close each figure after saving it
parameters.closeFigures = true;
% the number of timepoints to resample each stride velocity segment to.
parameters.resampleLength = 10; % to 0.5 s = 10 time points

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'period';

% Outputs
% stride segmentations reformatted so strides are all on same cell level
parameters.loop_list.things_to_save.segmentations_together.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_together.filename = {'stride_segmentations_together', '.mat'};
parameters.loop_list.things_to_save.segmentations_together.variable = {'stride_segmentations_together{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmentations_together.level = 'mouse';
% resampled segmentations
parameters.loop_list.things_to_save.resampled.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.resampled.filename = {'stride_segmentations_resampled', '.mat'};
parameters.loop_list.things_to_save.resampled.variable = {'stride_segmentations_resampled{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.resampled.level = 'mouse';
% mean 
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_save.average.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';
% std
parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'stride_segmentations_std_dev', '.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'stride_segmentations_std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';
% figure: not-resampled segmentations 
parameters.loop_list.things_to_save.fig_segmentations_together.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_segmentations_together.filename = {'stride_segmentations_together_','period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_segmentations_together.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_segmentations_together.level = 'period';
% figure: resampled segmentations
parameters.loop_list.things_to_save.fig_resampled.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_resampled.filename = {'stride_segmentations_resampled_','period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_resampled.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_resampled.level = 'period';
% figure: mean and std
parameters.loop_list.things_to_save.fig_average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from '], 'peak_depression', 's\concatenated periods\','paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_average.filename = {'stride_segmentations_average_','period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_average.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_average.level = 'period';

RunAnalysis({@GaitResampling}, parameters);
parameters.closeFigures = false;
%% Plot all mices' averages of each period together

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'period', {'loop_variables.periods_withLongs'}, 'period_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 

parameters.instancesDim = 1;
parameters.ylimits = [-6 6];
parameters.mymap = flipud(hsv(7));

% Inputs
% mean 
parameters.loop_list.things_to_load.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\concatenated periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.average.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_load.average.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.average.level = 'mouse';
% std
parameters.loop_list.things_to_load.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\concatenated periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.std_dev.filename = {'stride_segmentations_std_dev', '.mat'};
parameters.loop_list.things_to_load.std_dev.variable = {'stride_segmentations_std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.std_dev.level = 'mouse';
% resampled segmentations (to get the number of instances for standard error of the mean calculation)
parameters.loop_list.things_to_load.resampled.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\concatenated periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.resampled.filename = {'stride_segmentations_resampled', '.mat'};
parameters.loop_list.things_to_load.resampled.variable = {'stride_segmentations_resampled{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.resampled.level = 'mouse';

% Outputs
% figure
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\overlays\'],'paw', '\'};
parameters.loop_list.things_to_save.fig.filename = {'overlay_','period_iterator','_', 'period', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';

RunAnalysis({@PlotMiceStrideOverlays}, parameters);

close all;
%% Average each period across mice
% include m1107, aren't comparing across spon and motorized yet
% concatenate & average

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'period', {'loop_variables.periods_withLongs'}, 'period_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 

parameters.concatDim = 1;
parameters.concatenation_level = 'mouse';
parameters.averageDim = 1;

% Don't include mouse 1100 in spontaneous averages
parameters.evaluation_instructions = {{'period_iterator = parameters.values{strcmp(parameters.keywords, "period_iterator")};'...;
                                     'mouse = parameters.values{strcmp(parameters.keywords, "mouse")};' ...
                                     'if  any(period_iterator == [190:195]) && strcmp(mouse, "1100");'...
                                     'data_evaluated = [];'...
                                     'else;'...
                                     'data_evaluated = parameters.data;'...
                                     'end'}};
% Inputs
% each mouse
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\concatenated periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% concatenated data
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'data_all_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'data_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'period';
% average
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_save.average.filename = {'average_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.average.variable = {'average'}; 
parameters.loop_list.things_to_save.average.level = 'period';
% std_dev
parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'std_dev_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'std_dev'}; 
parameters.loop_list.things_to_save.std_dev.level = 'period';

parameters.loop_list.things_to_rename = {   {'data_evaluated', 'data'}
                                            {'concatenated_data', 'data'}};

RunAnalysis({@EvaluateOnData, @ConcatenateData, @AverageData}, parameters);

%% Plot average of each period across mice
% use standard error of the mean (SEM) as the errors
% use consitent axes limits
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'period', {'loop_variables.periods_withLongs'}, 'period_iterator';
               }; 

parameters.instancesDim = 1; % for calculating SEM
parameters.ylimits = [-4 4];

% Inputs
% average
parameters.loop_list.things_to_load.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_load.average.filename = {'average_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.average.variable = {'average'}; 
parameters.loop_list.things_to_load.average.level = 'period';
% std dev
parameters.loop_list.things_to_load.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_load.std_dev.filename = {'std_dev_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.std_dev.variable = {'std_dev'}; 
parameters.loop_list.things_to_load.std_dev.level = 'period';
% data_all (to get the number of mice used for SEM)
parameters.loop_list.things_to_load.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_load.concatenated_data.filename = {'data_all_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.concatenated_data.variable = {'data_all'}; 
parameters.loop_list.things_to_load.concatenated_data.level = 'period';

% Outputs
% figure
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\average figures\'],'paw', '\'};
parameters.loop_list.things_to_save.fig.filename = {'overlay_','period_iterator','_', 'period', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';
% SEM
parameters.loop_list.things_to_save.SEM.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\all mice\data\'],'paw', '\'};
parameters.loop_list.things_to_save.SEM.filename = {'SEM_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.SEM.variable = {'SEM'}; 
parameters.loop_list.things_to_save.SEM.level = 'period';

RunAnalysis({@PlotMiceStrideAverages}, parameters);
close all;

%% Segment FL, HL, and tail with FL x ranges -- Spontaneous long walk
% To find phase differences 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
                };

parameters.segmentDim = 1;
parameters.concatDim = 2;
parameters.instancesAsCells = true; 
parameters.uniformSegments = false;

% Inputs
% timeseries
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'velocity_direction', '\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_load.timeseries.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.timeseries.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.timeseries.level = 'mouse';
% time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\FL\'], 'mouse', '\'};
parameters.loop_list.things_to_load.time_ranges.filename = {'x_peaks_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_load.time_ranges.variable = {'x_peaks.depression_ranges{1}'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'mouse';

% Outputs
% segmented timseries
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename = {'stride_segmentations_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'mouse';

RunAnalysis({@StrideSegmentationLooper}, parameters);

%% Segment FL, HL, and tail with FL x ranges -- Motorized long walk
% To find phase differences 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator'
                };

parameters.segmentDim = 1;
parameters.concatDim = 2;
parameters.instancesAsCells = true;

% Inputs
% timeseries
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'velocity_direction', '\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_load.timeseries.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.timeseries.level = 'motorSpeed';
% time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\FL\'], 'mouse', '\'};
parameters.loop_list.things_to_load.time_ranges.filename = {'x_peaks_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable = {'x_peaks.depression_ranges{1}'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'motorSpeed';

% Outputs
% segmented timseries
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename = {'stride_segmentations_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'motorSpeed';

RunAnalysis({@StrideSegmentationLooper}, parameters);

%% Body parts segmented with FL x: Concatenate 

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator'
                };

parameters.concatDim = 1;
parameters.concatenation_level = 'type_tag';
parameters.concatenate_across_cells = true;

% Inputs
% data
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_load.data.level = 'type_tag';

% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'stride_segmentations'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Other paws with FL x depressions: resample and plot

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

% close each figure after saving it
parameters.closeFigures = true;
% the number of timepoints to resample each stride velocity segment to.
parameters.resampleLength = 10; % to 0.5 s = 10 time points

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% stride segmentations reformatted so strides are all on same cell level
parameters.loop_list.things_to_save.segmentations_together.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_together.filename = {'stride_segmentations_together', '.mat'};
parameters.loop_list.things_to_save.segmentations_together.variable = {'stride_segmentations_together{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmentations_together.level = 'mouse';
% resampled segmentations
parameters.loop_list.things_to_save.resampled.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.resampled.filename = {'stride_segmentations_resampled', '.mat'};
parameters.loop_list.things_to_save.resampled.variable = {'stride_segmentations_resampled{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.resampled.level = 'mouse';
% mean 
parameters.loop_list.things_to_save.average.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_save.average.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';
% std
parameters.loop_list.things_to_save.std_dev.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'stride_segmentations_std_dev', '.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'stride_segmentations_std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';
% figure: not-resampled segmentations 
parameters.loop_list.things_to_save.fig_segmentations_together.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_segmentations_together.filename = {'stride_segmentations_together_','period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_segmentations_together.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_segmentations_together.level = 'period';
% figure: resampled segmentations
parameters.loop_list.things_to_save.fig_resampled.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_resampled.filename = {'stride_segmentations_resampled_','period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_resampled.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_resampled.level = 'period';
% figure: mean and std
parameters.loop_list.things_to_save.fig_average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_average.filename = {'stride_segmentations_average_', 'period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_average.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_average.level = 'period';

RunAnalysis({@GaitResampling}, parameters);

%% segmented with FL x: Plot all mices' averages of each period together

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 


parameters.instancesDim = 1;
parameters.ylimits = [-6 6];
parameters.mymap = flipud(hsv(7));

% Inputs
% resampled segmentations
parameters.loop_list.things_to_load.resampled.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.resampled.filename = {'stride_segmentations_resampled', '.mat'};
parameters.loop_list.things_to_load.resampled.variable = {'stride_segmentations_resampled{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.resampled.level = 'mouse';
% mean 
parameters.loop_list.things_to_load.average.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.average.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_load.average.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.average.level = 'mouse';
% std
parameters.loop_list.things_to_load.std_dev.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.std_dev.filename = {'stride_segmentations_std_dev', '.mat'};
parameters.loop_list.things_to_load.std_dev.variable = {'stride_segmentations_std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.std_dev.level = 'mouse';

% Outputs
% figure
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\overlays\'], 'paw', '\' 'velocity_direction', '\'};
parameters.loop_list.things_to_save.fig.filename = {'overlay_','period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';

RunAnalysis({@PlotMiceStrideOverlays}, parameters);

close all;

%% segmented with FL x: Average each period across mice
% include m1107, aren't comparing across spon and motorized yet
% concatenate & average

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 

parameters.concatDim = 1;
parameters.concatenation_level = 'mouse';
parameters.averageDim = 1;

% Don't include mouse 1100 in spontaneous averages
parameters.evaluation_instructions = {{'period_iterator = parameters.values{strcmp(parameters.keywords, "period_iterator")};'...;
                                     'mouse = parameters.values{strcmp(parameters.keywords, "mouse")};' ...
                                     'if  period_iterator == 1 && strcmp(mouse, "1100");'...
                                     'data_evaluated = [];'...
                                     'else;'...
                                     'data_evaluated = parameters.data;'...
                                     'end'}};
% Inputs
% each mouse
parameters.loop_list.things_to_load.data.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% concatenated data
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'data_all_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'data_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'period';
% average
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.average.filename = {'average_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.average.variable = {'average'}; 
parameters.loop_list.things_to_save.average.level = 'period';
% std_dev
parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'std_dev_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'std_dev'}; 
parameters.loop_list.things_to_save.std_dev.level = 'period';

parameters.loop_list.things_to_rename = {   {'data_evaluated', 'data'}
                                            {'concatenated_data', 'data'}};

RunAnalysis({@EvaluateOnData, @ConcatenateData, @AverageData}, parameters);

%% segmented with FL x: Plot average of each period across mice
% use standard error of the mean (SEM) as the errors
% use consitent axes limits
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

parameters.instancesDim = 1; % for calculating SEM
parameters.ylimits = [-4 4];

% Inputs
% average
parameters.loop_list.things_to_load.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_load.average.filename = {'average_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.average.variable = {'average'}; 
parameters.loop_list.things_to_load.average.level = 'period';
% std dev
parameters.loop_list.things_to_load.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_load.std_dev.filename = {'std_dev_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.std_dev.variable = {'std_dev'}; 
parameters.loop_list.things_to_load.std_dev.level = 'period';
% data_all (to get the number of mice used for SEM)
parameters.loop_list.things_to_load.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_load.concatenated_data.filename = {'data_all_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.concatenated_data.variable = {'data_all'}; 
parameters.loop_list.things_to_load.concatenated_data.level = 'period';

% Outputs
% figure
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\average figures\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.fig.filename = {'overlay_','period_iterator','_', 'period', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';
% SEM
parameters.loop_list.things_to_save.SEM.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from FL x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.SEM.filename = {'SEM_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.SEM.variable = {'SEM'}; 
parameters.loop_list.things_to_save.SEM.level = 'period';

RunAnalysis({@PlotMiceStrideAverages}, parameters);
close all;

%% segment other velocity directions based on that body part's x-direction: spontaneous

% To find phase differences 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
                };

parameters.segmentDim = 1;
parameters.concatDim = 2;
parameters.instancesAsCells = true; 
parameters.uniformSegments = false;

% Inputs
% timeseries
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'velocity_direction', '\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_load.timeseries.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.timeseries.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.timeseries.level = 'mouse';
% time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.time_ranges.filename = {'x_peaks_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_load.time_ranges.variable = {'x_peaks.depression_ranges{1}'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'mouse';

% Outputs
% segmented timseries
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename = {'stride_segmentations_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'mouse';

RunAnalysis({@StrideSegmentationLooper}, parameters);

%% segment other velocity directions based on that body part's x-direction: Motorized long walk
% To find phase differences 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator'
                };

parameters.segmentDim = 1;
parameters.concatDim = 2;
parameters.instancesAsCells = true;

% Inputs
% timeseries
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\', 'velocity_direction', '\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_load.timeseries.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.timeseries.level = 'motorSpeed';
% time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.time_ranges.filename = {'x_peaks_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable = {'x_peaks.depression_ranges{1}'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'motorSpeed';

% Outputs
% segmented timseries
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename = {'stride_segmentations_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'motorSpeed';

RunAnalysis({@StrideSegmentationLooper}, parameters);

%% other velocity directions based on that body part's x-direction: Concatenate
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator'
                };

parameters.concatDim = 1;
parameters.concatenation_level = 'type_tag';
parameters.concatenate_across_cells = true;

% Inputs
% data
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_depression'}; 
parameters.loop_list.things_to_load.data.level = 'type_tag';

% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'stride_segmentations'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% other velocity directions based on that body part's x-direction: Gait Resampling
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

% close each figure after saving it
parameters.closeFigures = true;
% the number of timepoints to resample each stride velocity segment to.
parameters.resampleLength = 10; % to 0.5 s = 10 time points

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% stride segmentations reformatted so strides are all on same cell level
parameters.loop_list.things_to_save.segmentations_together.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.segmentations_together.filename = {'stride_segmentations_together', '.mat'};
parameters.loop_list.things_to_save.segmentations_together.variable = {'stride_segmentations_together{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmentations_together.level = 'mouse';
% resampled segmentations
parameters.loop_list.things_to_save.resampled.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.resampled.filename = {'stride_segmentations_resampled', '.mat'};
parameters.loop_list.things_to_save.resampled.variable = {'stride_segmentations_resampled{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.resampled.level = 'mouse';
% mean 
parameters.loop_list.things_to_save.average.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_save.average.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';
% std
parameters.loop_list.things_to_save.std_dev.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'stride_segmentations_std_dev', '.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'stride_segmentations_std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';
% figure: not-resampled segmentations 
parameters.loop_list.things_to_save.fig_segmentations_together.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_segmentations_together.filename = {'stride_segmentations_together_','period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_segmentations_together.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_segmentations_together.level = 'period';
% figure: resampled segmentations
parameters.loop_list.things_to_save.fig_resampled.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_resampled.filename = {'stride_segmentations_resampled_','period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_resampled.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_resampled.level = 'period';
% figure: mean and std
parameters.loop_list.things_to_save.fig_average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig_average.filename = {'stride_segmentations_average_', 'period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig_average.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig_average.level = 'period';

RunAnalysis({@GaitResampling}, parameters);

parameters.closeFigures = false;

%% Own x segmentations: Plot all mices' averages of each period together

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 


parameters.instancesDim = 1;
parameters.ylimits = [-6 6];
parameters.mymap = flipud(hsv(7));

% Inputs
% resampled segmentations
parameters.loop_list.things_to_load.resampled.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.resampled.filename = {'stride_segmentations_resampled', '.mat'};
parameters.loop_list.things_to_load.resampled.variable = {'stride_segmentations_resampled{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.resampled.level = 'mouse';
% mean 
parameters.loop_list.things_to_load.average.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.average.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_load.average.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.average.level = 'mouse';
% std
parameters.loop_list.things_to_load.std_dev.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.std_dev.filename = {'stride_segmentations_std_dev', '.mat'};
parameters.loop_list.things_to_load.std_dev.variable = {'stride_segmentations_std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.std_dev.level = 'mouse';

% Outputs
% figure
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\overlays\'], 'paw', '\' 'velocity_direction', '\'};
parameters.loop_list.things_to_save.fig.filename = {'overlay_','period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';

RunAnalysis({@PlotMiceStrideOverlays}, parameters);

close all;

%% Own x: Average each period across mice
% include m1107, aren't comparing across spon and motorized yet
% concatenate & average

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 

parameters.concatDim = 1;
parameters.concatenation_level = 'mouse';
parameters.averageDim = 1;

% Don't include mouse 1100 in spontaneous averages
parameters.evaluation_instructions = {{'period_iterator = parameters.values{strcmp(parameters.keywords, "period_iterator")};'...;
                                     'mouse = parameters.values{strcmp(parameters.keywords, "mouse")};' ...
                                     'if  period_iterator == 1 && strcmp(mouse, "1100");'...
                                     'data_evaluated = [];'...
                                     'else;'...
                                     'data_evaluated = parameters.data;'...
                                     'end'}};
% Inputs
% each mouse
parameters.loop_list.things_to_load.data.dir =  {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\concatenated periods\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_average', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
% concatenated data
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'data_all_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'data_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'period';
% average
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.average.filename = {'average_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.average.variable = {'average'}; 
parameters.loop_list.things_to_save.average.level = 'period';
% std_dev
parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'std_dev_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'std_dev'}; 
parameters.loop_list.things_to_save.std_dev.level = 'period';

parameters.loop_list.things_to_rename = {   {'data_evaluated', 'data'}
                                            {'concatenated_data', 'data'}};

RunAnalysis({@EvaluateOnData, @ConcatenateData, @AverageData}, parameters);

%% Own x: Plot average of each period across mice
% use standard error of the mean (SEM) as the errors
% use consitent axes limits
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions_sublist'}, 'velocity_direction_iterator'
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

parameters.instancesDim = 1; % for calculating SEM
parameters.ylimits = [-4 4];

% Inputs
% average
parameters.loop_list.things_to_load.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_load.average.filename = {'average_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.average.variable = {'average'}; 
parameters.loop_list.things_to_load.average.level = 'period';
% std dev
parameters.loop_list.things_to_load.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_load.std_dev.filename = {'std_dev_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.std_dev.variable = {'std_dev'}; 
parameters.loop_list.things_to_load.std_dev.level = 'period';
% data_all (to get the number of mice used for SEM)
parameters.loop_list.things_to_load.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_load.concatenated_data.filename = {'data_all_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_load.concatenated_data.variable = {'data_all'}; 
parameters.loop_list.things_to_load.concatenated_data.level = 'period';

% Outputs
% figure
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\average figures\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.fig.filename = {'overlay_','period_iterator','_', 'period', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';
% SEM
parameters.loop_list.things_to_save.SEM.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations from own x depressions\all mice\data\'],'paw', '\', 'velocity_direction', '\'};
parameters.loop_list.things_to_save.SEM.filename = {'SEM_','period_iterator','_', 'period', '.mat'};
parameters.loop_list.things_to_save.SEM.variable = {'SEM'}; 
parameters.loop_list.things_to_save.SEM.level = 'period';

RunAnalysis({@PlotMiceStrideAverages}, parameters);
close all;

%% run phase difference detections with phdiffmeasure -- spontaneous
% use fillmissing Matlab build-in function first ('movmean', 10)

% Compare HL and tail x to FL x. (tail x is larger on average than tail y... or at least I didn't segment based on y depressions) 

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator'; % iterate through HL and tail only
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 

parameters.isLongWalk = true;
parameters.fillMissing_window = 10; % The width of the window to run 'movmean' over in the 'fillmissing' step
parameters.minimumLength = 60; % The minimum length of the timeseries to try to calculate phase on (3 seconds)

% Inputs 
% reference (FL x)
parameters.loop_list.things_to_load.reference.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\FL\x\spontaneous\'], 'mouse', '\'};
parameters.loop_list.things_to_load.reference.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.reference.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.reference.level = 'mouse';
% compare to (other paw x)
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\x\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.phase_differences.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.phase_differences.filename = {'phaseDifference_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.phase_differences.variable = {'phase_difference'}; 
parameters.loop_list.things_to_save.phase_differences.level = 'mouse';

RunAnalysis({@FindPhaseDifference}, parameters);


%% run phase difference detections with phdiffmeasure -- motorized
% use fillmissing Matlab build-in function first ('movmean', 10)

% Compare HL and tail x to FL x. (tail x is larger on average than tail y... or at least I didn't segment based on y depressions) 

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator'; % iterate through HL and tail only
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator'
               }; 

parameters.isLongWalk = true;
parameters.fillMissing_window = 10; % The width of the window to run 'movmean' over in the 'fillmissing' step
parameters.minimumLength = 60; % The minimum length of the timeseries to try to calculate phase on (3 seconds)

% Inputs 
% reference (FL x)
parameters.loop_list.things_to_load.reference.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\FL\x\motorized\'], 'mouse', '\'};
parameters.loop_list.things_to_load.reference.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.reference.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.reference.level = 'motorSpeed';
% compare to (other paw x)
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\x\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'motorSpeed';

% Outputs
parameters.loop_list.things_to_save.phase_differences.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.phase_differences.filename = {'phaseDifference_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.phase_differences.variable = {'phase_difference'}; 
parameters.loop_list.things_to_save.phase_differences.level = 'motorSpeed';

RunAnalysis({@FindPhaseDifference}, parameters);


%% Phases: Concatenate
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator'
                };

parameters.concatDim = 1;
parameters.concatenation_level = 'type_tag';
parameters.concatenate_across_cells = true;

% Inputs
% data
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'phaseDifference_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'phase_difference'}; 
parameters.loop_list.things_to_load.data.level = 'type_tag';

% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'phaseDifference_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'phase_difference'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Get lengths of the long velocity segments: Spontaneous
% so when you average the phase differences, you can weight by the length
% of the walking segment

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator'; % iterate through HL and tail only
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               }; 

parameters.evaluation_instructions = {{'data_evaluated  = {cellfun("size", parameters.data, 1)};'}};
% Inputs 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\x\spontaneous\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_longPeriods_walk.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.data_evaluated.filename = {'istanceLengths_longWalk_spontaneous.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable = {'lengths'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';

RunAnalysis({@EvaluateOnData}, parameters);

%% Get lengths of the long velocity segments: Motorized
% so when you average the phase differences, you can weight by the length
% of the walking segment

if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator'; % iterate through HL and tail only
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator'
               }; 

parameters.evaluation_instructions = {{'data_evaluated  = {cellfun("size", parameters.data, 1)};'}};
% Inputs 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated velocity\'], 'paw', '\x\motorized\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'concatenated_velocity_longPeriods_walk_', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'velocity_all'}; 
parameters.loop_list.things_to_load.data.level = 'motorSpeed';

% Outputs
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.data_evaluated.filename = {'istanceLengths_longWalk_motorized', 'motorSpeed', '.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable = {'lengths'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'motorSpeed';

RunAnalysis({@EvaluateOnData}, parameters);

%% Lengths: Concatenate
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator'
                };

parameters.concatDim = 1;
parameters.concatenation_level = 'type_tag';
parameters.concatenate_across_cells = true;

% Inputs
% data
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'istanceLengths_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'lengths'}; 
parameters.loop_list.things_to_load.data.level = 'type_tag';

% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'instanceLengths_concatenated.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'lengths_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);


%% Phases: Average within mouse using circular statistics
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws_sublist'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

parameters.averageDim = 1;
parameters.useWeights = true;

% Inputs
% data
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'phaseDifference_concatenated.mat'};
parameters.loop_list.things_to_load.data.variable = {'phase_difference{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';
% weights
parameters.loop_list.things_to_load.weights.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.weights.filename = {'instanceLengths_concatenated.mat'};
parameters.loop_list.things_to_load.weights.variable = {'lengths_all{', 'period_iterator', '}'}; 
parameters.loop_list.things_to_load.weights.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename = {'within_mouse_average.mat'};
parameters.loop_list.things_to_save.average.variable = {'average{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\phase difference\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'within_mouse_std_dev.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'std_dev{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';

RunAnalysis({@AverageCircularData}, parameters);

parameters.useWeights = false;

%% Find stride durations (from stride velocity segmentations)
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Don't need to do different segmentation methods or velocity directions (just do x of each paw)
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

parameters.evaluation_instructions = {{'data_evaluated = cellfun(@numel, parameters.data);'}};

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride segmentations\from depressions\concatenated periods\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_together', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_together{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride durations\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.data_evaluated.filename = {'stride_durations', '.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable = {'stride_durations{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';

RunAnalysis({@EvaluateOnData}, parameters);

%% Stride durations: plot histograms
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

parameters.bin_edges = 0:1:60;

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride durations\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_durations', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_durations{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride durations\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig.filename = {'stride_durations_', 'period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';

RunAnalysis({@StrideDurationHistograms}, parameters);

close all;

%% *** Stride durations: fancy plots might do the mean within and across mice in Prism Graphpad ***


%% Segment positiosn by behavior period (long walk periods)-- Spontaneous

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
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\paw position\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'position', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'position.', 'body_part', '.', 'velocity_direction'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';
% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\spontaneous\segmented behavior periods\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'long_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'long_periods.walk'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented positions\'], 'body_part', '\', 'velocity_direction', '\', 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_longWalk_spontaneous', '_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'velocity_direction';

RunAnalysis({@SegmentTimeseriesData}, parameters);

%% Segment positiosn by behavior period (long walk periods)-- Motorized

% (similar to paw_velocity_pipeline_code.m)
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
               'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'loop_variables.mice_all(',  'mouse_iterator', ').days(', 'day_iterator', ').stacks'}, 'stack_iterator';
                   'body_part', {'loop_variables.body_parts'}, 'body_part_iterator';
                   'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator' ;
                   'motorSpeed', {'loop_variables.motorSpeeds'}, 'motorSpeed_iterator';
                   };

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
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\paw position\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.timeseries.filename= {'position', 'stack', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable= {'position.', 'body_part', '.', 'velocity_direction'}; 
parameters.loop_list.things_to_load.timeseries.level = 'stack';
% Time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\motorized\period instances\'], 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.time_ranges.filename= {'long_periods_', 'stack', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable= {'long_periods.walk_', 'motorSpeed'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'stack';

% Output Values
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented positions\'], 'body_part', '\', 'velocity_direction', '\', 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename= {'segmented_timeseries_longWalk_motorized', 'motorSpeed', '_', 'stack', '.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'motorSpeed';

RunAnalysis({@SegmentTimeseriesData}, parameters);

%% Concatenate positions (long walk periods)
% use type_tag to avoid separating spon & motorized
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Iterators
parameters.loop_list.iterators = {
                   'body_part', {'loop_variables.body_parts'}, 'body_part_iterator';
                   'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator';
                   'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator';
                   'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator'; 
                   'day', {'loop_variables.mice_all(', 'mouse_iterator', ').days(:).name'}, 'day_iterator';
                   'stack', {'getfield(loop_variables, {1}, "mice_all", {',  'mouse_iterator', '}, "days", {', 'day_iterator', '}, ', 'loop_variables.conditions_stack_locations_long{', 'type_tag_iterator', '})'}, 'stack_iterator'; 
                   };

parameters.concatDim = 1;
parameters.concatenate_across_cells = true;

% Inputs 
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\body\normalized\segmented positions\'], 'body_part', '\', 'velocity_direction', '\', 'mouse', '\', 'day', '\'};
parameters.loop_list.things_to_load.data.filename= {'segmented_timeseries_', 'type_tag', '_', 'stack', '.mat'};
parameters.loop_list.things_to_load.data.variable= {'segmented_timeseries'}; 
parameters.loop_list.things_to_load.data.level = 'stack';

% Outputs
parameters.loop_list.things_to_save.concatenated_data.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated positions\'], 'body_part', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.concatenated_data.filename = {'concatenated_positions_', 'type_tag', '.mat'};
parameters.loop_list.things_to_save.concatenated_data.variable = {'position_all'}; 
parameters.loop_list.things_to_save.concatenated_data.level = 'mouse';

RunAnalysis({@ConcatenateData}, parameters);

%% Segment positions by stride -- own x-direction 
% To find stride lengths in space/distance 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'velocity_direction', {'loop_variables.velocity_directions'}, 'velocity_direction_iterator'
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator';
                };

parameters.segmentDim = 1;
parameters.concatDim = 2;
parameters.instancesAsCells = true; 
parameters.uniformSegments = false;
parameters.add_extra_cell_layer = false;

% Inputs
% timeseries
parameters.loop_list.things_to_load.timeseries.dir = {[parameters.dir_exper 'behavior\body\normalized\concatenated positions\'], 'paw', '\', 'velocity_direction', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.timeseries.filename = {'concatenated_positions_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.timeseries.variable = {'position_all'}; 
parameters.loop_list.things_to_load.timeseries.level = 'type_tag';
%time ranges
parameters.loop_list.things_to_load.time_ranges.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\x peaks\all periods\'], 'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_load.time_ranges.filename = {'x_peaks_', 'type_tag', '.mat'};
parameters.loop_list.things_to_load.time_ranges.variable = {'x_peaks.depression_ranges{1}'}; 
parameters.loop_list.things_to_load.time_ranges.level = 'type_tag';

% Outputs
% segmented timseries
parameters.loop_list.things_to_save.segmented_timeseries.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\all periods\'],'paw', '\', 'velocity_direction', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.segmented_timeseries.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_save.segmented_timeseries.variable = {'stride_segmentations_depression{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.segmented_timeseries.level = 'mouse';

RunAnalysis({@StrideSegmentationLooper}, parameters);

%% Segment positions by stride -- FL x (might not do?)

%% plot position strides
% plot x vs y 
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator';
                };
parameters.resampleLength = 10;
parameters.closeFigures = true;
% Inputs
% x data
parameters.loop_list.things_to_load.x.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\all periods\'],'paw', '\x\' 'mouse', '\'};
parameters.loop_list.things_to_load.x.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_load.x.variable = {'stride_segmentations_depression{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.x.level = 'mouse';
% y data
parameters.loop_list.things_to_load.y.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\all periods\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_load.y.filename = {'stride_segmentations.mat'};
parameters.loop_list.things_to_load.y.variable = {'stride_segmentations_depression{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.y.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.x_together.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.x_together.filename = {'stride_segmentations_x_together.mat'};
parameters.loop_list.things_to_save.x_together.variable = {'stride_segmentations_x_together{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.x_together.level = 'mouse';

parameters.loop_list.things_to_save.y_together.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.y_together.filename = {'stride_segmentations_y_together.mat'};
parameters.loop_list.things_to_save.y_together.variable = {'stride_segmentations_y_together{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.y_together.level = 'mouse';

parameters.loop_list.things_to_save.x_resampled.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.x_resampled.filename = {'stride_segmentations_x_resampled.mat'};
parameters.loop_list.things_to_save.x_resampled.variable = {'stride_segmentations_x_resampled{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.x_resampled.level = 'mouse';

parameters.loop_list.things_to_save.y_resampled.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.y_resampled.filename = {'stride_segmentations_y_resampled.mat'};
parameters.loop_list.things_to_save.y_resampled.variable = {'stride_segmentations_y_resampled{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.y_resampled.level = 'mouse';

parameters.loop_list.things_to_save.average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.average.filename = {'stride_segmentations_average.mat'};
parameters.loop_list.things_to_save.average.variable = {'stride_segmentations_average{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.average.level = 'mouse';

parameters.loop_list.things_to_save.std_dev.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.std_dev.filename = {'stride_segmentations_std_dev.mat'};
parameters.loop_list.things_to_save.std_dev.variable = {'stride_segmentations_std_dev{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.std_dev.level = 'mouse';

parameters.loop_list.things_to_save.fig_positions_together.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.fig_positions_together.filename = {'stride_segmentations_together.fig'};
parameters.loop_list.things_to_save.fig_positions_together.variable = {'fig_positions_together'}; 
parameters.loop_list.things_to_save.fig_positions_together.level = 'type_tag';

parameters.loop_list.things_to_save.fig_resampled.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.fig_resampled.filename = {'stride_segmentations_resampled.fig'};
parameters.loop_list.things_to_save.fig_resampled.variable = {'fig_resampled'}; 
parameters.loop_list.things_to_save.fig_resampled.level = 'type_tag';

parameters.loop_list.things_to_save.fig_average.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_save.fig_average.filename = {'stride_segmentations_average.fig'};
parameters.loop_list.things_to_save.fig_average.variable = {'fig_average'}; 
parameters.loop_list.things_to_save.fig_average.level = 'type_tag';

RunAnalysis({@PlotStridePosition}, parameters);

parameters.closeFigures = false;

%% Get stride lengths (from stride position segmentations)
% load stride_positions_together
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

% Is so you can use a single loop for calculations. 
parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'type_tag', {'loop_variables.type_tags'}, 'type_tag_iterator';
                };

parameters.evaluation_instructions = {{'data_evaluated = cellfun( @range, parameters.data);'}};
% Input
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\y\' 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_segmentations_x_together.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_segmentations_x_together{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.data_evaluated.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\' 'mouse', '\'};
parameters.loop_list.things_to_save.data_evaluated.filename = {'stride_lengths.mat'};
parameters.loop_list.things_to_save.data_evaluated.variable = {'stride_lengths{', 'type_tag_iterator', ', 1}'}; 
parameters.loop_list.things_to_save.data_evaluated.level = 'mouse';

RunAnalysis({@EvaluateOnData}, parameters);

%% Stride lengths: plot histograms
if isfield(parameters, 'loop_list')
parameters = rmfield(parameters,'loop_list');
end

parameters.loop_list.iterators = {
               'paw', {'loop_variables.paws'}, 'paw_iterator';
               'mouse', {'loop_variables.mice_all(:).name'}, 'mouse_iterator';
               'period', {'loop_variables.periods_longsOnly'}, 'period_iterator';
               }; 

parameters.bin_edges = 0:2:200;
parameters.title_string = 'lengths';

% Inputs
parameters.loop_list.things_to_load.data.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\position strides from own x depressions\figures\'],'paw', '\' 'mouse', '\'};
parameters.loop_list.things_to_load.data.filename = {'stride_lengths', '.mat'};
parameters.loop_list.things_to_load.data.variable = {'stride_lengths{', 'period_iterator', ', 1}'}; 
parameters.loop_list.things_to_load.data.level = 'mouse';

% Outputs
parameters.loop_list.things_to_save.fig.dir = {[parameters.dir_exper 'behavior\gait analysis\normalized\stride lengths\'],'paw', '\', 'mouse', '\'};
parameters.loop_list.things_to_save.fig.filename = {'stride_lengths_', 'period', '_', 'period_iterator', '.fig'};
parameters.loop_list.things_to_save.fig.variable = {'fig'}; 
parameters.loop_list.things_to_save.fig.level = 'period';

RunAnalysis({@StrideDurationHistograms}, parameters);

close all;