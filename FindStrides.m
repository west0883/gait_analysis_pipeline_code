% FindStrides.m
% Sarah West
% 7/7/2

% FindStrides.m finds mouse strides from smoothed velocity traces of the
% paws, taken from DeepLabCut. Velocity traces should be segmented by
% behavior of interest. Uses peakdet.m to find peaks and depressions in the
% trace around the mean velocity value. 
% 
% The mean velocity is NOT zero, because you're using an absolute magnitude
% of the paw trajectory-- because the mouse is stationary & because you
% don't have a perfect side view of the mouse. But, using the mean as
% "zero" makes it more likely the minimum peak heights are adjusted for the
% stride length. In our videos, the peaks likely reflect the middle of the 
% swing phase, which would be the fastest part of this stride 

function [parameters] = FindStrides(parameters)

% Inputs: 
% parameters.data -- matrix or cell array; the paw velocity trace in X
%                   direction. Is only a cell array in cases of not-brokendown 
%                   continued periods, when different instances are of different 
%                   lengths.
% parameters.timeDim -- the dimension of .data that corresponsds to time;
%                   other dimensions are different instances of paw movement.
% parameters.instanceDim -- the dimension of multiple instances/velocity
%                   traces in this matrix (if only 1 instance, put in as the 
%                   first dimension with size 1).
% parameters.peakMinHeight-- positive scalar; the "th" value for peakdet
% parameters.peakMinSeparation -- positive integer; the minimum distance between
%                   peaks/strides. 4 = max 5 Hz stride 
% parameters.instancesAsCells -- true/false; if each instance is given as a
% different space in 
        
    % b = a - mean(a);
    % [pks,dep,pid,did] = peakdet(b, 0.05 , 'zero', 4);

    MessageToUser('Peaks for ', parameters);

    % Pull out input parameters
    data = parameters.data;
    timeDim = parameters.timeDim;
    instanceDim = parameters.instanceDim;
    peakMinHeight= parameters.peakMinHeight;
    peakMinSeparation = parameters.peakMinSeparation;

    %
    if parameters.instancesAsCells
        % If true, for continued walk long periods
        peak_heights= cell(numel(data), 1); 
        peak_indices = cell(numel(data), 1); 
        depression_heights= cell(numel(data), 1); 
        depression_indices = cell(numel(data), 1);
        segments_peak_all = cell(numel(data), 1); 
        segments_depression_all = cell(numel(data), 1); 
        peak_ranges= cell(numel(data), 1);
        depression_ranges= cell(numel(data), 1);

        for datai = 1:numel(data)
            
            data_holder = data{datai}; 

            [peak_heights_intermediate, peak_indices_intermediate, depression_heights_intermediate, ...
                depression_indices_intermediate, segments_peak_intermediate,...
                segments_depression_intermediate, peak_ranges_intermediate, depression_ranges_intermediate ] ...
                = SubStrider(data_holder, timeDim, instanceDim, peakMinHeight, peakMinSeparation);    
            
            peak_heights(datai) = peak_heights_intermediate;
            peak_indices(datai) = peak_indices_intermediate;
            depression_heights(datai) = depression_heights_intermediate;
            depression_indices(datai) = depression_indices_intermediate;
            segments_peak_all(datai) = segments_peak_intermediate; 
            segments_depression_all(datai) = segments_depression_intermediate; 
            peak_ranges(datai) = peak_ranges_intermediate;
            depression_ranges(datai) = depression_ranges_intermediate;

        end 

        % add another layer of cells to match other periods formatting
        peak_heights = {peak_heights};
        peak_indices = {peak_indices};
        depression_heights = {depression_heights};
        depression_indices = {depression_indices};
        segments_peak_all = {segments_peak_all};
        segments_depression_all = {segments_depression_all};
        peak_ranges = {peak_ranges};
        depression_ranges = {depression_ranges};

    else 
        % Otherwise, is all other periods
        data_holder = data;
        [peak_heights, peak_indices, depression_heights, depression_indices, ...
            segments_peak_all, segments_depression_all, peak_ranges, depression_ranges ] ...
            = SubStrider(data_holder, timeDim, instanceDim, peakMinHeight, peakMinSeparation);
        
    end 

    % Put all results into output structure
    parameters.peaks.peak_heights = peak_heights;
    parameters.peaks.peak_indices = peak_indices;
    parameters.peaks.depression_heights = depression_heights;
    parameters.peaks.depression_indices = depression_indices;
    parameters.peaks.peak_ranges = peak_ranges;
    parameters.peaks.depression_ranges = depression_ranges;

    % Put segmentations into output structure
    parameters.segmentations_peak = segments_peak_all; 
    parameters.segmentations_depression = segments_depression_all; 

