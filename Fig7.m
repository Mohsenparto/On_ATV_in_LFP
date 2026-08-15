%% plot_fig7
%
% Plots time-frequency representations (TFR) of spectral Mean, SD, and CV
% for neural LFP data, plus time-course plots per canonical frequency band.
%
% Requires:
%   - Fig7.mat containing: V1, M1, frq, Tt, Tl, frband, bandTitle, fs
%   - shadedErrorBar.m (Mathworks File Exchange)
%
% Outputs:
%   - Figure with TFR spectrograms (Mean, SD, CV) and per-band time courses
%
% Author: moh3enparto@gmail.com
% Date:   08.08.2026

clear; close all;
%% -- Load data -------------------------------------------------------------
% V1        : SD of TFR    [channels × frequencies × time]
% M1        : Mean of TFR  [channels × frequencies × time]
% frq       : Frequency vector (Hz)
% Tt / Tl   : Time tick positions / labels
% frband    : Cell array of band edges, e.g. {[4 8], [8 12], [12 30], [55 80]}
% bandTitle : Cell array of band names, e.g. {'Theta','Alpha','Beta','Gamma'}
% fs        : Sampling rate (Hz)
load('Fig7.mat', 'V1', 'M1', 'frq', 'Tt', 'Tl', 'frband', 'bandTitle', 'fs')

%% -- Pre-processing ---------------------------------------------------------
% Flip frequency axis  
freq_flipped    = flip(frq);
mean_tf_flipped = flip(M1, 2);   % Mean TFR with flipped frequency axis
std_tf_flipped  = flip(V1, 2);   % SD  TFR with flipped frequency axis

% Restrict to 4-40 Hz
freq_idx_4to40 = find(freq_flipped >= 4 & freq_flipped <= 40);

% Trim edges to avoid filter ringing artefacts
edge_samples = 50;                                               % samples to trim each side
time_idx     = (1 + edge_samples) : (size(M1, 3) - edge_samples);

% Adjust stored time-tick positions for the trimmed edges
time_ticks_adj        = Tt;
time_ticks_adj(2:end) = time_ticks_adj(2:end) - edge_samples;

% Event-line positions (task events) in trimmed-time coordinates
event_lines = time_ticks_adj(2:4) - edge_samples / fs;

%% -- TFR spectrograms: Mean · SD · CV --------------------------------------
figure;

% Helper: common axis settings for TFR images
set_tfr_axes = @(ax) set(ax, ...
    'YDir',        'normal', ...
    'XTickLabel',  {Tl}, ...
    'XTick',       floor(time_ticks_adj), ...
    'YTick',       1 : 5 : length(freq_idx_4to40), ...
    'YTickLabel',  round(freq_flipped(freq_idx_4to40(1:5:end))));

% Mean
subplot(5, 5, 1); hold on;
imagesc(squeeze(nanmean(mean_tf_flipped(:, freq_idx_4to40, time_idx))));
title('Mean');
set_tfr_axes(gca); axis tight;
colormap('jet'); shading interp;
colorbar('Position', [0.28*1 + 0*0.04,  0.82,  0.007,  0.1]);
ylabel('Frequency (Hz)');

% SD
subplot(5, 5, 3); hold on;
imagesc(squeeze(nanmean(std_tf_flipped(:, freq_idx_4to40, time_idx))));
title('SD');
set_tfr_axes(gca); axis tight;
colormap('jet'); shading interp;
colorbar('Position', [0.28*2 + 1*0.04,  0.82,  0.007,  0.1]);

% CV  (SD / Mean)
subplot(5, 5, 5); hold on;
cv_map = squeeze( nanmean(std_tf_flipped( :, freq_idx_4to40, time_idx)) ./ ...
                  nanmean(mean_tf_flipped(:, freq_idx_4to40, time_idx)) );
imagesc(cv_map);
title('CV');
set_tfr_axes(gca); axis tight;
xlabel('Time (s)');
colormap('jet'); shading interp;
colorbar('Position', [0.28*3 + 2*0.04,  0.82,  0.007,  0.1]);
box off;

%% -- Time courses per frequency band ---------------------------------------
band_colors  = 'gbrmk';   % one colour per canonical band
metric_names = {'Mean', 'SD', 'CV'};

for band_idx = 1:4
    % Frequency indices for this band
    freq_idx_band = find(freq_flipped >= frband{band_idx}(1) & ...
                         freq_flipped <= frband{band_idx}(2));

    for metric_idx = 1:3
        % Compute the chosen metric averaged over band frequencies
        switch metric_idx
            case 1   % Mean
                band_timecourse = squeeze(nanmean(mean_tf_flipped(:, freq_idx_band, time_idx), 2));
            case 2   % SD
                band_timecourse = squeeze(nanmean(std_tf_flipped(:, freq_idx_band, time_idx), 2));
            case 3   % CV = SD / Mean
                band_timecourse = squeeze( ...
                    nanmean(std_tf_flipped( :, freq_idx_band, time_idx), 2) ./ ...
                    nanmean(mean_tf_flipped(:, freq_idx_band, time_idx), 2) );
        end

        n_subjects = size(band_timecourse, 1);
        x_axis     = 1 : size(band_timecourse, 2);

        subplot(5, 5, 1 + 2*(metric_idx-1) + 5*band_idx);
        hold on;
        shadedErrorBar(x_axis, ...
                       mean(band_timecourse, 1), ...
                       std(band_timecourse, [], 1) ./ sqrt(n_subjects), ...
                       band_colors(band_idx), 1);
        xlim([1, length(x_axis)]);
        set(gca, 'XTickLabel', {}, 'XTick', []);
        line([event_lines; event_lines], ...
             [repmat(min(ylim), 1, length(event_lines)); ...
              repmat(max(ylim), 1, length(event_lines))], 'Color', 'k');
        box off;
        if metric_idx == 1
            ylabel(bandTitle{band_idx});
        end
    end
end

