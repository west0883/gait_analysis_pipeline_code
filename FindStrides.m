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
% parameters.data -- matrix; the paw velocity trace.
% parameters.timeDime -- the dimension of .data that corresponsds to time;
%                        other dimensions are different instances of paw movement. 
% parameters.peakThreshold -- positive scalar; the "th" value for peakdet
% parameters.minDistance -- positive integer; the minimum distance between
%                           peaks/strides. 4 = max 5 Hz stride 

    
% b = a - mean(a);
% [pks,dep,pid,did] = peakdet(b, 0.05 , 'zero', 2);


end 

