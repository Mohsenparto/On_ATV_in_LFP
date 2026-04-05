%% simulate_signal_conditions
%
% Simulates multi-trial LFP-like signals under five senarios that the
% stimulus SD varies compared to the baseline (Fixation-like period) SD.
% Computes across-trial variability (ATV), within-trial power variability
% (ITV), and their cross-subject correlation for each condition.
%
% Conditions:
%   1 : Low variability  (s = 0.5 × base STD)
%   2 : High variability (s = 2   × base STD)
%   3 : 50 % fixed + 50 % random
%   4 : 20 % fixed + 80 % random
%   5 : 10 % fixed + 90 % random
%
% Requires: clearex.m (available on Mathworks File Exchange)
%
% Author: moh3enparto@gmail.com
% Date:   01.04.2026

close all;

for condition_idx = 1:5   % loop over the five signal conditions

clc;
clearex('condition_idx');   % keep only the loop counter between iterations
set(groot, 'defaultAxesTickDir',     'out');
set(groot, 'defaultAxesTickDirMode', 'default');

%% -- Parameters -------------------------------------------------------------
fs                 = 1000;   % sampling rate (Hz)
trial_duration     = 1.5;    % total trial length (s)
n_trials           = 100;    % trials per subject
n_subjects         = 20;     % simulated subjects
pre_stim_dur       = 0.5;    % pre-stimulus period length (s)  : high variability
post_stim_dur      = 1.0;    % post-stimulus period length (s) : lower / fixed variability

% Base noise distribution
noise_mean = 0;
noise_std  = 4;

% Time vector and period masks
time_vec      = 0 : 1/fs : trial_duration - 1/fs;
pre_stim_mask = time_vec <= pre_stim_dur;
post_stim_mask = time_vec > pre_stim_dur & time_vec <= (pre_stim_dur + post_stim_dur);

