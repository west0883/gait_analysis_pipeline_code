% FindPhaseDifference.m
% Sarah West
% 7/20/23

% Finds the phase difference between two body part velocity traces for
% pipeline_gait_analysis.m . Uses phdiffmeasure.m .  Called by RunAnalysis.

function [parameters] = FindPhaseDifference(parameters)

    % Inputs:
    reference = parameters.reference; % The cell array of reference timeseries you're comparing the phase against.
    data = parameters.data; % The cell array of timeseries you're comparing to the reference.
    fillMissing_window = parameters.fillMissing_window; % The width of the window to run 'movmean' over in the 'fillmissing' step. 
    isLongWalk = parameters.isLongWalk; % If this is a long walk period 

    % Outputs
    % parameters.phase_differences -- the cell array of phase differences
    % for each pair of timeseries

    % Tell user what iteration you're on.
    MessageToUser('Finding phase of ', parameters);

    % If data has multiple entries/instances
    if iscell(data)



    end 

    % If this is a long walk period, add another layer of cells for
    % concatenation with other periods later
    if isLongWalk
        
        phase_differences = {phase_differences};

    end

    % Put into output structure
    parameters.phase_differences = phase_differences;
end 