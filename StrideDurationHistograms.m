% StrideDurationHistograms.m
% Sarah West
% 7/21/23

% Plots lengths of mouse paw strides in time ("durations"; calculated from paw
% velocities already segmented into individual strides) as histograms

function [parameters] = StrideDurationHistograms(parameters) 
    
    % Inputs
    data = parameters.data; % column vector of integers; the stride durations for a given mouse & period
    bin_edges = parameters.bin_edges; % bin edges 

    % Outputs
    % parameters.fig -- the histogram

    MessageToUser('Plotting ', parameters);

    % Make histogram
    fig = figure; 
    histogram(data, bin_edges);

    % Make title
    mouse = parameters.values{strcmp(parameters.keywords, 'mouse')}; 
    paw = parameters.values{strcmp(parameters.keywords, 'paw')}; 
    period = parameters.values{strcmp(parameters.keywords, 'period')}; 
    period_iterator = parameters.values{strcmp(parameters.keywords, 'period_iterator')}; 

    title([parameters.title_string ', m' mouse ', ' paw ', ', period ' ' period_iterator], 'Interpreter', 'none');

    % Put into output
    parameters.fig = fig;


end 