%% -- Simulate signals -------------------------------------------------------
for sub_idx = 1:n_subjects

    % Subject-level noise scale (drawn once per subject)
    subject_noise_scale = noise_std * rand(1) + noise_mean;

    for trial_idx = 1:n_trials

        % Generate the fixed (reproducible) noise component on the first trial
        if trial_idx == 1
            fixed_noise = noise_std .* subject_noise_scale .* ...
                          randn(1, sum(post_stim_mask)) + noise_mean;
        end

        n_pre  = sum(pre_stim_mask);
        n_post = sum(post_stim_mask);

        switch condition_idx
            case 1  % small random (0.5× STD)
                post_rand_std = 2;
                trial_data(trial_idx, post_stim_mask) = ...
                    post_rand_std * subject_noise_scale * randn(1, n_post) + noise_mean;
                trial_data(trial_idx, pre_stim_mask) = ...
                    noise_std .* subject_noise_scale * randn(1, n_pre);

            case 2  % large random (2× STD)
                post_rand_std = 8;
                trial_data(trial_idx, post_stim_mask) = ...
                    post_rand_std * subject_noise_scale * randn(1, n_post) + noise_mean;
                trial_data(trial_idx, pre_stim_mask) = ...
                    noise_std .* subject_noise_scale * randn(1, n_pre);

            case 3  % 50 % fixed + 50 % random
                post_rand_std = 4;
                trial_data(trial_idx, post_stim_mask) = ...
                    (5*fixed_noise + ...
                     5*post_rand_std*subject_noise_scale*randn(1, n_post) + noise_mean) ./ 10;
                trial_data(trial_idx, pre_stim_mask) = ...
                    (5*noise_std.*subject_noise_scale*randn(1, n_pre) + ...
                     5*noise_std.*subject_noise_scale*randn(1, n_pre)) ./ 10;

            case 4  % 20 % fixed + 80 % random
                post_rand_std = 4;
                trial_data(trial_idx, post_stim_mask) = ...
                    (2*fixed_noise + ...
                     8*post_rand_std*subject_noise_scale*randn(1, n_post) + noise_mean) ./ 10;
                trial_data(trial_idx, pre_stim_mask) = ...
                    (2*noise_std.*subject_noise_scale*randn(1, n_pre) + ...
                     8*noise_std.*subject_noise_scale*randn(1, n_pre)) ./ 10;

            case 5  % 10 % fixed + 90 % random
                post_rand_std = 4;
                trial_data(trial_idx, post_stim_mask) = ...
                    (1*fixed_noise + ...
                     9*post_rand_std*subject_noise_scale*randn(1, n_post) + noise_mean) ./ 10;
                trial_data(trial_idx, pre_stim_mask) = ...
                    (1*noise_std.*subject_noise_scale*randn(1, n_pre) + noise_mean + ...
                     9*noise_std.*subject_noise_scale*randn(1, n_pre) + noise_mean) ./ 10;
        end
    end   % trials

    subject_data{sub_idx} = trial_data;
    clear trial_data;

    %% -- Diagnostic plots for the first subject -----------------------------
    if sub_idx == 1
        time_axis  = (0 : length(time_vec)-1) / fs;
        sig_scaled = 10 .* squeeze(subject_data{1});

        figure;

        % Raw trials
        subplot(2, 3, 1);
        plot(time_axis, sig_scaled');
        xlabel('Time (s)'); ylabel('Amplitude');
        title(['Condition ', num2str(condition_idx)]);
        box off; axis square;

        % Across-trial variability (ATV)
        atv_timecourse = var(sig_scaled, 1);
        subplot(2, 3, 4);
        plot(time_axis, atv_timecourse);
        xlabel('Time (s)'); ylabel('ATV'); box off; axis square;

        % Power (log and linear) and coefficient of variation
            power_matrix = zeros(size(sig_scaled));
            for tr = 1:size(sig_scaled, 1)
                    power_matrix(tr, :) = abs(sig_scaled(tr, :)).^2;
            end

            subplot(2, 3, 2);
            plot(nanmean(power_matrix), 'LineWidth', .5, 'Color', 'k');
            ylabel('Power'); 
            xlabel('Time (s)'); box off; axis square;

            coeff_var = nanstd(power_matrix) ./ nanmean(power_matrix);
            subplot(2, 3, 5);
            plot(smooth(coeff_var, 50), 'LineWidth', .5, 'Color', 'k');
             ylabel('CV(Power)');
            xlabel('Time (s)'); box off; axis square;
    end

end   % subjects

%% -- Power:Variability correlation (cross-subject) -------------------------
% Post-stimulus samples used for correlation
post_stim_samples = 501:1500;

clear atv_per_subject itv_per_subject;
for sub_idx = 1:length(subject_data)
    y = subject_data{sub_idx}(:, post_stim_samples);
    % ATV: variance across trials at each time point, then averaged
    atv_per_subject(sub_idx, :) = mean(mean((y - mean(y, 1)).^2, 2), 1);
    % ITV: variance across time within each trial, then averaged
    itv_per_subject(sub_idx, :) = mean(mean((y - mean(y, 2)).^2, 2), 1);
end

subplot(2, 3, 6); hold on;
[corr_r, corr_p]  = corr(itv_per_subject, atv_per_subject, 'Type', 'Pearson');
[fit_model, ~]    = fit(itv_per_subject, atv_per_subject, 'poly1');
fit_handle        = plot(fit_model, itv_per_subject, atv_per_subject);
set(fit_handle, 'LineWidth', 2, 'Color', [0 0 0]);
scatter(itv_per_subject, atv_per_subject, 40, 'o', ...
    'MarkerFaceColor', [.1 .1 .1], 'MarkerEdgeColor', [0 0 0], 'LineWidth', .2);
poly_coeffs = polyfit(itv_per_subject, atv_per_subject, 1);
corr_slope  = poly_coeffs(1);
legend('off');
xlabel('ITV (a.u.)'); ylabel('ATV (a.u.)');
title({['r = ', num2str(corr_r)], ['slope = ', num2str(corr_slope)], ...
       ['p = ',  num2str(corr_p)]});
box off; axis tight; axis square;
line([0, max(xlim)], [0, max(ylim)], 'LineStyle', '-', 'Color', 'b');

% Overlay conditions 1 and 3 on a shared summary figure
condition_colors = 'gyryy';
if condition_idx == 1 || condition_idx == 3
    figure(100); hold on;
    [corr_r, corr_p] = corr(itv_per_subject, atv_per_subject, 'Type', 'Pearson');
    [fit_model, ~]   = fit(itv_per_subject, atv_per_subject, 'poly1');
    fit_line = plot(fit_model, itv_per_subject, atv_per_subject);
    set(fit_line, 'LineWidth', 2, 'Color', condition_colors(condition_idx), ...
        'MarkerFaceColor', [1 1 1], 'MarkerEdgeColor', [1 1 1]);
    legend('off');
end

end   % condition loop

%% -- Summary figure ---------------------------------------------------------
figure(100); hold on;
legend({'', '0.5× STD (cond. 1)', '', '50 % fixed (cond. 3)'});
xlabel('ITV (a.u.)'); ylabel('ATV (a.u.)'); box off;

