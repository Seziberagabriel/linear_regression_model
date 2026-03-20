# Predicting Global Undernourishment Prevalence

## Mission
To combat malnutrition and undernutrition, I advocate for equitable access to nutritious food
and promote sustainable solutions in my home community. Through education, innovation, and
collaboration with communities, I aim to address root causes of food insecurity and empower
individuals to lead healthier lives.

## Problem
Using historical undernourishment data across 208 countries (2000–2024), this project builds
a regression model to predict undernourishment prevalence — helping identify and prioritize
communities where food insecurity is rising or persistent.


## Dataset Description
- **Source:** Our World in Data / Food and Agriculture Organization (FAO) of the United Nations
  → https://ourworldindata.org/hunger-and-undernourishment
- **File:** `prevalence-of-undernourishment.csv`
- **Rows:** ~5,000+ country-year observations
- **Columns:**
  - `Entity` — Country or region name
  - `Code` — ISO country code
  - `Year` — Observation year (2000–2024)
  - `undernourishment` — % of population that is undernourished (target variable)

## Why This Dataset?
Undernourishment is a critical global health indicator tracked by the UN.
This dataset spans 20+ years across 180+ countries, making it rich in both
volume and geographic variety — ideal for regression analysis.
