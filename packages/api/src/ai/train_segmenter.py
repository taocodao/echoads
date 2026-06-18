#!/usr/bin/env python3
"""
train_segmenter.py — Module 2: XGBoost Audience Segmenter Training
Trains a viewer tier classifier (T1–T12) from the viewer_profiles table.
Output: viewer_classifier.json (XGBoost model) + metadata.json

Usage:
  pip install xgboost scikit-learn psycopg2-binary pandas numpy
  python train_segmenter.py --db postgresql://user:pass@host/echoads --output ./models

Environment:
  DATABASE_URL  — PostgreSQL connection string (override with --db)

The trained model JSON is used by segmenter.route.ts for on-the-fly inference.
For iOS: convert to Core ML using coremltools after training:
  coremltools.converters.xgboost.convert(booster, feature_names=FEATURES)
"""

import argparse
import json
import os
import sys
from datetime import datetime

import numpy as np
import pandas as pd

try:
    import xgboost as xgb
    from sklearn.model_selection import train_test_split, cross_val_score
    from sklearn.preprocessing import LabelEncoder
    from sklearn.metrics import classification_report, accuracy_score
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError as e:
    print(f"❌ Missing dependency: {e}")
    print("Run: pip install xgboost scikit-learn psycopg2-binary pandas numpy")
    sys.exit(1)


# ── Feature definitions (must match useProfileEngine.ts feature vector) ───────

FEATURES = [
    "engagement_depth",      # 0–100 composite score
    "ad_completion_rate",    # 0–1
    "prediction_rate",       # 0–1
    "session_frequency",     # sessions/week
    "total_watch_hours",     # cumulative
    "sport_football",        # affinity: Football (0–1)
    "sport_live",            # affinity: Live Sports (0–1)
    "sport_commerce",        # affinity: Sports Commerce (0–1)
]

TIER_LABELS = ["T1","T2","T3","T4","T5","T6","T7","T8","T9","T10","T11","T12"]


# ── Data loading ───────────────────────────────────────────────────────────────

def load_from_db(db_url: str) -> pd.DataFrame:
    print(f"[DB] Connecting to database…")
    conn = psycopg2.connect(db_url)
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("""
        SELECT
            viewer_token, segment_id, engagement_depth,
            ad_completion_rate, prediction_rate, session_frequency,
            total_watch_hours, sport_affinities
        FROM viewer_profiles
        WHERE segment_id IS NOT NULL
    """)
    rows = cur.fetchall()
    conn.close()
    print(f"[DB] Loaded {len(rows):,} profiles")
    return pd.DataFrame(rows)


def generate_synthetic_data(n_samples: int = 5000) -> pd.DataFrame:
    """
    Generate synthetic training data using the same rule-based logic as
    useProfileEngine.ts. Used when real data is insufficient.
    """
    print(f"[Synthetic] Generating {n_samples:,} synthetic profiles…")
    rng = np.random.default_rng(42)
    rows = []
    for _ in range(n_samples):
        # Sample engagement distribution (skewed toward lower tiers)
        eng = rng.beta(1.5, 4) * 100

        if eng >= 85:   tier = "T1"
        elif eng >= 70: tier = "T2"
        elif eng >= 55: tier = "T3"
        elif eng >= 40: tier = "T4"
        elif eng >= 32: tier = "T5"
        elif eng >= 25: tier = "T6"
        elif eng >= 20: tier = "T7"
        elif eng >= 15: tier = "T8"
        elif eng >= 10: tier = "T9"
        elif eng >= 7:  tier = "T10"
        elif eng >= 4:  tier = "T11"
        else:           tier = "T12"

        # Correlate features with engagement (realistic noise)
        noise = lambda scale: rng.normal(0, scale)
        rows.append({
            "segment_id":        tier,
            "engagement_depth":  np.clip(eng, 0, 100),
            "ad_completion_rate": np.clip(eng/100 * 0.9 + noise(0.08), 0, 1),
            "prediction_rate":   np.clip(eng/100 * 0.7 + noise(0.1),  0, 1),
            "session_frequency": np.clip(eng/10 + noise(0.5), 0, 10),
            "total_watch_hours": np.clip(eng/3 + noise(5),    0, 100),
            "sport_football":    np.clip(0.5 + eng/200 + noise(0.1), 0, 1),
            "sport_live":        np.clip(0.4 + eng/200 + noise(0.1), 0, 1),
            "sport_commerce":    np.clip(0.2 + eng/300 + noise(0.08), 0, 1),
        })
    return pd.DataFrame(rows)


