import io
import os
import joblib
import numpy as np
import pandas as pd

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.linear_model import SGDRegressor
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_squared_error

app = FastAPI(
    title="Undernourishment Prevalence Predictor",
    description="Predicts undernourishment % given a country code and year.",
    version="1.0.0",
)

# ── CORS: specific origins, NOT wildcard * ─────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "https://undernourishment-api.onrender.com", 
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

MODEL_PATH  = "best_model.pkl"
SCALER_PATH = "scaler.pkl"

def load_artefacts():
    if not os.path.exists(MODEL_PATH) or not os.path.exists(SCALER_PATH):
        raise RuntimeError("Model or scaler not found. Copy .pkl files into this folder.")
    return joblib.load(MODEL_PATH), joblib.load(SCALER_PATH)

model, scaler = load_artefacts()

# ── Input schema with enforced types and ranges ────────────────────────────────
class PredictionInput(BaseModel):
    entity_code: int = Field(..., ge=0, le=300,
        description="Label-encoded country integer (0–300)", example=12)
    year: int = Field(..., ge=2000, le=2030,
        description="Year between 2000 and 2030", example=2015)

class PredictionOutput(BaseModel):
    entity_code: int
    year: int
    predicted_undernourishment_pct: float

class RetrainOutput(BaseModel):
    message: str
    best_model: str
    best_mse: float

@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "docs": "/docs"}

@app.post("/predict", response_model=PredictionOutput, tags=["Prediction"])
def predict(data: PredictionInput):
    features = np.array([[data.entity_code, data.year]], dtype=float)
    scaled   = scaler.transform(features)
    pred     = float(np.clip(model.predict(scaled)[0], 0.0, 80.0))
    return PredictionOutput(
        entity_code=data.entity_code,
        year=data.year,
        predicted_undernourishment_pct=round(pred, 2),
    )

@app.post("/retrain", response_model=RetrainOutput, tags=["Retraining"])
async def retrain(file: UploadFile = File(...)):
    global model, scaler
    contents = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(400, f"Cannot parse CSV: {e}")

    col = next((c for c in df.columns if "undernourishment" in c.lower()
                or "prevalence" in c.lower()), None)
    if not col:
        raise HTTPException(422, "No undernourishment column found.")
    df = df.rename(columns={col: "undernourishment"})
    df = df.drop(columns=[c for c in ["Code","Decade"] if c in df.columns]).dropna()
    df["Entity"] = df["Entity"].astype("category").cat.codes

    if len(df) < 50:
        raise HTTPException(422, f"Too few rows after cleaning: {len(df)}")

    X = df[["Entity","Year"]]
    y = df["undernourishment"]
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    new_scaler = StandardScaler()
    Xtr = new_scaler.fit_transform(X_train)
    Xte = new_scaler.transform(X_test)

    candidates = {
        "Linear Regression": SGDRegressor(max_iter=200, eta0=0.01, random_state=42),
        "Decision Tree":     DecisionTreeRegressor(max_depth=6, random_state=42),
        "Random Forest":     RandomForestRegressor(n_estimators=100, max_depth=10, random_state=42),
    }
    results = {n: (mean_squared_error(y_test, m.fit(Xtr,y_train).predict(Xte)), m)
               for n, m in candidates.items()}
    best_name, (best_mse, best_m) = min(results.items(), key=lambda x: x[1][0])
    joblib.dump(best_m,     MODEL_PATH)
    joblib.dump(new_scaler, SCALER_PATH)
    model, scaler = best_m, new_scaler
    return RetrainOutput(message=f"Retrained on {len(df)} rows.",
                         best_model=best_name, best_mse=round(best_mse,4))