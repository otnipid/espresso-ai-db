-- ========================================
-- PREDICTION FEATURES TABLE
-- ========================================
-- Purpose: Store engineered features for ML model training and prediction, ensuring consistency between training and inference
-- Dependencies: shots table
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS prediction_features (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    shot_id UUID NOT NULL REFERENCES shots(id) ON DELETE CASCADE,
    feature_name TEXT NOT NULL,
    feature_value NUMERIC,
    feature_type TEXT NOT NULL CHECK (feature_type IN ('numeric', 'categorical', 'boolean')),
    feature_version TEXT DEFAULT '1.0',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints for data quality
    CONSTRAINT unique_shot_feature UNIQUE (shot_id, feature_name, feature_version),
    CONSTRAINT valid_feature_value CHECK (
        (feature_type = 'boolean' AND feature_value IN (0, 1)) OR
        (feature_type = 'categorical') OR
        (feature_type = 'numeric' AND feature_value IS NOT NULL)
    )
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_prediction_features_shot_id ON prediction_features(shot_id);
CREATE INDEX IF NOT EXISTS idx_prediction_features_feature_name ON prediction_features(feature_name);
CREATE INDEX IF NOT EXISTS idx_prediction_features_version ON prediction_features(feature_version);

-- Trigger for updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_prediction_features_updated_at 
    BEFORE UPDATE ON prediction_features 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- View for commonly accessed prediction features
CREATE OR REPLACE VIEW shot_prediction_features AS
SELECT 
    s.id as shot_id,
    s.dose_grams,
    s.grind_setting,
    s.water_temp_c,
    s.extraction_time_seconds,
    s.yield_grams,
    s.pressure_bars,
    -- Aggregate numeric features
    ARRAY_AGG(CASE WHEN pf.feature_type = 'numeric' THEN 
        json_build_object(pf.feature_name, pf.feature_value) 
        END FILTER (WHERE pf.feature_type = 'numeric') 
    ) as numeric_features,
    -- Aggregate categorical features
    ARRAY_AGG(CASE WHEN pf.feature_type = 'categorical' THEN 
        json_build_object(pf.feature_name, pf.feature_value) 
        END FILTER (WHERE pf.feature_type = 'categorical') 
    ) as categorical_features,
    -- Aggregate boolean features
    ARRAY_AGG(CASE WHEN pf.feature_type = 'boolean' THEN 
        json_build_object(pf.feature_name, pf.feature_value) 
        END FILTER (WHERE pf.feature_type = 'boolean') 
    ) as boolean_features
FROM shots s
LEFT JOIN prediction_features pf ON s.id = pf.shot_id
GROUP BY s.id;

-- Comments for documentation
COMMENT ON TABLE prediction_features IS 'Stores engineered features for ML model training and prediction, ensuring consistency between training and inference';
COMMENT ON VIEW shot_prediction_features IS 'Convenient view for accessing shot data with associated prediction features';