def prepare_features(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.Series]:
    """Extract and engineer features from raw profiles."""
    # Expand sport_affinities JSONB if present as dict/string
    if "sport_affinities" in df.columns:
        if df["sport_affinities"].dtype == object:
            affinities = df["sport_affinities"].apply(
                lambda x: json.loads(x) if isinstance(x, str) else (x or {})
            )
            df["sport_football"] = affinities.apply(lambda a: a.get("Football", 0.5))
            df["sport_live"]     = affinities.apply(lambda a: a.get("Live Sports", 0.4))
            df["sport_commerce"] = affinities.apply(lambda a: a.get("Sports Commerce", 0.2))

    # Fill missing columns with defaults
    for col, default in [
        ("sport_football", 0.5), ("sport_live", 0.4), ("sport_commerce", 0.2)
    ]:
        if col not in df.columns:
            df[col] = default

    X = df[FEATURES].fillna(0).clip(0, None)
    y = df["segment_id"]
    return X, y


# ── Training ──────────────────────────────────────────────────────────────────

def train(X: pd.DataFrame, y: pd.Series, output_dir: str) -> dict:
    print(f"\n[Train] Features: {list(X.columns)}")
    print(f"[Train] Samples:  {len(X):,}")
    print(f"[Train] Classes:  {sorted(y.unique())}")

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y_enc, test_size=0.2, random_state=42, stratify=y_enc
    )

    model = xgb.XGBClassifier(
        n_estimators=200,
        max_depth=6,
        learning_rate=0.1,
        subsample=0.8,
        colsample_bytree=0.8,
        objective="multi:softprob",
        num_class=len(le.classes_),
        use_label_encoder=False,
        eval_metric="mlogloss",
        random_state=42,
        n_jobs=-1,
    )

    model.fit(
        X_train, y_train,
        eval_set=[(X_test, y_test)],
        verbose=False,
    )

    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"\n[Train] ✅ Accuracy: {accuracy:.3f}")
    print(classification_report(y_test, y_pred, target_names=le.classes_))

    # Feature importance
    importance = dict(zip(FEATURES, model.feature_importances_.tolist()))
    print("\n[Train] Feature importance:")
    for feat, imp in sorted(importance.items(), key=lambda x: -x[1]):
        bar = "█" * int(imp * 40)
        print(f"  {feat:<25} {bar} {imp:.4f}")

    # Save model
    os.makedirs(output_dir, exist_ok=True)
    model_path = os.path.join(output_dir, "viewer_classifier.json")
    model.save_model(model_path)
    print(f"\n[Train] Model saved → {model_path}")

    # Save metadata
    metadata = {
        "modelVersion": "xgboost-v1",
        "trainedAt": datetime.utcnow().isoformat() + "Z",
        "features": FEATURES,
        "classes": le.classes_.tolist(),
        "accuracy": round(accuracy, 4),
        "nSamples": len(X),
        "nEstimators": 200,
        "featureImportance": importance,
        "notes": "Replace rule-based classifier in segmenter.route.ts when accuracy >= 0.85",
        "coreMLConversion": (
            "import coremltools as ct\n"
            "model = ct.converters.xgboost.convert(booster, feature_names=FEATURES)\n"
            "model.save('ViewerClassifier.mlpackage')"
        ),
    }
    meta_path = os.path.join(output_dir, "metadata.json")
    with open(meta_path, "w") as f:
        json.dump(metadata, f, indent=2)
    print(f"[Train] Metadata → {meta_path}")

    return metadata


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Train ArenzaTV XGBoost Audience Segmenter")
    parser.add_argument("--db",       default=os.environ.get("DATABASE_URL", ""), help="PostgreSQL URL")
    parser.add_argument("--output",   default="./models",  help="Output directory for model files")
    parser.add_argument("--synthetic",action="store_true", help="Use synthetic data (no DB required)")
    parser.add_argument("--samples",  type=int, default=5000, help="Synthetic sample count")
    args = parser.parse_args()

    if args.synthetic or not args.db:
        df = generate_synthetic_data(args.samples)
        X, y = prepare_features(df)
    else:
        df = load_from_db(args.db)
        if len(df) < 100:
            print(f"⚠️  Only {len(df)} real profiles — augmenting with synthetic data")
            synthetic = generate_synthetic_data(max(1000, 5000 - len(df)))
            X_syn, y_syn = prepare_features(synthetic)
            X_real, y_real = prepare_features(df)
            X = pd.concat([X_real, X_syn], ignore_index=True)
            y = pd.concat([y_real, y_syn], ignore_index=True)
        else:
            X, y = prepare_features(df)

    metadata = train(X, y, args.output)
    print(f"\n✅ Training complete. Accuracy: {metadata['accuracy']:.1%}")
    if metadata["accuracy"] >= 0.85:
        print("🎉 Model meets 85% accuracy threshold — ready for production deployment!")
        print("   Next: convert to Core ML for iOS using coremltools")
    else:
        print("⚠️  Accuracy below 85% threshold. Collect more real data before deploying.")


if __name__ == "__main__":
    main()
