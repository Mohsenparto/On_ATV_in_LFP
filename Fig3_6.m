%% plot_fig3_6
%
% Main analysis script for LFP variability and power across cortical areas.
% Reproduces Figs. 3, and 6 of the associated publication.

% Requires:
%   - Fig3_6_summary_<monkey><filt><interval><freq>.mat
%   - shadedErrorBar.m (Mathworks File Exchange)
%
% Author: moh3enparto@gmail.com
% Date:   08.08.2026

clear; close all;

%% -- Analysis configuration -------------------------------------------------
% state selects the figure / data variant to reproduce:
%   1 : Fig. 6 + Fig. 3  
%   2 : Fig. S2  (monkey 2)
analysis_state = 1;  

switch analysis_state
    case 1,  monkey_id = 1; filter_flag = 0; freq_band_type = 1; epoch_interval = 'pos';
    case 2,  monkey_id = 2; filter_flag = 0; freq_band_type = 1; epoch_interval = 'pos'; 
end

if filter_flag == 0, freq_band_type = 1; end   %  data: gamma only

% Processing options
cut_window  = 100;   % samples to cut after filtering to remove edge artefacts
smooth_win  = 50;    % samples for temporal smoothing

% Monkey-specific frequency parameters (Hz)
if monkey_id == 1,     if freq_band_type == 1, ref = 65; else, ref = 7; end
elseif monkey_id == 2, if freq_band_type == 1, ref = 54; else, ref = 7; end
end

%% -- Load data --------------------------------------------------------------

summary_file = ['Fig3_6_summary_', num2str(monkey_id), ...
                num2str(filter_flag), '_', epoch_interval, ...
                '_', num2str(ref), '.mat'];

summary_exists = isfile(summary_file);
load(summary_file);

% Build frequency-band index arrays from TFfreq vector
band_edges  = {[4 8], [8 12], [12 30], [55 80]};
band_titles = {'Theta', 'Alpha', 'Beta', 'Gamma'};
n_bands     = length(band_edges);
freq_band_idx = cell(1, n_bands);
for bi = 1:n_bands
    freq_band_idx{bi} = find(TFfreq >= band_edges{bi}(1) & TFfreq <= band_edges{bi}(2));
end

sel_ch      = [1:3];   %  area indices

set(groot, 'defaultAxesTickDir',     'out');
set(groot, 'defaultAxesTickDirMode', 'manual');

%% -- TFR spectrograms + band time courses -----------------------------------
if filter_flag == 0 && analysis_state ~= 4

    fixation_len    = floor(size(FF, 3) * 800 / TimeL);
    fixation_period = 7 : fixation_len - 7;
    edge_len        = 1;
    end_timepoint   = size(Pow_i, 3);

    band_colors     = 'gbrmk';
    subplot_counter = 1;
    figure;

    for metric_idx = 1:3   % 1=Mean, 2=SD, 3=CV
        clear band_data_cell

        switch metric_idx
            case 1,  metric_data = Mean_i(:, :, edge_len:end_timepoint-edge_len, :); metric_label = 'Mean';
            case 2,  metric_data = STD_i( :, :, edge_len:end_timepoint-edge_len, :); metric_label = 'SD';
            case 3,  metric_data = CV_i(  :, :, edge_len:end_timepoint-edge_len, :); metric_label = 'CV';
        end

        % Average selected channels across conditions
        for cond_idx = 1:size(metric_data, 4)
            band_data_cell{1}(:, :, cond_idx) = squeeze(nanmean(metric_data(sel_ch, :, :, cond_idx), 1));
        end

        event_lines = [fixation_len, 2*fixation_len];

        % TFR image
        subplot(5, 5, 1 + 2*(metric_idx-1));
        imagesc(squeeze(nanmean(band_data_cell{1}, 3)));
        set(gca, 'YDir', 'normal');
        colormap('jet'); shading interp;
        title(metric_label);
        set(gca, 'XTick',       [1, fixation_len, 2*fixation_len, 3*fixation_len], ...
                 'XTickLabel',  {'-.8', '0', '.8', '1.6'}, ...
                 'YTick',       1:8:size(metric_data, 2), ...
                 'YTickLabel',  TFfreq(1:8:end));
        colorbar('Position', [0.28*subplot_counter + (subplot_counter-1)*0.04, 0.82, 0.007, 0.1]);
        if metric_idx == 1, ylabel('Frequency (Hz)'); end
        line([event_lines; event_lines], ...
             [repmat(min(ylim), 1, 2); repmat(max(ylim), 1, 2)], 'Color', 'k');
        box off;

        % Band time courses
        for band_idx = 1:n_bands
            subplot(5, 5, 1 + 2*(metric_idx-1) + 5*band_idx);
            y = squeeze(nanmean(band_data_cell{1}(freq_band_idx{band_idx}, :, :), 1));
            x = 1:size(y, 1);
            shadedErrorBar(x, mean(y, 2), std(y, [], 2) ./ sqrt(size(y, 2)), band_colors(band_idx), 1);
            set(gca, 'XTick',      [1, fixation_len, 2*fixation_len, size(y,1)], ...
                     'XTickLabel', {'-.8', '0', '.8', '1.6'});
            xlim([1, length(x)]);
            if metric_idx == 1, ylabel(band_titles{band_idx}); end
            line([event_lines; event_lines], ...
                 [repmat(min(ylim), 1, 2); repmat(max(ylim), 1, 2)], 'Color', 'k');
            box off;
        end

        subplot_counter = subplot_counter + 1;
    end

    %% -- Cross-area ITV vs ATV scatter ----------------------------------------
    if monkey_id == 1

        time_windows = {300:800, 800:1100, 1100:1600};   % pre / stimulus / post (samples)
