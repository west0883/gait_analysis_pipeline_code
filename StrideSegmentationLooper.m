% StrideSegmentationLooper.m
% Sarah West
% 7/19/23

function [parameters] = StrideSegmentationLooper(parameters)

    % Inputs 
    % parameters.timeseries -- 
    % parameters.time_ranges -- 

    MessageToUser('Segmenting ', parameters);

    timeseries = parameters.timeseries;
    time_ranges = parameters.time_ranges;

    subParameters.segmentDim = parameters.segmentDim;
    subParameters.concatDim = parameters.concatDim;
    subParameters.uniformSegments = parameters.uniformSegments;

    % If true, is continued walk long periods
    if parameters.instancesAsCells

        segmentations_all = cell(size(timeseries));

        for datai = 1:numel(timeseries)
            
            timeseries_holder = timeseries{datai}; 
            time_ranges_holder = vertcat(time_ranges{datai}{:});

            subParameters.timeseries = timeseries_holder;
            subParameters.time_ranges = time_ranges_holder;

            subParameters = SegmentTimeseriesData(subParameters);

            segmentations_all{datai} = subParameters.segmented_timeseries;

        end
        
        % add another layer of cells to match other periods formatting
        if ~isfield(parameters, 'add_extra_cell_layer') ||  (isfield(parameters, 'add_extra_cell_layer') && parameters.add_extra_cell_layer)
            segmentations_all = {segmentations_all};
        end
  
    % Otherwise, is all other periods
    else
        timeseries_holder = timeseries;
        time_ranges_holder = time_ranges; 

        subParameters.timeseries = timeseries_holder;
        subParameters.time_ranges = time_ranges_holder;
        
        subParameters = SegmentTimeseriesData(subParameters);

        segmentations_all = subParameters.segmented_timeseries;
    end 
    
    % Put into output structure
    parameters.segmented_timeseries = segmentations_all;
    
end 