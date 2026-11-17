# Predicting Airbnb Nightly Prices in Los Angeles

An end-to-end regression analysis in R of 34,000+ Los Angeles Airbnb listings: a reproducible cleaning pipeline,
exploratory analysis, and a multiple linear regression that explains which listing features move nightly price
and predicts the price of listings it has not seen. The final model cuts prediction error by about a third
compared with a no-model baseline (test RMSE $134 vs $200).

*Built as the final project for MSBA 500 (Business Analytics Fundamentals) at CSU Channel Islands.*

**Stack:** R (base R), `lm`, cross-validation, GitHub Codespaces dev container
**Data:** [Inside Airbnb](https://insideairbnb.com/get-the-data/), Los Angeles, scraped 2026-09-14

---

## Contents

1. [Highlights](#highlights)
2. [Business question](#business-question)
3. [Approach](#approach)
4. [Key findings](#key-findings)
5. [Model performance](#model-performance)
6. [Data](#data)
7. [Data cleaning](#data-cleaning)
8. [Variables](#variables)
9. [Repository layout](#repository-layout)
10. [How to run](#how-to-run)
11. [Limitations](#limitations)
12. [Roadmap](#roadmap)
13. [Reproducibility](#reproducibility)
14. [Credits](#credits)

---

## Highlights

| | |
| --- | --- |
| Listings analyzed | 34,582 (after cleaning 43,781 raw rows) |
| Outcome | Nightly asking price in USD, modeled as log(price) |
| Evaluation | 80/20 train/test split, 5-fold cross-validation on the training data |
| Test error vs baseline | RMSE **$134** vs $200; MAE **$82** vs $139 |
| Variance explained | R² of **0.67** on log price (held-out test listings) |
| Biggest drivers | Room type, number of bedrooms and guests, neighborhood, shared bathroom, minimum stay |

## Business question

**Which listing features are associated with higher or lower nightly prices on Airbnb in Los Angeles, and how
accurately can those features predict the price of a listing?**

The answer is useful to hosts and property managers pricing a new listing, and to analysts comparing prices
across neighborhoods and room types. The model describes **associations in asking prices**, not causal effects.

## Approach

```text
Raw Inside Airbnb file  →  01_clean.R  →  analytic file (34,582 × 20)
                                          ├→ 02_explore.R  →  summary tables + 6 charts
                                          └→ 03_model.R    →  train/test split, model comparison,
                                                              final model, test evaluation
```

1. **Clean:** keep the 18 columns that would be known when a host sets a price, parse text fields
   (price, bathrooms), remove extreme prices, handle missing values, and engineer features
   (amenity count, shared bathroom, license flag, distance to LAX).
2. **Explore:** summary statistics and six charts covering the price distribution, group comparisons and
   relationships between variables.
3. **Model:** compare a baseline, a small model, a full model and a stepwise-reduced model with 5-fold
   cross-validation on the training data, then score the chosen model on the held-out test data once.
4. **Report:** RMSE and MAE in dollars (log predictions converted back with `exp()`), and R² on the log scale,
   always next to the baseline.

## Key findings

All effects are approximate and hold the other variables fixed. They are associations in asking prices, not
causal effects.

- **Size matters most.** Each extra bedroom goes with about **+16%** in price, and each extra guest a listing
  accommodates with about **+6%**.
- **Room type separates prices sharply.** Compared with entire homes, private rooms are about **34% lower**
  and shared rooms about **62% lower**. Median prices are $250 for entire homes and $86 for private rooms.
- **Location matters.** Santa Monica and Beverly Hills listings sit about $290 in median price, while some
  neighborhoods are far lower. Each mile from LAX goes with about **0.7% lower** price.
- **Shared bathrooms** go with about **24% lower** prices, and a listed license with about **19% higher**.
- **Longer required stays are cheaper per night.** Each additional minimum night goes with about 0.8% lower
  price. About 44% of listings require 30+ nights, and their median nightly price is roughly half that of
  shorter stays.
- **Host badges add little.** Superhost status and identity verification were not statistically significant
  once the listing's features were accounted for.

Charts are saved in `Outputs/`:

| Chart | What it shows |
| --- | --- |
| `fig1_price_distribution.png` | Price is strongly right-skewed (mean about $255, median about $202); log price is far more symmetric |
| `fig2_price_by_room_type.png` | Median price by room type: entire homes $250, hotel rooms $272, private rooms $86, shared rooms about $36 |
| `fig3_accommodates_vs_price.png` | Price rises with guests accommodated and flattens above about 8 guests |
| `fig4_price_by_neighborhood.png` | Median price by neighborhood group, from about $293 down to about $46 |
| `fig5_lax_distance_vs_price.png` | Distance to LAX has only a weak negative relationship with price |
| `fig6_correlation_with_price.png` | Size variables correlate most with log price (accommodates 0.64, bedrooms 0.57, beds 0.52) |

## Model performance

Candidate comparison on the training data (5-fold cross-validation; error is on the log scale):

| Model | Terms | Adjusted R² | CV RMSE (log) |
| --- | ---: | ---: | ---: |
| Baseline (average only) | 0 | 0.000 | 0.7645 |
| Small (guests, room type, neighborhood) | 19 | 0.575 | 0.4988 |
| Full (all 16 candidate predictors) | 39 | 0.696 | 0.4222 |
| Reduced (stepwise from full) | 37 | 0.696 | 0.4222 |

Held-out test results (6,916 listings, scored once):

| Model | RMSE (USD) | MAE (USD) | R² (log price) |
| --- | ---: | ---: | ---: |
| Baseline | 199.69 | 139.10 | 0.000 |
| Final model | 134.03 | 81.78 | 0.668 |

A typical prediction misses by about $82. RMSE is larger because it weights the few expensive listings more.
Test performance is close to training performance, so the model is not badly overfit.

> These numbers come from the run with seed 2026. If the model choice or settings change, rerun
> `03_model.R` and update this section.

Full coefficient estimates with standard errors, p-values and percent effects are in
`Outputs/model_coefficients.csv`.

## Data

| Item | Detail |
| --- | --- |
| Source | [Inside Airbnb](https://insideairbnb.com/get-the-data/), Los Angeles, California |
| File | `listings.csv.gz` (detailed listings), scrape date **2026-09-14** |
| Direct link | <https://data.insideairbnb.com/united-states/ca/los-angeles/2026-09-14/data/listings.csv.gz> |
| Unit of observation | One Airbnb listing (one row per listing `id`) |
| Raw size | 43,781 rows × 90 columns |
| Type | Cross-sectional (one snapshot) |
| Collection | Inside Airbnb collects publicly visible information from the Airbnb website; it is not provided by Airbnb |

Inside Airbnb refreshes its data and moves older scrapes to an archive, so **the copy committed in
`Data/raw/` is the source of truth for this project**. The scripts stop with an error if the raw file does not
have 43,781 rows and 90 columns.

Things to know about the data:

- `price` is the **host's asking price**, not what guests paid.
- A listing priced in this snapshot may not be bookable on every night.
- Inside Airbnb publishes its data under a Creative Commons license. Confirm the current terms and attribution
  requirements at <https://insideairbnb.com/data-policy/> before reusing it.

## Data cleaning

`01_clean.R` prints one line per step, which serves as the cleaning log. Settings such as the price range
and the number of neighborhood groups are at the top of the script.

| Step | What happens | Rows removed | Rows left |
| --- | --- | ---: | ---: |
| 0 | Raw file (90 columns) | – | 43,781 |
| 1 | Keep the 18 columns needed for the analysis | 0 | 43,781 |
| 2 | Remove duplicate listing ids | 0 | 43,781 |
| 3 | Convert `price` from text (for example `$1,234.00`) to a number; remove listings with no price | 7,094 | 36,687 |
| 4 | Remove extreme prices outside $20–$1,000 per night | 2,086 | 34,601 |
| 5 | Report missing values by column (no kept predictor exceeds 10%; `license` is about 70% missing and becomes a yes/no flag) | 0 | 34,601 |
| 6–7 | Convert `t`/`f` columns to TRUE/FALSE, parse `bathrooms_text`, and create `shared_bath`, `n_amenities`, `has_license` and `dist_lax_mi` | 0 | 34,601 |
| 8 | Fill the few missing sizes by random draw from observed values (hot-deck): 77 bedrooms, 880 beds, 62 bathrooms; remove 19 rows with other missing values | 19 | 34,582 |
| 9 | Group rare categories: top 15 neighborhoods and top 8 property types, the rest labeled "Other" | 0 | 34,582 |

**Final analytic file: 34,582 rows × 20 columns.**

Decisions behind the cleaning:

- **Columns dropped:** URLs, free-text descriptions, host fields that are empty in this scrape, outcome and
  demand fields (availability, estimated occupancy and revenue), copies of the price, and review fields.
  Reviews and demand fields only exist after bookings happen, so they would not be known when a host sets a
  price.
- **Price range:** listings above $1,000 are rare asking prices that would dominate the fit. The $20–$1,000
  range is a modeling choice set by `PRICE_MIN` and `PRICE_MAX` in `01_clean.R`, to be tested in the diagnostics.
- **Hot-deck imputation** is used only for the small number of missing size fields (under 3% each).

## Variables

`Data/clean/data_dictionary_draft.csv` lists every variable in the analytic file with its type.

| Variable | Description | Derived from |
| --- | --- | --- |
| `id` | Listing identifier (not a predictor) | – |
| `price` | **Outcome.** Nightly asking price, USD | `price` (text → number) |
| `room_type` | Entire home/apt, Private room, Hotel room, Shared room | – |
| `property_type_grp` | Top 8 property types, others as "Other" | `property_type` |
| `neighborhood_grp` | Top 15 neighborhoods, others as "Other" | `neighbourhood_cleansed` |
| `accommodates` | Number of guests the listing sleeps | – |
| `bedrooms`, `beds` | Counts | – |
| `bathrooms` | Number of bathrooms (0.5 for a half bath) | `bathrooms_text` |
| `shared_bath` | TRUE if the bathroom is shared | `bathrooms_text` |
| `n_amenities` | Number of listed amenities | `amenities` |
| `minimum_nights` | Minimum stay required, in nights | – |
| `has_license` | TRUE if a license or registration number is listed | `license` |
| `dist_lax_mi` | Approximate straight-line miles from LAX | `latitude`, `longitude` |
| `latitude`, `longitude` | Listing coordinates (used only to derive distance; not model predictors) | – |
| `host_is_superhost` | TRUE/FALSE | – |
| `host_identity_verified` | TRUE/FALSE | – |
| `hosts_time_as_host_years` | Years since the host joined | – |
| `calculated_host_listings_count` | Number of listings the host has | – |

`log_price` (the natural log of `price`) is created inside `02_explore.R` and `03_model.R`.

## Repository layout

```text
.
├── .devcontainer/            Codespaces / dev container setup (R 4.4.1, rocker/tidyverse)
├── Data/
│   ├── raw/                  Original download, never edited
│   │   └── los_angeles_airbnb_listings.csv.gz
│   └── clean/                Final analytic file and starter data dictionary
│       ├── airbnb_analytic.csv
│       └── data_dictionary_draft.csv
├── Scripts/
│   ├── 00_setup.R            One-time package installation
│   ├── 01_clean.R            Raw data → analytic file (prints the cleaning log)
│   ├── 02_explore.R          Summary tables and charts
│   ├── 03_model.R            Train/test split, model comparison, final model
│   └── 04_diagnostics.R      Residual checks, VIF, sensitivity check (planned)
├── Outputs/                  Tables and figures created by the scripts
├── .lintr                    Code style settings (120-character lines)
└── README.md
```

The unzipped raw `.csv` (about 125 MB) is git-ignored because it exceeds GitHub's 100 MB file limit.
`read.csv()` reads the committed `.csv.gz` directly, so there is no need to unzip it.

## How to run

**Requirements:** R 4.2 or newer. The cleaning, exploration and modeling scripts use base R only. `00_setup.R`
installs the packages planned for the diagnostics step (for example `regclass` for VIF) and the project tooling.
The repository includes a dev container, so it opens ready to use in GitHub Codespaces.

**Run every script from the project root** (the folder that contains `Data/` and `Scripts/`), because all paths
are relative.

```bash
# 1. One time only: install packages (on a local machine R may ask you to pick a CRAN mirror)
Rscript Scripts/00_setup.R

# 2. The analysis, in order
Rscript Scripts/01_clean.R     # writes Data/clean/airbnb_analytic.csv
Rscript Scripts/02_explore.R   # writes summary tables and charts to Outputs/
Rscript Scripts/03_model.R     # writes model tables to Outputs/
```

To run steps 1–3 in one go and stop at the first error:

```bash
for f in Scripts/0[1-3]*.R; do Rscript "$f" || break; done
```

In VS Code you can also open a script and run it in an R terminal (select all, then Cmd/Ctrl + Enter).

| Script | Outputs |
| --- | --- |
| `01_clean.R` | `Data/clean/airbnb_analytic.csv`, `Data/clean/data_dictionary_draft.csv`, and a printed step-by-step cleaning log |
| `02_explore.R` | `Outputs/summary_numeric.csv`, `Outputs/summary_categorical.csv`, `Outputs/fig1`–`fig6` (PNG) |
| `03_model.R` | `Outputs/model_comparison.csv`, `Outputs/model_test_results.csv`, `Outputs/model_coefficients.csv` |

## Limitations

- **Asking prices, not paid prices.** Hosts can ask for any price, so the model describes pricing behavior.
- **One snapshot.** Seasonality, events and changes over time are not captured.
- **Price range.** Listings below $20 or above $1,000 were removed, so results apply to typical short-term rentals.
- **Long stays.** Many listings require 30+ nights, and their nightly prices are lower. A sensitivity check
  without them is planned.
- **Association, not causation.** For example, listings with a license price higher, but the data cannot show
  that a license raises price.
- **Coarse location.** Neighborhoods outside the top 15 are grouped together.
- **Model selection.** Variable selection and cross-validation both use the training data, which can make
  cross-validated error slightly optimistic. The separate test set guards against this.

## Roadmap

- [x] Reproducible cleaning pipeline (`01_clean.R`)
- [x] Exploratory analysis and charts (`02_explore.R`)
- [x] Model comparison and held-out test evaluation (`03_model.R`)
- [ ] Diagnostics: residual plots, influential points, multicollinearity (VIF), sensitivity check (`04_diagnostics.R`)
- [ ] Lock package versions with `renv`

## Reproducibility

- Relative paths only; run scripts from the project root.
- Random seed `2026` is set in `01_clean.R` and `03_model.R` (hot-deck imputation, train/test split and
  cross-validation folds). `02_explore.R` uses random jitter only for the look of the charts.
- The raw file is pinned (43,781 × 90). The MD5 checksum of the unzipped raw CSV is
  `a06a20394ca908bb9622c9a376bff329`.
- Airline traffic data was considered as an add-on, but a single listings snapshot has no month-to-month
  variation, so it is not part of the current analysis. Distance to LAX is used as the location feature instead.

## Credits

- **Contributors:** Jeremy Short, _[teammate 2]_, _[teammate 3]_
- **Data:** [Inside Airbnb](https://insideairbnb.com/), Los Angeles, scraped 2026-09-14. See their data policy for
  license and attribution terms.
- **AI assistance:** parts of the code and documentation were developed with Claude (Anthropic).
- _Add a license for the code here if desired (for example MIT)._
