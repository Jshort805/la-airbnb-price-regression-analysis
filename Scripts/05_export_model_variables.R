# 05_export_model_variables.R - Save only the variables used in the analysis
# Input : Data/clean/airbnb_analytic.csv  (made by 01_clean.R)
# Output: Data/clean/airbnb_model_variables.csv
# Run from the project root:  Rscript Scripts/05_export_model_variables.R

df <- read.csv("Data/clean/airbnb_analytic.csv")
df$log_price <- log(df$price)

model_vars <- c("id", "price", "log_price",
                "room_type", "property_type_grp", "neighborhood_grp", "accommodates",
                "bedrooms", "beds", "bathrooms", "shared_bath", "n_amenities",
                "minimum_nights", "has_license", "dist_lax_mi", "host_is_superhost",
                "host_identity_verified", "hosts_time_as_host_years",
                "calculated_host_listings_count")

model_data <- df[, model_vars]
write.csv(model_data, "Data/clean/airbnb_model_variables.csv", row.names = FALSE)
cat("Saved", nrow(model_data), "rows x", ncol(model_data), "columns\n")