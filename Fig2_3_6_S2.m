%% analyze_ECoG_neural_variability
%
% Main analysis script for LFP variability and power across cortical areas.
% Reproduces Figs. 2, 3, and 6 of the associated publication.
%
% Analysis pipeline:
%   1. Load pre-processed LFP data (mean, SD, CV of TFR; raw power)
%   2. Plot TFR spectrograms and frequency-band time courses (Mean / SD / CV)
%   3. Compute cross-area power:variability scatter (ITV vs ATV)
%   4. Plot raw LFP mean and variability (attention in vs out)
%   5. Plot power spectrum and power variability (attention in vs out)
%
% Requires:
%   - Fig2_3_6_data<monkey><filt><interval><freq>.mat
%   - shadedErrorBar.m (Mathworks File Exchange)
%
% Author: moh3enparto@gmail.com
% Date:   01.04.2026

clear; close all;
save_figures = 0;   % set to 1 to save figures to disk

%% -- Analysis configuration -------------------------------------------------
% state selects the figure / data variant to reproduce:
%   1 : Fig. 2 (filtered, gamma band)
%   2 : Fig. 2 (filtered, alpha band)
%   3 : Fig. 6 + Fig. 2e + Fig. 3  
%   4 : Fig. 2f  (change epoch)
%   5 : Fig. S2  (monkey 2, raw)
analysis_state = 3;

switch analysis_state
    case 1,  monkey_id = 1; filter_flag = 1; freq_band_type = 1; epoch_interval = 'pos';
    case 2,  monkey_id = 1; filter_flag = 1; freq_band_type = 2; epoch_interval = 'pos';
    case 3,  monkey_id = 1; filter_flag = 0; freq_band_type = 1; epoch_interval = 'pos';
    case 4,  monkey_id = 1; filter_flag = 0; freq_band_type = 1; epoch_interval = 'change';
    case 5,  monkey_id = 2; filter_flag = 0; freq_band_type = 1; epoch_interval = 'pos';
end

if filter_flag == 0, freq_band_type = 1; end   % raw data: gamma only

% Processing options
cut_window  = 100;   % samples to cut after filtering to remove edge artefacts
smooth_win  = 50;    % samples for temporal smoothing
sel_ch      = [1:3];   %  ch indices

% Monkey-specific frequency parameters (Hz)
if monkey_id == 1
    gamma_lo = 65;  gamma_hi = 85;
    alpha_lo = 6;   alpha_hi = 18;
    hbeta_lo = 15;  hbeta_hi = 30;
    if freq_band_type == 1, ref_freq = 65; else, ref_freq = 7; end
elseif monkey_id == 2
    gamma_lo = 55;  gamma_hi = 75;
    alpha_lo = 15;  alpha_hi = 30;
    hbeta_lo = 7;   hbeta_hi = 15;
    if freq_band_type == 1, ref_freq = 54; else, ref_freq = 7; end
end

% Epoch of interest for statistical comparisons
if freq_band_type == 1, stat_epoch = 2400:3000;
else,                   stat_epoch = 1900:2400;
end

%% -- Load data --------------------------------------------------------------
data_file = ['Fig2_3_6_data', num2str(monkey_id), num2str(filter_flag), ...
              epoch_interval, num2str(ref_freq), '.mat'];
load(data_file, 'a');
cellfun(@(f) assignin('base', f, a.(f)), fieldnames(a));

% Build frequency-band index arrays from TFfreq vector
band_edges  = {[4 8], [8 12], [12 30], [55 80]};
band_titles = {'Theta', 'Alpha', 'Beta', 'Gamma'};
n_bands     = length(band_edges);
freq_band_idx = cell(1, n_bands);
for bi = 1:n_bands
    freq_band_idx{bi} = find(TFfreq >= band_edges{bi}(1) & TFfreq <= band_edges{bi}(2));