for tw = 1:length(time_windows)

    itv_areas     = ITV_summary(:, tw);
    atv_areas     = ATV_summary(:, tw);
    evoked_itv    = EvokedITV_summary(:, tw);

    % ITV vs ATV scatter
    figure(51);
    subplot(2, 2, tw);
    hold on;

    [corr_r, corr_p] = corr(itv_areas, atv_areas, ...
                            'Type', 'Pearson');

    [fit_model, ~] = fit(itv_areas, atv_areas, 'poly1');

    fit_handle = plot(fit_model, itv_areas, atv_areas);
    set(fit_handle, 'LineWidth', 2, 'Color', [0 0 0]);

    scatter(itv_areas, atv_areas, 40, 'o', ...
        'MarkerFaceColor', [.1 .1 .1], ...
        'MarkerEdgeColor', [0 0 0], ...
        'LineWidth', .2);

    text(itv_areas, atv_areas, sprintfc(' %d', 1:numel(areas)));

    line([.5 1], [.5 1], ...
        'LineStyle', '--', 'Color', 'r');

    axis square;
    legend('off');

    xlabel('ITV');
    ylabel('ATV');

    title(['Time window: ', ...
        num2str(time_windows{tw}(1)/1000), ':', ...
        num2str(time_windows{tw}(end)/1000), ' s']);

    corr_slope = polyfit(itv_areas, atv_areas, 1);
    corr_slope = corr_slope(1);

    text(mean(xlim), min(ylim) + 0.2*abs(min(ylim)), ...
        {['r = ', num2str(corr_r)], ...
         ['slope = ', num2str(corr_slope)], ...
         ['p = ', num2str(corr_p)]});


    % ATV/ITV ratio vs Evoked/ITV ratio
    figure(52);
    subplot(2, 2, tw);
    hold on;

    x_ratio = atv_areas ./ itv_areas;
    y_ratio = evoked_itv ./ itv_areas;

    [corr_r, corr_p] = corr(x_ratio, y_ratio, ...
                            'Type', 'Pearson');

    [fit_model, ~] = fit(x_ratio, y_ratio, 'poly1');

    fit_handle = plot(fit_model, x_ratio, y_ratio);

    set(fit_handle, 'LineWidth', 2, 'Color', [0 0 0]);

    scatter(x_ratio, y_ratio, 40, 'o', ...
        'MarkerFaceColor', [.1 .1 .1], ...
        'MarkerEdgeColor', [0 0 0], ...
        'LineWidth', .2);

    text(x_ratio, y_ratio, sprintfc(' %d', 1:numel(areas)));

    axis square;
    legend('off');

    xlabel('ATV / ITV ratio');
    ylabel('Evoked ITV / ITV ratio');

    title(['Time window: ', ...
        num2str(time_windows{tw}(1)/1000), ':', ...
        num2str(time_windows{tw}(end)/1000), ' s']);

    corr_slope = polyfit(x_ratio, y_ratio, 1);
    corr_slope = corr_slope(1);

    text(mean(xlim), min(ylim) + 0.2*abs(min(ylim)), ...
        {['r = ', num2str(corr_r)], ...
         ['slope = ', num2str(corr_slope)], ...
         ['p = ', num2str(corr_p)]});

end

        figure(52); subplot(2, 2, 4); hold on;
bar(EvokedITV_summary(:, 3));
xlabel('Area index'); ylabel('Evoked ITV');
        set(gca, 'XTick', 1:length(areas), 'XTickLabel', areas);
    end
end



