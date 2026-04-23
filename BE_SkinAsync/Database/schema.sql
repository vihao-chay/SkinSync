CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    phone VARCHAR(30),
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'banned')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    skin_type VARCHAR(30) NOT NULL,
    skin_concerns TEXT[] NOT NULL,
    monthly_budget VARCHAR(30) NOT NULL,
    age INT,
    birth_year INT
);

CREATE TABLE IF NOT EXISTS ai_analyses (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    overall_score INT NOT NULL CHECK (overall_score BETWEEN 0 AND 100),
    skin_age INT,
    recovery_capacity INT,
    uv_damage INT,
    aging_risk INT,
    issues_detected JSONB NOT NULL DEFAULT '{}'::jsonb,
    root_causes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_ai_analyses_user_created_at ON ai_analyses(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    brand VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    suitable_skin_types TEXT[] NOT NULL,
    image_url VARCHAR(500),
    rating NUMERIC(3,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'out_of_stock')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE INDEX IF NOT EXISTS idx_products_status_category ON products(status, category);

CREATE TABLE IF NOT EXISTS user_regimens (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    analysis_id UUID NOT NULL REFERENCES ai_analyses(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_user_regimens_user_active ON user_regimens(user_id, is_active);

CREATE TABLE IF NOT EXISTS regimen_items (
    id UUID PRIMARY KEY,
    regimen_id UUID NOT NULL REFERENCES user_regimens(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    routine_time VARCHAR(20) NOT NULL CHECK (routine_time IN ('Morning', 'Evening')),
    step_order INT NOT NULL CHECK (step_order > 0)
);

CREATE INDEX IF NOT EXISTS idx_regimen_items_regimen_time_step ON regimen_items(regimen_id, routine_time, step_order);

CREATE TABLE IF NOT EXISTS daily_logs (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    morning_completed BOOLEAN NOT NULL DEFAULT FALSE,
    evening_completed BOOLEAN NOT NULL DEFAULT FALSE,
    skin_feeling VARCHAR(30) NOT NULL,
    is_irritated BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    daily_image_url VARCHAR(500),
    CONSTRAINT uq_daily_logs_user_date UNIQUE (user_id, date)
);

CREATE INDEX IF NOT EXISTS idx_daily_logs_user_date ON daily_logs(user_id, date DESC);
