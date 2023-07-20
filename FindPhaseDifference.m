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
    minimumLength = parameters.minimumLength; % The minimum length of the timeseries to try to calculate phase on (3 seconds)
    
    % Outputs
    % parameters.phase_differences -- the cell array of phase differences
    % for each pair of timeseries. Each phase difference is on the ranges
    % [-pi pi] -- in radians

    % Tell user what iteration you're on.
    MessageToUser('Finding phase of ', parameters);

    % If data has multiple entries/instances
    if iscell(data)

        % Make a holder for all phase differences
        phase_differences = NaN(size(data));

        % For each entry in data
        for datai = 1:numel(data)
            
            % Pull out respective data and reference timeseries
            data_holder = data{datai};
            reference_holder = reference{datai};

            % Run through subfunction
            phase_difference = SubPhaseDifference(reference_holder, data_holder, fillMissing_window, minimumLength);

            % Put result into holder
            phase_differences(datai) = phase_difference;

        end 
    else 

        phase_differences = SubPhaseDifference(reference, data, fillMissing_window, minimumLength);

    end 

    % If this is a long walk period, add another layer of cells for
    % concatenation with other periods later
    if isLongWalk
        
        phase_differences = {phase_differences};

    end

    % Put into output structure
    parameters.phase_differences = phase_differences;
end 

function [phase_difference] = SubPhaseDifference(reference, data, fillMissing_window, minimumLength)

      % If the timeseries are shorter than 3 seconds, skip them
%     % If either timeseries has more than 10% of the data missing, skip it
%     if sum(isnan(data)) > numel(data) * 0.10
%         phase_difference = NaN;
%         return
%     end 
%     if sum(isnan(reference)) > numel(reference) * 0.10
%         phase_difference = NaN;
%         return
%     end 

    % Fill NaNs in reference or data 
    reference_filled = fillmissing(reference, 'movmean',fillMissing_window);
    data_filled = fillmissing(data, 'movmean',fillMissing_window);

    % If either reference or data still has NaNs (has a gap of greater than
    % fillMissing_window), segment the timeseries at each relevant point 
    if any(isnan(data_filled)) || any(isnan(reference_filled))
         
        all_nans = sort([find(isnan(data_filled));  find(isnan(reference_filled))]); 
        all_nans_space = diff(all_nans);

        % Segment
        segments = {};
        counter = 1;
        % deal with first segment 
        if all_nans(1) >= minimumLength
            segments{counter} = 1:all_nans(1) - 1;
            counter = counter + 1;
        end 

        % middle segments
        for i = 2:numel(all_nans)
            
            % If the next segments are greater than minimumLength and
            % further away from previous than minimumLenght
            if all_nans(i) >= minimumLength && all_nans_space(i - 1) >= minimumLength

                segments{counter} = all_nans(i - 1) + 1 : all_nans(i) - 1; 
                counter = counter + 1;

            end
        end 

        % deal with last segment
        % if it doesn't fall too close to the end
        if all_nans(end) <= (numel(reference_filled) - minimumLength)

            segments{counter} = all_nans(end) + 1 : numel(reference_filled);
        end 
  
        % If no good segments, make phase difference be NaN
        if isempty(segments)
            phase_difference = NaN;
        
        % If there are good segments
        else

            % Perform phdiffmeasure on each segment
            phase_diff_holder = NaN(numel(segments), 1);
            for i = 1:numel(segments)
                
                phase_diff_holder(i) = phdiffmeasure(reference_filled(segments{i}), data_filled(segments{i}));
            end 

            % Take average weighted by lengths of segments, using circular
            % statistics 
            weights = cellfun(@numel, segments) ./ sum(cellfun(@numel, segments));

            phase_difference = circ_mean(phase_diff_holder, weights');
            
        end 
    
    % If no NaNs left,
    else
        phase_difference = phdiffmeasure(reference_filled, data_filled);
    end 
end 