end 

function [peak_heights, peak_indices, depression_heights, depression_indices, ...
    segments_peak_all, segments_depression_all, peak_ranges, depression_ranges ] ...
    = SubStrider(data_holder, timeDim, instanceDim, peakMinHeight, peakMinSeparation)

    % ***Remove mean from data trace***

    % Go across time dimension
    data_meanRemoved = data_holder - mean(data_holder, timeDim, 'omitnan');

    % *** Run through peakdet.m ***

    % peakdet.m requires data to be inputted as individual vectors.
    % Find if there's more than one instance/velocity trace in this matrix,
        
    % set up dimensions holder
    C = repmat({':'}, 1, ndims(data_holder));

    % Set up output holders
    peak_heights = cell(size(data_holder, instanceDim), 1);
    depression_heights = cell(size(data_holder, instanceDim), 1);
    peak_indices = cell(size(data_holder, instanceDim), 1);
    depression_indices = cell(size(data_holder, instanceDim), 1);
    

    for instancei = 1:size(data_holder, instanceDim)
        
        % Pull out this instance's data
        C{instanceDim} = instancei;
        this_data = data_holder(C{:});

        % Run this instance through peakdet
        [peak_height, depression_height, pid1, did1] = peakdet(this_data, peakMinHeight, 'zero', peakMinSeparation);
        
        % put into holding variable
        peak_heights{instancei} = peak_height;
        depression_heights{instancei} = depression_height;
        peak_indices{instancei} = pid1;
        depression_indices{instancei} = did1;

       
    end 
  

    % *** Segment velocity traces by stride ***
    % Do NOT used mean data-- use original

    % set up dimensions holder
    C = repmat({':'}, 1, ndims(data_holder));

    % Set up segments holder
    segments_peak_all = cell(size(data_holder, instanceDim), 1);
    segments_depression_all = cell(size(data_holder, instanceDim), 1);
    peak_ranges = cell(size(data_holder, instanceDim), 1);
    depression_ranges = cell(size(data_holder, instanceDim), 1);
   
    for instancei = 1:size(data_holder, instanceDim)
        
        % Pull out this instance's data
        C{instanceDim} = instancei;
        this_data = data_holder(C{:});

        % Pull out this instance's peak indices
        this_peaks = peak_indices{instancei};

        % Segment by peaks
        [segments, ranges] = SubStrideSegmenter(this_data, this_peaks);

        segments_peak_all{instancei} = segments;
        peak_ranges{instancei} = ranges;

        % Segment by depressions
        this_depressions = depression_indices{instancei};

        [segments, ranges] = SubStrideSegmenter(this_data, this_depressions);
        segments_depression_all{instancei} = segments;
        depression_ranges{instancei} = ranges;

    end 
end

function [segments, peak_ranges] = SubStrideSegmenter(this_data, this_peaks)

    segments = cell(numel(this_peaks) - 1, 1);
    peak_ranges = cell(numel(this_peaks) - 1, 1);

    % Only do full strides (don't use time before first peak, or
    % last peak + time to end)
    for peaki = 1:numel(this_peaks) - 1
        
        % pull out segment; 
        holder =  this_data(this_peaks(peaki):this_peaks(peaki + 1) - 1);
        
        % make into row vector
        if iscolumn(holder)
            holder = holder';
        end 
        segments{peaki} = holder;
        peak_ranges{peaki} = [this_peaks(peaki), this_peaks(peaki + 1) - 1];

    end 

end 
