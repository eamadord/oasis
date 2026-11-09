-- Se ejecuta automáticamente solo la primera vez (volumen vacío)
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE TABLE IF NOT EXISTS tfg (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  creators_name JSONB,
  creators_id JSONB,
  contributors_name JSONB,
  contributors_id JSONB,
  subjects JSONB,
  ods JSONB,
  date TEXT,
  url TEXT,
  document_url TEXT,
  dc_publisher TEXT,
  dc_rights JSONB,
  private BOOLEAN DEFAULT FALSE,
  abstract_es TEXT,
  abstract_en TEXT,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tfg_title ON tfg USING gin (to_tsvector('spanish', title));
CREATE INDEX IF NOT EXISTS idx_tfg_subjects ON tfg USING gin (subjects);
CREATE INDEX IF NOT EXISTS idx_tfg_ods ON tfg USING gin (ods);
CREATE INDEX IF NOT EXISTS idx_tfg_created_at ON tfg (created_at);
