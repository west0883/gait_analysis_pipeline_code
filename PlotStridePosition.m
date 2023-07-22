% PlotStridePosition.m
% Sarah West
% 7/21/23

function [parameters] = PlotStridePosition(parameters)

    x = parameters.x;
    y = parameters.y; 
    resampleLength = parameters.resampleLength;

    MessageToUser('Resampling ', parameters);

    % Put strides of different instances together on same level
    x_together = vertcat(x{:});
    y_together = vertcat(y{:});

    % If empty, tell RunAnalysis to skip saving & skip to next item
    if isempty(x_together)
        dont_save1 = repmat({false}, 6,1);
        dont_save2 = repmat({true}, 3, 1);
        parameters.dont_save = [dont_save1; dont_save2];

        parameters.x_together = x_together;
        parameters.y_together = y_together;
        parameters.average = [];
        parameters.std_dev = [];
        parameters.x_resampled = [];
        parameters.y_resampled = [];

        parameters.fig_positions_together = [];
        parameters.fig_resampled = [];
        parameters.fig_average = [];


        return
    end 

    % Make a holder matrix for the resampled timeseries. (Is an array
    % instead of a cell array because they're the same length now). 
    x_resampled = NaN(size(x_together, 1), resampleLength);
    y_resampled = NaN(size(x_together, 1), resampleLength);
    
    % For each entry/stride, resample to the desired length
    for i = 1:size(x_together, 1) 
    
        x_resampled(i, :) = resample(x_together{i}, resampleLength, numel(x_together{i}));
        y_resampled(i, :) = resample(y_together{i}, resampleLength, numel(y_together{i}));

    end 
     
    % Take mean and standard deviation
    x_average = mean(x_resampled, 1, 'omitnan');
    x_std_dev = std(x_resampled, [], 1, 'omitnan');
    y_average = mean(y_resampled, 1, 'omitnan');
    y_std_dev = std(y_resampled, [], 1, 'omitnan');

    % Create a colormap for beginning to end 
    mymap = jet(size(x_together, 1));

    % get mouse and period for figure titles
    mouse = parameters.values{strcmp(parameters.keywords, 'mouse')};
    period = parameters.values{strcmp(parameters.keywords, 'type_tag')};
    paw = parameters.values{strcmp(parameters.keywords, 'paw')};

    % Plot un-resampled strides together
    fig_positions_together = figure;
    hold on;
    for i = 1:size(x_together, 1) 
        plot(x_together{i}, y_together{i}, 'Color', mymap(i, :));
    end 
    xlim([-60 100]);
    ylim([-20 20]);
    title(['stride positions, ' mouse ', '  paw, ', ' period], 'Interpreter', 'none'); 
  
    % Plot resampled strides together
    fig_resampled = figure; 
    hold on; 
    for i = 1:size(x_resampled, 1) 
         plot(x_resampled(i, :), y_resampled(i, :), 'Color', mymap(i, :));
    end 
    xlim([-60 100]);
    ylim([-20 20]);
    title(['resampled stride positions, ' mouse ', '  paw, ', ' period], 'Interpreter', 'none'); 
    
    % Plot mean and std of strides
    fig_average = figure;
    hold on;
    errorbar(x_average, y_average,  y_std_dev, y_std_dev, x_std_dev,  x_std_dev);
    xlim([-20 40]);
    ylim([-10 10]);
    title(['stride position mean with std, ' mouse ', '  paw,  ', ',  period], 'Interpreter', 'none'); 

    average = [x_average; y_average];
    std_dev = [x_std_dev; y_std_dev];

    % Put all output variables into output structure
    parameters.x_together = x_together;
    parameters.y_together = y_together;
    parameters.x_resampled = x_resampled;
    parameters.y_resampled = y_resampled;
    parameters.average = average;
    parameters.std_dev = std_dev;
    parameters.fig_positions_together = fig_positions_together;
    parameters.fig_resampled = fig_resampled;
    parameters.fig_average = fig_average;
end 