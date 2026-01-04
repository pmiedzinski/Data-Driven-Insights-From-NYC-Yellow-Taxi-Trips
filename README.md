# Data-Driven Insights from NYC Yellow Taxi Trips (2022)

This project analyses NYC Yellow Taxi trips from 2022 using Google BigQuery (SQL) to identify revenue-relevant patterns, demand concentration, and tipping behaviour. The work was completed as a take-home style analysis and presented as a short executive slide deck plus a supporting written report.

## What’s in this repository

- **Presentation:** `Data-Driven-Insights-from-NYC-Yellow-Taxi-Trips-2022 Pawel Miedzinski.pptx`
- **Report:** `NYC_Taxi_Report.pdf`
- **SQL (all questions):** `NYC_Taxi_Queries.sql`

## Business questions (summary)

Using the 2022 dataset, the analysis answers questions covering:

1. Top pickup and drop-off zones (demand concentration)
2. Zones with highest “fare per mile” (treated as anomaly detection, not pricing truth)
3. Staten Island pickups: revenue by destination borough and top revenue zones
4. Staten Island tips by quarter (UK quarter convention as instructed)
5. Zones with total tips > $100 in the highest-tipping quarter
6. Tip efficiency (tips per trip) with a minimum trip threshold
7. Monthly seasonality of Staten Island pickup volumes
8. Insight-based recommendations for revenue optimisation

## Data and tools

- **Trips dataset (BigQuery public):** `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2022`
- **Zone lookup (BigQuery public):** `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`
- **Tooling:** Google BigQuery (SQL) for querying and aggregation; PowerPoint and Gamma for presentation output.

## Important note on December 2022

December 2022 in the task dataset contains only **57 rows**, so it is treated as incomplete. For time-series comparisons (monthly/quarterly), December is excluded to avoid misleading seasonality conclusions.

If a complete time series is required, the report outlines three best-practice approaches to impute December (for example a 10-year seasonal ratio method, a recent-year December profile with trend adjustment, or a time-series/regression forecast). A detailed step-by-step guide is included in `NYC_Taxi_December_Imputation_Guide.pdf`.

## How to run the SQL

Note: The SQL is written for **BigQuery**. Small changes would be needed to run it in PostgreSQL/MySQL.

## Outputs

Key outputs and conclusions are summarised in the slide deck and supported in the report:
- Demand is highly concentrated around major hubs (e.g., airports and central Manhattan zones)
- “Fare per mile” is heavily distorted in airport/boundary contexts and is best used as an anomaly flag
- Staten Island highest-value corridor (by revenue) is towards Manhattan
- Stronger tipping and demand appear during summer months in the available data


