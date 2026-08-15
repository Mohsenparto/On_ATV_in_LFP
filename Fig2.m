%% plot_fig2
%
% Reproduces all Fig. 2 panels 
%
% Requires: 
%   filt=0 Fig2_filt0_ga1_pos.mat   or  Fig2_filt0_ga1_change.mat
%   filt=1 Fig2_filt1_ga1_pos.mat   or  Fig2_filt1_ga2_pos.mat
%
% Author: moh3enparto@gmail.com
% Date:   08.08.2026

clear; close all;
set(groot, 'defaultAxesTickDir',     'out');
set(groot, 'defaultAxesTickDirMode', 'manual');

%% -- Select parameter combination -------------------------------------------
filter_flag    = 1;     % 0 = wideband  |  1 = filtered
gamma_alpha    = 2;     % 1 = gamma  |  2 = alpha
epoch_interval = 'pos'; % 'pos'  |  'change'

% filt=0 always uses gammaAlpha=1
if filter_flag == 0, gamma_alpha = 1; end

%% -- Load matching summary file ----------------------------------------------
summary_file = sprintf('Fig2_filt%d_ga%d_%s.mat', filter_flag, gamma_alpha, epoch_interval);
load(summary_file);  

area_labels = plot_params.area_labels;
n_areas     = length(area_labels);

%% ----------------------------------------------------------------------------
%  BRANCH A: wideband (filt == 0) : power spectra
% ----------------------------------------------------------------------------
if filter_flag == 0

    Freq = plot_params.Freq;

    figure('Name', 'Power spectra (wideband)');

    for ai = 1:n_areas
        lbl = area_labels{ai};
        s   = pow_summary.(lbl);

        % -- Row 1: low-freq spectrum (1:45 Hz) ---------------------------
        subplot(2, n_areas, ai); hold on;
        plot(s.low_freq.mean_IN,  'r');
        plot(s.low_freq.mean_OUT, 'k');
        title([lbl, '  p(\alpha) = ', num2str(s.low_freq.p_alpha, '%.2e')]);
        set(gca, 'XTick',      1:10:40, ...
                 'XTickLabel', Freq(1:10:40));
        if ai == 1
            ylabel('Power (a.u.)');
            legend('Att-in', 'Att-out', 'Location', 'best');
        end
        box off;

        % -- Row 2: gamma band (40:90 Hz) ---------------------------------
        subplot(2, n_areas, ai + n_areas); hold on;
        plot(s.gamma.mean_IN,  'r');
        plot(s.gamma.mean_OUT, 'k');
        title([lbl, '  p(\gamma) = ', num2str(s.gamma.p_gamma, '%.2e')]);
        set(gca, 'XTick',      1:10:50, ...
                 'XTickLabel', 40:10:90);
        if ai == 1
            xlabel('Frequency (Hz)');
            ylabel('Power (a.u.)');
        end
        box off;
    end

%% ----------------------------------------------------------------------------
%  BRANCH B: filtered (filt == 1) : LFP mean, variance, absolute versions
% ----------------------------------------------------------------------------
elseif filter_flag == 1

    cut_win  = plot_params.cut_window;
    len      = plot_params.len;
    x_full   = 1:len;
    x_trim   = cut_win : len - cut_win;
    fixL = floor(length(x_trim)/30*8);
    x_ticks  = [fixL, 2*fixL, 3*fixL];
    x_labels = {'0', '.8', '1.6', '2.4'};
    event_lines = [fixL, 2*fixL, 3*fixL];

    % Helper: draw event lines within current axes limits
    draw_events = @() line( ...
        [event_lines; event_lines], ...
        [repmat(min(ylim), 1, 3); repmat(max(ylim), 1, 3)], ...
        'LineStyle', '--', 'Color', 'm');

    %% -- Figure 1: LFP mean time courses ------------------------------------
    figure('Name', 'LFP Mean : att-in vs att-out');

    for ai = 1:n_areas
        lbl = area_labels{ai};
        s   = lfp_summary.(lbl).lfp_mean;
        n_t = length(s.mean_IN);

        subplot(2, n_areas, ai); hold on;
        plot(s.mean_IN(x_trim),  'r');
        plot(s.mean_OUT(x_trim), 'k');
        xlim([1, length(x_trim)]);
        draw_events();
        set(gca, 'XTick', x_ticks, 'XTickLabel', x_labels);
        title(lbl);
        if ai == 1
            xlabel('Time (s)'); ylabel('Mean LFP');
            legend('Att-in', 'Att-out', 'Location', 'best');
            text('Units', 'normalized', 'String', 'F           S          C       Ch', ...
                 'Position', [0.075 0.98 0]);
        end
        box off;
    end

    %% -- Figure 2: LFP variance time courses --------------------------------
    figure('Name', 'LFP Variance : att-in vs att-out');

    for ai = 1:n_areas
        lbl = area_labels{ai};
        s   = lfp_summary.(lbl).lfp_var;

        subplot(2, n_areas, ai); hold on;
        plot(s.mean_IN( x_trim), 'r');
        plot(s.mean_OUT(x_trim), 'k');
        xlim([1, length(x_trim)]);
        draw_events();
        set(gca, 'XTick', x_ticks, 'XTickLabel', x_labels);
        title(sprintf('%s   p_{full}=%.2e   p_{stim}=%.2e   p_{ch}=%.2e', ...
              lbl, s.p_full, s.p_stim, s.p_change));
        if ai == 1
            xlabel('Time (s)'); ylabel('Variance');
            legend('Att-in', 'Att-out', 'Location', 'best');
            text('Units', 'normalized', 'String', 'F           S          C       Ch', ...
                 'Position', [0.075 0.98 0]);
        end
        box off;
    end

    %% -- Figure 3: Absolute LFP mean ----------------------------------------
    figure('Name', 'Absolute LFP Mean : att-in vs att-out');

    for ai = 1:n_areas
        lbl = area_labels{ai};
        s   = lfp_summary.(lbl).lfp_mean_abs;

        subplot(2, n_areas, ai); hold on;
        plot(s.mean_IN( x_trim), 'r');
        plot(s.mean_OUT(x_trim), 'k');
        xlim([1, length(x_trim)]);
        draw_events();
        set(gca, 'XTick', x_ticks, 'XTickLabel', x_labels);
        title(lbl);
        if ai == 1
            xlabel('Time (s)'); ylabel('Mean |LFP|');
            legend('Att-in', 'Att-out', 'Location', 'best');
            text('Units', 'normalized', 'String', 'F           S          C       Ch', ...
                 'Position', [0.075 0.98 0]);
        end
        box off;
    end

    %% -- Figure 4: Absolute LFP variance ------------------------------------
    figure('Name', 'Absolute LFP Variance : att-in vs att-out');

    for ai = 1:n_areas
        lbl = area_labels{ai};
        s   = lfp_summary.(lbl).lfp_var_abs;

        subplot(2, n_areas, ai); hold on;
        plot(s.mean_IN( x_trim), 'r');
        plot(s.mean_OUT(x_trim), 'k');
        xlim([1, length(x_trim)]);
        draw_events();
        set(gca, 'XTick', x_ticks, 'XTickLabel', x_labels);
        title(sprintf('%s   p_{full}=%.2e   p_{stim}=%.2e   p_{ch}=%.2e', ...
              lbl, s.p_full, s.p_stim, s.p_change));
        if ai == 1
            xlabel('Time (s)');  
            legend('Att-in', 'Att-out', 'Location', 'best');
            text('Units', 'normalized', 'String', 'F           S          C       Ch', ...
                 'Position', [0.075 0.98 0]);
        end
        box off;
    end

end   