# 04_diagnostics.R - Check the final model: residuals, multicollinearity (VIF), and a sensitivity check
# Input : Data/clean/airbnb_analytic.csv (made by 01_clean.R)
#         Outputs/model_test_results.csv (made by 03_model.R, tells us which model was chosen)
# Output: Outputs/fig7_residual_diagnostics.png, Outputs/vif_table.csv,
#         Outputs/sensitivity_coefficients.csv
# Run from the project root:  Rscript Scripts/04_diagnostics.R   (run 03_model.R first)

set.seed(2026)

## Part 1: Rebuild the training data and the final model exactly as in 03_model.R
df <- read.csv("Data/clean/airbnb_analytic.csv")
df$log_price <- log(df$price)
df$room_type <- relevel(factor(df$room_type), ref = "Entire home/apt")
df$neighborhood_grp <- relevel(factor(df$neighborhood_grp), ref = "Other")
common_type <- names(which.max(table(df$property_type_grp)))
df$property_type_grp <- relevel(factor(df$property_type_grp), ref = common_type)

predictors <- c("room_type", "property_type_grp", "neighborhood_grp", "accommodates",
                "bedrooms", "beds", "bathrooms", "shared_bath", "n_amenities",
                "minimum_nights", "has_license", "dist_lax_mi", "host_is_superhost",
                "host_identity_verified", "hosts_time_as_host_years",
                "calculated_host_listings_count")

# Same seed and same first random step as 03_model.R, so the split is identical
train_rows <- sample(nrow(df), size = round(0.8 * nrow(df)))
train <- df[train_rows, ]
test <- df[-train_rows, ]

full_fit <- lm(as.formula(paste("log_price ~", paste(predictors, collapse = " + "))), data = train)
reduced_fit <- step(full_fit, trace = 0)
final_name <- sub("Final: ", "", read.csv("Outputs/model_test_results.csv")$model[2])
final_fit <- switch(final_name, Full = full_fit, Reduced = reduced_fit,
                    Small = lm(log_price ~ accommodates + room_type + neighborhood_grp, data = train))
cat("Diagnosing the final model:", final_name, "\n")

## Part 2: Residual diagnostics (do the model assumptions hold?)
# Four panels: residuals vs fitted (should be a flat cloud around 0; a curve or funnel is a problem),
# normal Q-Q (points should follow the line), scale-location (red line should be flat), and
# Cook's distance (tall spikes are listings with unusual influence on the model).
png("Outputs/fig7_residual_diagnostics.png", width = 1400, height = 1200, res = 130)
par(mfrow = c(2, 2))
plot(final_fit, which = 1:4)
invisible(dev.off())
cat("Share of listings with |standardized residual| > 3:",
    round(mean(abs(rstandard(final_fit)) > 3) * 100, 2), "% (about 0.3% if residuals were normal)\n")

## Part 3: Multicollinearity (VIF)
# VIF shows how much a variable overlaps with the other numeric predictors (above 5 is a concern,
# above 10 is serious). VIF = 1 / (1 - R2) from regressing each variable on all the others.
vif_vars <- c("accommodates", "bedrooms", "beds", "bathrooms", "shared_bath", "n_amenities",
              "minimum_nights", "has_license", "dist_lax_mi", "host_is_superhost",
              "host_identity_verified", "hosts_time_as_host_years", "calculated_host_listings_count")
X <- train[, vif_vars]
X[] <- lapply(X, as.numeric)  # TRUE/FALSE becomes 1/0
vif <- numeric(length(vif_vars))
for (i in seq_along(vif_vars)) {
  vif[i] <- 1 / (1 - summary(lm(X[[vif_vars[i]]] ~ ., data = X[, -i]))$r.squared)
}
vif_table <- data.frame(variable = vif_vars, vif = round(vif, 2),
                        in_final_model = vif_vars %in% attr(terms(final_fit), "term.labels"))
vif_table <- vif_table[order(-vif_table$vif), ]
write.csv(vif_table, "Outputs/vif_table.csv", row.names = FALSE)
print(vif_table, row.names = FALSE)

## Part 4: Sensitivity check - do the results hold without long-stay listings?
# Many listings require 30+ nights and are priced about half as much per night. Refit the same model
# on short stays only (minimum nights below 30) and compare the percent effects.
short_fit <- lm(formula(final_fit), data = train[train$minimum_nights < 30, ])
a <- coef(final_fit)
b <- coef(short_fit)
terms_kept <- setdiff(names(a), "(Intercept)")
sens <- data.frame(term = terms_kept,
                   pct_effect_all = round((exp(a[terms_kept]) - 1) * 100, 1),
                   pct_effect_short = round((exp(b[terms_kept]) - 1) * 100, 1),
                   row.names = NULL)
write.csv(sens, "Outputs/sensitivity_coefficients.csv", row.names = FALSE)
print(sens)
# How to read it: if the main effects keep the same sign and a similar size, the conclusions do not
# depend on long-stay listings. A big change in a coefficient means long stays drive that result.

cat("Saved 1 chart and 2 tables to Outputs/\n")