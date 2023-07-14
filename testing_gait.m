load('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\concatenated periods\FL\1087\stride_segmentations.mat')

b = vertcat(stride_segmentations{192,1}{:});
figure; hold on; for i = 1:2984; plot(b{i}); end
title('startwalk FL velocity strides');
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\startwalk FL velocity strides.fig')
new_segs = NaN(2984, 10);
for i = 1:2984 

    new_segs(i, :) = resample(b{i}, 10, numel(b{i}));

end 

figure; hold on; for i = 1:2984; plot(new_segs(i, :)); end
title('resampled startwalk FL velocity strides');
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\resampled startwalk FL velocity strides.fig')

mn = mean(new_segs, 1, 'omitnan');
std_dev = std(new_segs, [], 1, 'omitnan');
figure; plot(mn); hold on;
plot(mn + std_dev); plot( mn - std_dev);
title('mean resampled startwalk FL velocity strides with std')
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\mean resampled startwalk FL velocity strides with std.fig');

close all

%% spontaneous walk
b = vertcat(stride_segmentations{196,1}{:});
figure; hold on; for i = 1:9143; plot(b{i}); end
title('spontaneous walk FL velocity strides');
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\spontaneous walk FL velocity strides.fig')
new_segs = NaN(9143, 10);
for i = 1:9143 

    new_segs(i, :) = resample(b{i}, 10, numel(b{i}));

end 

figure; hold on; for i = 1:9143; plot(new_segs(i, :)); end
title('resampled spontaneous walk FL velocity strides');
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\resampled spontaneous walk FL velocity strides.fig')

mn = mean(new_segs, 1, 'omitnan');
std_dev = std(new_segs, [], 1, 'omitnan');
figure; plot(mn); hold on;
plot(mn + std_dev); plot( mn - std_dev);
title('mean resampled spontaneous walk FL velocity strides with std')
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\mean resampled spontaneous walk FL velocity strides with std.fig');

close all

%% motorized walk
b = vertcat(stride_segmentations{195,1}{:});
figure; hold on; for i = 1:21464; plot(b{i}); end
title('motorized walk FL velocity strides');
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\motorized walk FL velocity strides.fig')

new_segs = NaN(9143, 10);
for i = 1:9143 

    new_segs(i, :) = resample(b{i}, 10, numel(b{i}));

end 

figure; hold on; for i = 1:9143; plot(new_segs(i, :)); end
title('resampled motorized walk FL velocity strides');
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\resampled motorized walk FL velocity strides.fig')

mn = mean(new_segs, 1, 'omitnan');
std_dev = std(new_segs, [], 1, 'omitnan');
figure; plot(mn); hold on;
plot(mn + std_dev); plot( mn - std_dev);
title('mean resampled motorized walk FL velocity strides with std')
savefig('Y:\Sarah\Analysis\Experiments\Random Motorized Treadmill\behavior\gait analysis\stride segmentations\mean resampled motorized walk FL velocity strides with std.fig');

close all