% GaitResampling.m
% Sarah West
% 7/14/23

function [parameters] = GaitResampling(parameters)

    data = parameters.data;
    resampleLength = parameters.resampleLength;

    MessageToUser('Resampling ', parameters);

    % Put strides of different instances together on same level
    segmentations_together = vertcat(data{:});
   
    % If empty, tell RunAnalysis to skip saving & skip to next item
    if isempty(segmentations_together)
        dont_save1 = repmat({false}, 4,1);
        dont_save2 = repmat({true}, 3, 1);
        parameters.dont_save = [dont_save1; dont_save2];

        parameters.segmentations_together = segmentations_together;
        parameters.resampled = [];
        parameters.average = [];
        parameters.std_dev = [];

        parameters.fig_segmentations_together = [];
        parameters.fig_resampled = [];
        parameters.fig_average = [];

        return
    end 

    % Make a holder matrix for the resampled timeseries. (Is an array
    % instead of a cell array because they're the same length now). 
    resampled = NaN(size(segmentations_together, 1), resampleLength);
    
    % For each entry/stride, resample to the desired length
    for i = 1:size(segmentations_together, 1) 
    
        resampled(i, :) = resample(segmentations_together{i}, resampleLength, numel(segmentations_together{i}));

    end 
     
    % Take mean and standard deviation
    average = mean(resampled, 1, 'omitnan');
    std_dev = std(resampled, [], 1, 'omitnan');

    % Create a colormap for beginning to end 
    mymap = jet(size(segmentations_together, 1));

    % Plot un-resampled strides together
    fig_segmentations_together = figure;
    hold on;
    for i = 1:size(segmentations_together, 1) 
        plot(segmentations_together{i}, 'Color', mymap(i, :));
    end 

    % Plot resampled strides together
    fig_resampled = figure; 
    hold on; 
    for i = 1:size(segmentations_together, 1) 
         plot(resampled(i, :), 'Color', mymap(i, :));
    end 

    % Plot mean and std of strides
    fig_average = figure;
    hold on;
    plot(average)
    plot(average + std_dev);
    plot(average - std_dev);

    % Put all output variables into output structure
    parameters.segmentations_together = segmentations_together;
    parameters.resampled = resampled;
    parameters.average = average;
    parameters.std_dev = std_dev;
    parameters.fig_segmentations_together = fig_segmentations_together;
    parameters.fig_resampled = fig_resampled;
    parameters.fig_average = fig_average;
end 