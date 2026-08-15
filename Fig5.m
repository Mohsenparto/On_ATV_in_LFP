%% plot_fig5

% Reproduces Fig. 5 panels 
% Requires:  
%  -  shadedErrorBar.m  (Mathworks File Exchange)
%   - figdata_lfp_tf.mat and figdata_mua_sua.mat 

% Author: moh3enparto@gmail.com
% Date:   08.08.2026

clear; close all;
set(groot, 'defaultAxesTickDir',     'out');
set(groot, 'defaultAxesTickDirMode', 'manual');

%% -- Load summary data -------------------------------------------------------
load('figdata_mua_sua.mat', 'mua_sua_summary', 'plot_params');
load('figdata_lfp_tf.mat',  'lfp_tf_summary');   

fixation_sample = plot_params.fixation_sample;
edge_samples    = plot_params.edge_samples;
event_line      = plot_params.event_line;
TFfreq          = plot_params.TFfreq;
band_edges      = plot_params.band_edges;
band_labels     = plot_params.band_labels;
stepL           = plot_params.stepL;

band_colors = 'gbrmk';

%% -- MUA and SUA time courses -------------------------------------
panel_order    = {'mua_mean', 'mua_var', 'mua_fano', ...
                  'sua_mean', 'sua_var', 'sua_fano'};
subplot_pos    = [1, 2, 3, 5, 6, 7];
group_titles   = {'MUA', '', [num2str(stepL), ' ms window'], ...
                  'SUA', '', ''};
              
figure('Name', 'Fig 5 : MUA / SUA variability');
for pi = 1:6
    s = mua_sua_summary.(panel_order{pi});

    subplot(4, 4, subplot_pos(pi));
    x_axis = 1:length(s.mean_across_channels);
    shadedErrorBar(x_axis, s.mean_across_channels, s.sem_across_channels, '-k', 1);
    axis tight;
    line([event_line; event_line], ...
         [min(ylim); max(ylim)], 'Color', 'k');
    ylabel(s.label);
    setCustomXTicks2(event_line);
    if ~isempty(group_titles{pi}), title(group_titles{pi}); end
    if pi == 6, xlabel('Time (ms)'); end
    box off;
end

%% -- LFP TFR spectrograms and per-band time courses ---------------
tfr_fields  = {'lfpTF_mean',  'lfpTF_var',  'lfpTF_fano'};
tfr_labels  = {'Mean(Power)', 'SD(Power)',   'CV(Power)'};

figure('Name', 'Fig 5 : LFP TFR variability');

for mi = 1:3
    s     = lfp_tf_summary.(tfr_fields{mi});
    tfr   = s.tfr_grand_mean;          % [time × freq]
    n_t   = size(tfr, 1);
    fix_x = round(n_t / 2)-edge_samples;           % fixation onset

    % -- TFR spectrogram ---------------------------------------------------
    subplot(6, 4, mi + 1);
    imagesc(tfr');
    set(gca, 'YDir', 'normal'); colormap('jet'); shading interp;
    title(tfr_labels{mi});
    set(gca, 'XTick',      [1, fix_x, 2*fix_x], ...
             'XTickLabel', {'-.8', '0', '.8'}, ...
             'YTick',      1:4:length(TFfreq), ...
             'YTickLabel', TFfreq(1:4:end));
    colorbar('Position', [0.285 + mi*0.21, 0.87, 0.007, 0.1]);
    if mi == 1
        xlabel('Time (s)'); ylabel('Frequency (Hz)');
    end
    box off;

    % -- Per-band time courses ---------------------------------------------
    for bi = 1:4
        tc = s.band_timecourses.(band_labels{bi});

        subplot(6, 4, (mi + 1) + 4*bi);
        x_axis = 1:length(tc.mean);
        shadedErrorBar(x_axis, tc.mean, tc.sem, band_colors(bi), 1);
        xlim([1, length(x_axis)]);
        line([fix_x; fix_x], [min(ylim); max(ylim)], 'Color', 'k');
        set(gca, 'Box', 'off', 'TickDir', 'out', ...
                 'XTick',      [1, fix_x, 2*fix_x], ...
                 'XTickLabel', {'-.8', '0', '.8'});
        if mi == 1, ylabel(band_labels{bi}); end
        if bi == 4 && mi == 2, xlabel('Time (s)'); end
    end
end

