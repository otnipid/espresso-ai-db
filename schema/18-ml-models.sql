-- ========================================
-- ML MODELS TABLE
-- ========================================
-- Purpose: Store trained machine learning models with versioning and performance metrics
-- Dependencies: None (standalone table)
-- Idempotent: Yes (uses IF NOT EXISTS)

CREATE TABLE IF NOT EXISTS ml_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name TEXT NOT NULL,
    version TEXT NOT NULL,
    model_type TEXT NOT NULL CHECK (model_type IN ('parameter_prediction', 'success_prediction', 'classification', 'regression')),
    model_data BYTEA NOT NULL,
    feature_schema JSONB NOT NULL,
    hyperparameters JSONB,
    performance_metrics JSONB,
    training_data_count INTEGER NOT NULL,
    training_data_from TIMESTAMP,
    training_data_to TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT FALSE,
    
    -- Constraints
    CONSTRAINT unique_model_version UNIQUE (model_name, version),
    CONSTRAINT valid_performance_metrics CHECK (
        jsonb_typeof(performance_metrics) = 'object'
    )
);

-- Training History Table
-- Tracks training runs and their outcomes

CREATE TABLE IF NOT EXISTS training_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES ml_models(id),
    training_status TEXT NOT NULL CHECK (training_status IN ('started', 'completed', 'failed', 'cancelled')),
    started_at TIMESTAMP DEFAULT NOW(),
    completed_at TIMESTAMP,
    training_duration_seconds INTEGER,
    performance_metrics JSONB,
    error_message TEXT,
    data_points_count INTEGER,
    training_config JSONB,
    
    -- Constraints
    CONSTRAINT valid_training_duration CHECK (
        training_duration_seconds IS NULL OR training_duration_seconds > 0
    )
);

-- Model Predictions Table
-- Logs individual predictions for accuracy tracking

CREATE TABLE IF NOT EXISTS model_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES ml_models(id),
    shot_id UUID NOT NULL REFERENCES shots(id),
    prediction_type TEXT NOT NULL,
    prediction_data JSONB NOT NULL,
    confidence_score NUMERIC CHECK (confidence_score BETWEEN 0 AND 1),
    actual_result JSONB,
    accuracy_score NUMERIC CHECK (accuracy_score BETWEEN 0 AND 1),
    created_at TIMESTAMP DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_confidence CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 1),
    CONSTRAINT valid_accuracy CHECK (accuracy_score IS NULL OR accuracy_score BETWEEN 0 AND 1)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_ml_models_name_type ON ml_models(model_name, model_type);
CREATE INDEX IF NOT EXISTS idx_ml_models_active ON ml_models(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_training_history_model_id ON training_history(model_id);
CREATE INDEX IF NOT EXISTS idx_training_history_status ON training_history(training_status);
CREATE INDEX IF NOT EXISTS idx_model_predictions_shot_id ON model_predictions(shot_id);
CREATE INDEX IF NOT EXISTS idx_model_predictions_model_id ON model_predictions(model_id);

-- View for active models
CREATE OR REPLACE VIEW active_ml_models AS
SELECT 
    id,
    model_name,
    version,
    model_type,
    performance_metrics,
    training_data_count,
    created_at,
    jsonb_extract_path_text(performance_metrics, 'accuracy')::numeric as accuracy
FROM ml_models 
WHERE is_active = true;

-- Function to get the active model for a given type
CREATE OR REPLACE FUNCTION get_active_model(p_model_type TEXT)
RETURNS TABLE (
    model_id UUID,
    model_name TEXT,
    version TEXT,
    model_data BYTEA,
    feature_schema JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.model_name,
        m.version,
        m.model_data,
        m.feature_schema
    FROM ml_models m
    WHERE m.model_type = p_model_type 
    AND m.is_active = true
    ORDER BY m.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to activate a model and deactivate others of same type
CREATE OR REPLACE FUNCTION activate_model(p_model_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_model_type TEXT;
BEGIN
    -- Get the model type
    SELECT model_type INTO v_model_type
    FROM ml_models 
    WHERE id = p_model_id;
    
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- Deactivate all models of this type
    UPDATE ml_models 
    SET is_active = false 
    WHERE model_type = v_model_type;
    
    -- Activate the specified model
    UPDATE ml_models 
    SET is_active = true 
    WHERE id = p_model_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Comments for documentation
COMMENT ON TABLE ml_models IS 'Stores trained machine learning models with versioning and performance metrics';
COMMENT ON TABLE training_history IS 'Tracks training runs and their outcomes for monitoring and debugging';
COMMENT ON TABLE model_predictions IS 'Logs individual predictions for accuracy tracking and model evaluation';
COMMENT ON VIEW active_ml_models IS 'Convenient view for accessing currently active ML models';
COMMENT ON FUNCTION get_active_model IS 'Returns the active model for a given model type';
COMMENT ON FUNCTION activate_model IS 'Activates a model and deactivates others of the same type';
