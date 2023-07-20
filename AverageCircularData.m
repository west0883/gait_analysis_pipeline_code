% AverageCircularData.m
% Sarah West
% 7/20/23

function [parameters] = AverageCircularData(parameters)

    % Display progress message to user.
    MessageToUser('Averaging ', parameters);

    % Pull out data.
    data = parameters.data; 

    % Pull out weights
    if isfield(parameters, 'weights')
        weights = parameters.weights; 

    else
        weights = ones(size(data));
    end 
% 
%     % If user says to remove outliers
%     if isfield(parameters, 'removeOutliers') && parameters.removeOutliers
% 
%         % Remove outliers along averageDim, replace with NaNs.
%         outliers = isoutlier(data, parameters.averageDim);
%         data(outliers) = NaN;
%     end 

    % take out nans 
    data = data(~isnan(data));
    weights = weights(~isnan(data));

    % if user says not to squeeze the data, don't
    if isfield(parameters, 'useSqueeze') && ~parameters.useSqueeze
        %  Take the mean
        average = circ_mean(data, weights, parameters.averageDim); 
    
        % Take the standard deviation
        std_dev = circ_std(data, weights, [], parameters.averageDim); 
    else
         %  Take the mean
        average = squeeze(circ_mean(data, weights, parameters.averageDim)); 
    
        % Take the standard deviation
        std_dev = squeeze(circ_std(data, weights, [],  parameters.averageDim)); 
    end

    % If user says to put the average & std_dev in the same file,
    if isfield(parameters, 'average_and_std_together') && parameters.average_and_std_together
       parameters.average = [average, std_dev];
    else
        % Put them in different places/files
       parameters.average = average;
       parameters.std_dev = std_dev;
    end

end 