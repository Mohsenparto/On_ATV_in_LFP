# Neural Variability Analysis — MATLAB Code

Code accompanying the publication:

> **On variability in local field potentials**  
>  Mohsen Parto-Dezfouli,  Elizabeth L. Johnson,  Eleni Psarou,  Conrado Arturo Bosman,  B. Suresh Krishna,  Pascal Fries
>  *biorxiv*, doi: 10.1101/2025.03.27.645661

---

## Overview

This repository contains MATLAB scripts for analysing **across-trial variability (ATV)** and **intra-trial variability (ITV)** of LFP and EEG, and their relationship to neural power. Four scripts reproduce the main figures of the paper.

| Script | Description | Figures |
|--------|-------------|---------|
| `Fig4.m` | Simulates LFP-like signals under five fixed/random noise mixture conditions and computes ATV–ITV correlations | Fig. 4 |
| `Fig1_4.m` | Plots example trials, ERP, ATV and ITV from real LFP data; tests effect of amplitude scaling on power CV | Figs. 1, 4 |
| `Fig2_3_6_S2.m` | Main analysis: TFR spectrograms (Mean / SD / CV), cross-area ITV–ATV scatter, attention comparisons | Figs. 2, 3, 6 |
| `Fig7.m` | Plots TFR spectrograms and per-band time courses of Mean, SD, and CV | Fig. 7 |

---

## Requirements

### MATLAB toolboxes
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox
- Curve Fitting Toolbox

### External dependencies
- [`shadedErrorBar`](https://uk.mathworks.com/matlabcentral/fileexchange/26311) — Rob Campbell, MATLAB File Exchange  
  Download and place `shadedErrorBar.m` in the repository folder (or add it to your MATLAB path).
- `clearex` — clears all variables except specified ones  
  Available on the MATLAB File Exchange, or replace with a manual `clearvars -except`.

---

## Data

Pre-processed data files are available on:

| File | Used by |
|------|---------|
| `Fig7.mat` | `Fig7.m` |
| `Fig1_4_data<band><filt>.mat` | `Fig1f_i_Fig4d_f.m` |
| `Fig2_3_6_data<monkey><filt><interval><freq>.mat` | `Fig2_3_6_S2.m` |

Download all `.mat` files and place them in the **same directory** as the scripts.

---

## Usage

1. Clone the repository and add it to your MATLAB path:
   ```matlab
   addpath(genpath('path/to/this/repo'))
   ```

2. Download the data files (see above) and place them in the repo folder.

3. Run any script directly from the MATLAB editor or command window:
   ```matlab
   Fig4      		% simulation figures
   Fig1f_i_Fig4d_f      % Figs. 1 & 4
   Fig2_3_6_S2     	% Figs. 2, 3 & 6
   Fig7       		% Fig. 7
   ```

4. In `Fig2_3_6_S2.m`, set `analysis_state` to select the figure variant:

   | `analysis_state` | Output |
   |---|---|
   | 1 | Fig. 2 — filtered, gamma |
   | 2 | Fig. 2 — filtered, alpha |
   | 3 | Figs. 3, 6, 2e — raw, gamma |
   | 4 | Fig. 2f — raw, change epoch |
   | 5 | Fig. S2 — monkey 2 |

---

## Key Concepts

**ATV (across-trial variability)**: variance *across* trials at each time point — captures how consistently the neural response is reproduced.

**ITV (intra-trial variability)**: variance *across time* within each trial — captures ongoing fluctuations in neural activity.

**CV (coefficient of variation)**: SD divided by Mean — a normalised measure of dispersion used here to compare variability across frequencies and brain areas.

---

## Citation

If you use this code, please cite:

```bibtex
@On variability in local field potentials
  doi     = 10.1101/2025.03.27.645661 
}
```

---

## License

This code is released under the Creative Commons Attribution 4.0 International (LICENSE).
