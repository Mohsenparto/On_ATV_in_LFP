%%  fig1_fig4_atv_itv_ECoG
%
% Plots example LFP trials, ERP, across-trial variability (ATV), and
% intra-trial variability (ITV). Also examines how power and its
% coefficient of variation (CV) change when stimulus amplitude is scaled.
% Used to reproduce Figs. 1 and 4 of the associated publication.
%
% Requires:
%   - Fig1_4_data<band><filt>.mat  containing: Sig, Sig1, Sig2, Sig3
%   - shadedErrorBar.m (Mathworks File Exchange)
%
% Author: moh3enparto@gmail.com
% Date:   01.04.2026

clc; clear all; close all;

%% -- Configuration ----------------------------------------------------------
filter_flag = 0;   % 1 = filtered (Fig. 1)   0 = wideband (Figs. 1 & 4)

% Smoothing windows (samples)
lfp_smooth_win = 5;    % smoothing for raw LFP traces
pow_smooth_win = 5;    % smoothing for power traces
itv_window     = 50;   % sliding window for ITV computation

% Loop over frequency bands if data is filtered
if filter_flag == 0
    band_conditions = 1;
else
    band_conditions = 1:2;
end

%% -- Main loop --------------------------------------------------------------
for band = band_conditions

    load(['Fig1_4_data', num2str(band), num2str(filter_flag), '.mat'], ...
         'Sig', 'Sig1', 'Sig2', 'Sig3');   % loads pre-processed LFP signals

    set(groot, 'defaultAxesTickDir',     'out');
    set(groot, 'defaultAxesTickDirMode', 'manual');

    %% -- Fig. 1: ATV sample plot ---------------------------------------------
    trial_plot_idx = 1:20;   % subset of trials to display
    time_labels    = {'-.8', '-.4', '0', '.4', '.8'};
    time_ticks     = [1, 400, 800, 1200, 1600];
    stim_line      = 800 - lfp_smooth_win;   % stimulus onset (adjusted for smoothing)

    figure;

    % Raw trial traces
    subplot(2, 2, 1);
    plot(Sig(trial_plot_idx, :)', 'LineWidth', .1, 'Color', 'k');
    line([stim_line; stim_line], ylim, 'LineStyle', '--', 'Color', 'k');
    set(gca, 'XTick', time_ticks, 'XTickLabel', time_labels);
    xlabel('Time from stim-onset (s)'); ylabel('LFP amplitude');

    % Event-related potential (ERP = trial average)
    subplot(2, 2, 2);
    plot(nanmean(Sig)', 'LineWidth', .5, 'Color', 'k');
    line([stim_line; stim_line], ylim, 'LineStyle', '--', 'Color', 'k');
    set(gca, 'XTick', time_ticks, 'XTickLabel', time_labels);
    xlabel('Time from stim-onset (s)'); ylabel('ERP');

    % ATV (across-trial variance at each time point)
    subplot(2, 2, 3);
    plot(var(Sig)', 'LineWidth', .5, 'Color', 'k');
    line([stim_line; stim_line], ylim, 'LineStyle', '--', 'Color', 'k');
    set(gca, 'XTick', time_ticks, 'XTickLabel', time_labels);
    xlabel('Time from stim-onset (s)'); ylabel('ATV');

    % ITV (sliding-window within-trial variance)
    itv_timecourse = zeros(1, size(Sig2, 2) - itv_window);
    for t_idx = 1 : size(Sig2, 2) - itv_window
        itv_timecourse(t_idx) = nanmean(var(Sig2(:, t_idx : t_idx+itv_window), [], 2)');
    end
    subplot(2, 2, 4);
    plot(itv_timecourse, 'LineWidth', .5, 'Color', 'k');
    line([800; 800],            ylim, 'LineStyle', '--', 'Color', 'k');
    line([800-itv_window; 800-itv_window], ylim, 'LineStyle', '--', 'Color', 'k');
    set(gca, 'XTick', time_ticks, 'XTickLabel', time_labels);
    xlabel('Time from stim-onset (s)'); ylabel('ITV');

    %% -- Fig. 4: Effect of amplitude scaling on power and CV -----------------
    if filter_flag == 0

        % Amplitude scale factors: 1×, 10×, 0.1× applied to stimulus period
        amplitude_scales = [1, 10, 0.1];
        subplot_counter  = 1;
        power_label = 'Power';  

        for scale_idx = 1:3
        figure(200 + 100*band);
            amp_scale = amplitude_scales(scale_idx);

            % Scale the stimulus period (samples 801:1600)
            sig_scaled = Sig1;
            sig_scaled(:, 801:1600) = Sig1(:, 801:1600) .* amp_scale;
            sig_smoothed = smoothdata(sig_scaled, 2, 'movmean', lfp_smooth_win);

            % Signal, variance, and CV
            subplot(3, 6, subplot_counter); subplot_counter = subplot_counter + 1;
            plot(sig_smoothed(trial_plot_idx, :)', 'LineWidth', .5, 'Color', 'k');
            title(['Stim. ×', num2str(amp_scale)]);

            sig_variance = var(sig_smoothed);
            sig_auc      = trapz(abs(sig_smoothed));
            subplot(3, 6, subplot_counter); subplot_counter = subplot_counter + 1;
            plot(sig_variance, 'LineWidth', .5, 'Color', 'k');
            if scale_idx == 1, title('Var(Signal)'); end

            subplot(3, 6, subplot_counter); subplot_counter = subplot_counter + 1;
            plot(sig_variance ./ sig_auc, 'LineWidth', .5, 'Color', 'k');
            if scale_idx == 1, title('CV(Signal)'); end

            % Power matrix
            power_matrix = zeros(size(Sig1));
            for tr = 1:size(Sig1, 1)
                    power_matrix(tr, :) = smoothdata(abs(Sig1(tr, :).^2), 2, 'movmean', pow_smooth_win);
            end

            subplot(3, 6, subplot_counter); subplot_counter = subplot_counter + 1;
            plot(nanmean(power_matrix), 'LineWidth', .5, 'Color', 'k');
            if scale_idx == 1, title(['Mean(', power_label, ')']); end

            power_std = std(power_matrix);
            subplot(3, 6, subplot_counter); subplot_counter = subplot_counter + 1;
            plot(power_std, 'LineWidth', .5, 'Color', 'k');
            if scale_idx == 1, title(['SD(', power_label, ')']); end

            coeff_var = nanstd(power_matrix) ./ nanmean(power_matrix);
            subplot(3, 6, subplot_counter); subplot_counter = subplot_counter + 1;
            plot(coeff_var, 'LineWidth', .5, 'Color', 'k');
            if scale_idx == 1, title(['CV(', power_label, ')']); end

            %% -- ITV vs ATV scatter under amplitude scaling -------------------
                sig_rescaled = Sig3 .* amp_scale;
                clear atv_channels itv_channels;
                for ch = 1:size(sig_rescaled, 1)
                    y_ch = squeeze(sig_rescaled(ch, :, :));
                    atv_channels(ch, :) = mean(mean((y_ch - mean(y_ch, 1)).^2, 2), 1);
                    itv_channels(ch, :) = mean(mean((y_ch - mean(y_ch, 2)).^2, 2), 1);
                end

                figure(1100 + 100*band);
                subplot(2, 3, scale_idx); hold on;
                [corr_r, corr_p] = corr(itv_channels, atv_channels, 'Type', 'Pearson');
                [fit_model, ~]   = fit(itv_channels, atv_channels, 'poly1');
                fit_handle = plot(fit_model, itv_channels, atv_channels);
                set(fit_handle, 'LineWidth', 2, 'Color', [0 0 0]);
                scatter(itv_channels, atv_channels, 40, 'o', ...
                    'MarkerFaceColor', [.1 .1 .1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', .2);
                corr_slope = polyfit(itv_channels, atv_channels, 1); corr_slope = corr_slope(1);
                legend('off');
                xlabel('ITV (a.u.)'); ylabel('ATV (a.u.)');
                title({['r = ', num2str(corr_r)], ...
                       ['slope = ', num2str(corr_slope)], ...
                       ['p = ', num2str(corr_p)]});
                box off; axis tight; axis square;
                line([0, max(xlim)], [0, max(ylim)], 'LineStyle', '-', 'Color', 'b');
        end   % amplitude scale loop
    end   % wideband check
end   % band loop

