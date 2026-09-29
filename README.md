# medonko-pro-workflow

Analysis code for the manuscript *Patient-Reported Outcomes Workflow and Missingness in Routine Oncological Care* (Schwenke et al., 2026).

The study describes the routine, REDCap-based collection of EORTC patient-reported outcome (PRO) questionnaires in the medical oncology outpatient clinic of the University Hospital Basel, Switzerland. It covers questionnaire handout rates, the effect of reminders to reception staff, item-level missingness, EORTC score availability, survey completion time, and a survey of clinical staff.

## Data availability

**This repository contains code only. No patient-level data are included.**

The underlying data contain sensitive clinical information and are not publicly available. They may be made available from the corresponding author upon reasonable request, subject to institutional and ethics requirements (Ethics Committee of Northwest and Central Switzerland, BASEC 2024-00972).

## Repository structure

```
_quarto.yml   Quarto project configuration (render order of the analyses)
R/            Shared helper functions
  io.R              directory creation, parquet/RDS writing, PNG/SVG plot export
  table_rendering.R table formatting helpers
analyses/     One Quarto document per analysis stage (see below)
```

The following directories are created locally when the pipeline runs and are excluded from version control:

- `data/clean/`: input data (not shared)
- `output/`: derived datasets, imputations, fitted models, tables and figures
- `_site/`, `_freeze/`, `.quarto/`: Quarto render output and caches

## Analysis pipeline

| Document | Purpose | Output directory |
|---|---|---|
| `00_build_analysis_datasets.qmd` | Builds the canonical patient-, questionnaire- and item-level datasets | `output/derived/` |
| `01_cohort_description.qmd` | Patient and questionnaire characteristics | `output/01_cohort/` |
| `02_missingness_descriptive.qmd` | Descriptive summaries of missing items | `output/02_missingness_descriptive/` |
| `03a_missingness_imputation.qmd` | Multiple imputation (`mice`) of covariates for the missingness models | `output/03_imputation/` |
| `03b_missingness_models_binary.qmd` | Questionnaire-level missingness model (`rms`), bootstrap validation, calibration and variable importance | `output/03_missingness_models_binary/` |
| `03c_item_position_effect.qmd` | Effect of item position on item-level missingness | `output/03c_position_effect/` |
| `04_score_computability.qmd` | Availability of EORTC scale scores | `output/04_score_computability/` |
| `05_reminder_design.qmd` | Expected vs observed handout rates and the reminder comparison | `output/05_reminder_design/` |
| `06_redcap_staff_survey.qmd` | Clinical staff survey on the REDCap-based PRO workflow | `output/06_redcap_staff_survey/` |
| `07_survey_completion_time.qmd` | Questionnaire completion time | `output/07_survey_completion_time/` |

`00_build_analysis_datasets.qmd` must run first. `03a_missingness_imputation.qmd` must run before `03b_missingness_models_binary.qmd`.

## Required input files

Place the following files in `data/clean/`:

- `analysis_data_long_2026-08-11.parquet`: long-format questionnaire item data with patient and visit covariates
- `UmfrageQoLInDerMedOn_DATA_2026-06-21_1421.csv`: REDCap export of the clinical staff survey

## Running the analyses

Requirements:

- R 4.6.1
- Quarto 1.9 (Typst output)
- R packages: `tidyverse`, `here`, `arrow`, `mice`, `rms`, `Hmisc`, `MASS`, `patchwork`, `scales`, `flextable`, `tinytable`, `table1`

Run from the repository root so that `here()` resolves paths correctly.

Render the full pipeline:

```bash
quarto render
```

Or render a single stage:

```bash
quarto render analyses/00_build_analysis_datasets.qmd
```

Every figure is saved as both PNG and SVG in the corresponding `output/` directory.

## License

The code in this repository is released under the [MIT License](LICENSE). This applies to the code only; it grants no rights to the underlying patient data.
