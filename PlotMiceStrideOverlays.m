% PlotMiceStrideOverlays.m
% Sarah West 
% 7/18/23

% For a given behavior period plots the average, resampled stride
% (normalized to be 10 data points long) of each mouse onto the same
% figure. Each line has the standard error of the mean as error bars.
% Runs with RunAnalysis

function [parameters] = PlotMiceStrideOverlays(parameters)
    
    % Inputs
    % parameters.average -- a vector, one per mouse; the mean stride
    % parameters.std_dev -- a vector, one per mouse; the standard deviation
    % of that mouse's stride
    % parameters.resampled -- a matrix, one per mouse; all the strides for
    % that period in that mouse; is for getting the number of samples to
    % plot the standard error of the mean
    % parameters.instancesDim -- integer; the dimension of
    % 'resampled' that has different instances 
    % parameters.ylimits -- pair of scalars; is the yaxis limit you want to
    % plot
    % parameters.mymap -- the colormap you want to use to plot each mouse

    % Outputs
    % parameters.fig -- the figure of overlaid strides

    % Tell user what iteration you're on
    MessageToUser('Plotting ', parameters);

    % Pull out inputs 
    average = parameters.average;
    std_dev = parameters.std_dev;
    resampled = parameters.resampled;
    instancesDim = parameters.instancesDim;
    ylimits = parameters.ylimits;
    mymap = parameters.mymap;

    % If the output figure hasn't been created yet, do it now
    if ~isfield(parameters, 'fig') || isempty(parameters.fig)
        
        fig = figure; 

        % clear any previous legend entries
        legend_text = {};
        parameters.legend_text = {};

        % Get the current period & iterator
        period = parameters.values{strcmp(parameters.keywords, 'period')};
        period_iterator = parameters.values{strcmp(parameters.keywords, 'period_iterator')};

        if any(strcmp(parameters.keywords, 'paw'))
            paw = parameters.values{strcmp(parameters.keywords, 'paw')};
            paw_section = [ paw ', '];
        else
            paw_section = [];
        end 

        if any(strcmp(parameters.keywords, 'velocity_direction'))
            velocity_direction = parameters.values{strcmp(parameters.keywords, 'velocity_direction')};
            velocity_direction_section = [ velocity_direction ', '];
        else
            velocity_direction_section = [];
        end 

        % Make figure title 
        title(['mean with std_dev, ' paw_section velocity_direction_section period ' ' num2str(period_iterator)], 'Interpreter', 'none');

    % If it has been created, pull it out of the parameters structure
    else
        fig = parameters.fig;
        legend_text = parameters.legend_text;
    end

    % Keep plots from one mouse to the next
    hold on;

    % if no data in average, skip to next 
    if isempty(average)
        parameters.fig = fig;
        parameters.legend_text = legend_text;
        return
    end

    % Calculate standard error of the mean (sem)
    SEM = std_dev./sqrt(size(resampled, instancesDim));

    % Get the mouse & mouse iterator for legend and color
    mouse = parameters.values{strcmp(parameters.keywords, 'mouse')};
    mouse_iterator = parameters.values{strcmp(parameters.keywords, 'mouse_iterator')};

    % grab the color for the lines
    this_color = mymap(mouse_iterator, :); 

    % Plot the average and shaded error bars % S
    s = shadedErrorBar(1:10, average, std_dev , 'lineProps', {'-','color', this_color}, 'patchSaturation', 0.2);
    delete(s.edge); % delete shaded area edges
    set(s.mainLine, 'LineWidth', 2);
   
    % Set the y axis limits
    ylim(ylimits);

    % create the legend
    legend_text = [legend_text, {mouse}];
    legend(legend_text);

    % Put the output figure into outputs
    parameters.fig = fig;
    parameters.legend_text = legend_text;
end 