end

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
            t_win = time_windows{tw};
            for area_idx = 1:length(areas)
                sig_win = LFP_sig(area_idx, :, t_win);
                % ATV: variance across trials (between-trial)
                atv_areas(area_idx, 1) = mean(reshape((sig_win - mean(sig_win, 2)).^2, [], 1));
                % ITV: variance across time (within-trial)
                itv_areas(area_idx, 1) = mean(reshape((sig_win - mean(sig_win, 3)).^2, [], 1));
                % Evoked ITV: variability of the trial-average
                evoked_itv(area_idx, 1) = mean((nanmean(sig_win, 2) - mean(nanmean(sig_win, 2), 3)).^2);
            end

            % ITV vs ATV scatter
            figure(51); subplot(2, 2, tw); hold on;
            [corr_r, corr_p] = corr(itv_areas, atv_areas, 'Type', 'Pearson');
            [fit_model, ~]   = fit(itv_areas, atv_areas, 'poly1');
            fit_handle = plot(fit_model, itv_areas, atv_areas);
            set(fit_handle, 'LineWidth', 2, 'Color', [0 0 0]);
            scatter(itv_areas, atv_areas, 40, 'o', ...
                'MarkerFaceColor', [.1 .1 .1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', .2);
            text(itv_areas, atv_areas, sprintfc(' %d', 1:numel(areas)));
            line([.5 1], [.5 1], 'LineStyle', '--', 'Color', 'r'); axis square;
            legend('off');
            xlabel('ITV'); ylabel('ATV');
            title(['Time window: ', num2str(t_win(1)/1000), ':', num2str(t_win(end)/1000), ' s']);
            corr_slope = polyfit(itv_areas, atv_areas, 1); corr_slope = corr_slope(1);
            text(mean(xlim), min(ylim) + 0.2*abs(min(ylim)), ...
                 {['r = ', num2str(corr_r)], ['slope = ', num2str(corr_slope)], ['p = ', num2str(corr_p)]});

            % ATV/ITV ratio vs Evoked/ITV ratio scatter
            figure(52); subplot(2, 2, tw); hold on;
            [corr_r, corr_p] = corr(atv_areas./itv_areas, evoked_itv./itv_areas, 'Type', 'Pearson');
            [fit_model, ~]   = fit(atv_areas./itv_areas, evoked_itv./itv_areas, 'poly1');
            fit_handle = plot(fit_model, atv_areas./itv_areas, evoked_itv./itv_areas);
            set(fit_handle, 'LineWidth', 2, 'Color', [0 0 0]);
            scatter(atv_areas./itv_areas, evoked_itv./itv_areas, 40, 'o', ...
                'MarkerFaceColor', [.1 .1 .1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', .2);
            text(atv_areas./itv_areas, evoked_itv./itv_areas, sprintfc(' %d', 1:numel(areas)));
            axis square; legend('off');
            xlabel('ATV / ITV ratio'); ylabel('Evoked ITV / ITV ratio');
            title(['Time window: ', num2str(t_win(1)/1000), ':', num2str(t_win(end)/1000), ' s']);
            corr_slope = polyfit(atv_areas./itv_areas, evoked_itv./itv_areas, 1); corr_slope = corr_slope(1);
            text(mean(xlim), min(ylim) + 0.2*abs(min(ylim)), ...
                 {['r = ', num2str(corr_r)], ['slope = ', num2str(corr_slope)], ['p = ', num2str(corr_p)]});
        end

        figure(52); subplot(2, 2, 4); hold on;
        bar(evoked_itv);
        xlabel('Area index'); ylabel('Evoked ITV');
        set(gca, 'XTick', 1:length(areas), 'XTickLabel', areas);
    end
end

%% -- LFP mean and variability: attention in vs out --------------------------
if monkey_id == 1 && analysis_state ~= 4

    figure;

    % Mean LFP
    subplot(3, 3, 1); hold on;
    plot(squeeze(nanmean(Mean_IN( sel_ch, :), 1))', 'r');
    plot(squeeze(nanmean(Mean_OUT(sel_ch, :), 1))', 'k');
    xlim([cut_window, len - cut_window]);
    event_lines_ms = [800, 1600, 2400] - smooth_win;
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});
    xlabel('Time (s)'); ylabel('Mean LFP');
    legend('Att-in', 'Att-out');
    text('Units', 'normalized', 'String', 'F      S     C     Ch', 'Position', [0.08 0.98 0]);

    % LFP variance
    subplot(3, 3, 4); hold on;
    plot(smooth(squeeze(nanmean(var_IN( sel_ch, :), 1)), smooth_win)', 'r');
    plot(smooth(squeeze(nanmean(var_OUT(sel_ch, :), 1)), smooth_win)', 'k');
    xlim([cut_window, len - cut_window]);
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});
    ylabel('Variance');
    text('Units', 'normalized', 'String', 'F      S     C     Ch', 'Position', [0.08 0.98 0]);

    % Statistical tests (rank-sum) for key epochs
    [p_full,  ~] = ranksum(squeeze(nanmean(var_IN_ch( sel_ch, :, stat_epoch), [1,3])), ...
                           squeeze(nanmean(var_OUT_ch(sel_ch, :, stat_epoch), [1,3])));
    [p_stim,  ~] = ranksum(squeeze(nanmean(var_IN_ch( sel_ch, :, 1100:1600), [1,3])), ...
                           squeeze(nanmean(var_OUT_ch(sel_ch, :, 300:800),   [1,3])));
    [p_change, ~] = ranksum(squeeze(nanmean(var_IN_ch( sel_ch, :, 1900:2400), [1,3])), ...
                            squeeze(nanmean(var_OUT_ch(sel_ch, :, 300:800),   [1,3])));
    subplot(3, 3, 7); hold on;
    text(0, .5, {['p (full epoch) = ',   num2str(p_full,  '%.2e')], ...
                  ['p (stim epoch) = ',  num2str(p_stim,  '%.2e')], ...
                  ['p (change epoch) = ', num2str(p_change, '%.2e')]});

    %% -- ITV time courses ----------------------------------------------------
    if exist('ITV_IN', 'var')
        figure;
        subplot(3, 3, 4); hold on;
        plot(smooth(squeeze(nanmean(ITV_IN( sel_ch, :), 1)), smooth_win)', 'r');
        plot(smooth(squeeze(nanmean(ITV_OUT(sel_ch, :), 1)), smooth_win)', 'k');
        xlim([cut_window, len - cut_window]);
        line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
        set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});
        ylabel('ITV');
        text('Units', 'normalized', 'String', 'F      S     C     Ch', 'Position', [0.08 0.98 0]);
    end

    %% -- Power, power SD, and power CV time courses --------------------------
    figure;

    subplot(3, 3, 1); hold on;
    plot(smoothdata(nanmean(Pow_IN( sel_ch, :)), 2, 'movmean', smooth_win), 'r');
    plot(smoothdata(nanmean(Pow_OUT(sel_ch, :)), 2, 'movmean', smooth_win), 'k');
    xlim([cut_window, len - cut_window]); ylabel('Power');
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});

    subplot(3, 3, 4); hold on;
    plot(smoothdata(nanmean(PowVar_IN( sel_ch, :)), 2, 'movmean', smooth_win), 'r');
    plot(smoothdata(nanmean(PowVar_OUT(sel_ch, :)), 2, 'movmean', smooth_win), 'k');
    xlim([cut_window, len - cut_window]); ylabel('SD(Power)');
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});

    subplot(3, 3, 7); hold on;
    plot(smoothdata(nanmean(PowCV_IN( sel_ch, :)), 2, 'movmean', smooth_win), 'r');
    plot(smoothdata(nanmean(PowCV_OUT(sel_ch, :)), 2, 'movmean', smooth_win), 'k');
    xlim([cut_window, len - cut_window]); ylabel('CV(Power)');
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});
    xlabel('Time (s)'); legend('Att-in', 'Att-out');

    %% -- Absolute LFP mean and variance --------------------------------------
    figure;

    subplot(3, 3, 1); hold on;
    plot(squeeze(nanmean(Mean_IN_abs( sel_ch, :), 1))', 'r');
    plot(squeeze(nanmean(Mean_OUT_abs(sel_ch, :), 1))', 'k');
    xlim([cut_window, len - cut_window]);
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});
    xlabel('Time (s)'); ylabel('Mean |LFP|'); legend('Att-in', 'Att-out');
    text('Units', 'normalized', 'String', 'F      S     C     Ch', 'Position', [0.08 0.98 0]);

    subplot(3, 3, 4); hold on;
    plot(smooth(squeeze(nanmean(var_IN_abs( sel_ch, :), 1)), smooth_win)', 'r');
    plot(smooth(squeeze(nanmean(var_OUT_abs(sel_ch, :), 1)), smooth_win)', 'k');
    xlim([cut_window, len - cut_window]);
    line([event_lines_ms; event_lines_ms], ylim, 'LineStyle', '--', 'Color', 'm');
    set(gca, 'XTick', [800, 1600, 2400], 'XTickLabel', {'0', '.8', '1.6', '2.4'});
    ylabel('Variance |LFP|');

    [p_full,   ~] = ranksum(squeeze(nanmean(var_IN_abs_ch( sel_ch, :, stat_epoch), [1,3])), ...
                            squeeze(nanmean(var_OUT_abs_ch(sel_ch, :, stat_epoch), [1,3])));
    [p_stim,   ~] = ranksum(squeeze(nanmean(var_IN_abs_ch( sel_ch, :, 1100:1600), [1,3])), ...
                            squeeze(nanmean(var_OUT_abs_ch(sel_ch, :, 300:800),   [1,3])));
    [p_change, ~] = ranksum(squeeze(nanmean(var_IN_abs_ch( sel_ch, :, 1900:2400), [1,3])), ...
                            squeeze(nanmean(var_OUT_abs_ch(sel_ch, :, 300:800),   [1,3])));
    subplot(3, 3, 7);
    text(0, .5, {['p (full epoch) = ',    num2str(p_full,   '%.2e')], ...
                  ['p (stim epoch) = ',   num2str(p_stim,   '%.2e')], ...
                  ['p (change epoch) = ', num2str(p_change, '%.2e')]});
end

%% -- Power spectra: attention in vs out -------------------------------------
if filter_flag == 0 && monkey_id == 1

    figure;
    for area_idx = 1:length(twoarea)
        % Low-frequency band (1:45 Hz)
        subplot(2, 2, area_idx); hold on;
        plot(squeeze(mean(mean(RawpowI(:, sel_ch, 1:45),  1), 2))', 'r');
        plot(squeeze(mean(mean(RawpowO(:, sel_ch, 1:45),  1), 2))', 'k');
        [p_alpha, ~] = ranksum(squeeze(nanmean(RawpowI(:, sel_ch, alpha_lo:alpha_hi), [2,3])), ...
                               squeeze(nanmean(RawpowO(:, sel_ch, alpha_lo:alpha_hi), [2,3])));
        title(num2str(p_alpha, '%.2e'));
        set(gca, 'XTick', 1:10:40, 'XTickLabel', Freq(1:10:40));

        % High-frequency band (40:90 Hz, gamma)
        subplot(2, 2, area_idx + 2); hold on;
        plot(squeeze(mean(mean(RawpowI(:, sel_ch, 55:90), 1), 2))', 'r');
        plot(squeeze(mean(mean(RawpowO(:, sel_ch, 55:90), 1), 2))', 'k');
        [p_gamma, ~] = ranksum(squeeze(nanmean(RawpowI(:, sel_ch, gamma_lo:gamma_hi), [2,3])), ...
                               squeeze(nanmean(RawpowO(:, sel_ch, gamma_lo:gamma_hi), [2,3])));
        title(num2str(p_gamma, '%.2e'));
        set(gca, 'XTick', 1:10:50, 'XTickLabel', 40:10:90);
    end
end

