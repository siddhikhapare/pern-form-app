-- ============================================
-- FORM BUILDER DATABASE INITIALIZATION
-- ============================================
-- This script creates all necessary tables for the form builder application
-- Run this script after creating your database

-- Drop existing tables if they exist (for fresh start)
DROP TABLE IF EXISTS response_data CASCADE;
DROP TABLE IF EXISTS form_responses CASCADE;
DROP TABLE IF EXISTS form_fields CASCADE;
DROP TABLE IF EXISTS forms CASCADE;

-- ============================================
-- 1. FORMS TABLE
-- Stores the main form information
-- ============================================
CREATE TABLE forms (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add comment to table
COMMENT ON TABLE forms IS 'Main table storing form information';
COMMENT ON COLUMN forms.id IS 'Unique identifier for each form';
COMMENT ON COLUMN forms.title IS 'Title of the form';
COMMENT ON COLUMN forms.description IS 'Optional description of the form';

-- ============================================
-- 2. FORM FIELDS TABLE
-- Stores individual fields for each form
-- ============================================
CREATE TABLE form_fields (
  id SERIAL PRIMARY KEY,
  form_id INTEGER NOT NULL,
  label VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL,
  options TEXT,
  required BOOLEAN DEFAULT false,
  field_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign key constraint
  CONSTRAINT fk_form_fields_form
    FOREIGN KEY (form_id) 
    REFERENCES forms(id) 
    ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE form_fields IS 'Stores fields/questions for each form';
COMMENT ON COLUMN form_fields.type IS 'Field type: text, textarea, email, number, date, select, radio, checkbox';
COMMENT ON COLUMN form_fields.options IS 'Comma-separated values for select/radio/checkbox fields';
COMMENT ON COLUMN form_fields.field_order IS 'Order in which fields should be displayed';

-- ============================================
-- 3. FORM RESPONSES TABLE
-- Stores submission metadata
-- ============================================
CREATE TABLE form_responses (
  id SERIAL PRIMARY KEY,
  form_id INTEGER NOT NULL,
  respondent_name VARCHAR(255) DEFAULT 'Anonymous',
  respondent_email VARCHAR(255),
  submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign key constraint
  CONSTRAINT fk_form_responses_form
    FOREIGN KEY (form_id) 
    REFERENCES forms(id) 
    ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE form_responses IS 'Stores metadata about form submissions';
COMMENT ON COLUMN form_responses.respondent_name IS 'Name of person who submitted the form (optional)';
COMMENT ON COLUMN form_responses.respondent_email IS 'Email of person who submitted the form (optional)';

-- ============================================
-- 4. RESPONSE DATA TABLE
-- Stores actual field values for each response
-- ============================================
CREATE TABLE response_data (
  id SERIAL PRIMARY KEY,
  response_id INTEGER NOT NULL,
  field_label VARCHAR(255) NOT NULL,
  field_value TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  
  -- Foreign key constraint
  CONSTRAINT fk_response_data_response
    FOREIGN KEY (response_id) 
    REFERENCES form_responses(id) 
    ON DELETE CASCADE
);

-- Add comments
COMMENT ON TABLE response_data IS 'Stores actual field values for each form submission';
COMMENT ON COLUMN response_data.field_label IS 'Label of the field being answered';
COMMENT ON COLUMN response_data.field_value IS 'Value/answer provided by respondent';

-- ============================================
-- CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Index for faster form field lookups
CREATE INDEX idx_form_fields_form_id 
  ON form_fields(form_id);

-- Index for faster response lookups by form
CREATE INDEX idx_form_responses_form_id 
  ON form_responses(form_id);

-- Index for faster response data lookups
CREATE INDEX idx_response_data_response_id 
  ON response_data(response_id);

-- Index for sorting forms by creation date
CREATE INDEX idx_forms_created_at 
  ON forms(created_at DESC);

-- Index for faster field ordering
CREATE INDEX idx_form_fields_order 
  ON form_fields(form_id, field_order);

-- Index for email lookups (if needed for analytics)
CREATE INDEX idx_form_responses_email 
  ON form_responses(respondent_email) 
  WHERE respondent_email IS NOT NULL;

-- ============================================
-- INSERT SAMPLE DATA (Optional - for testing)
-- ============================================

-- Sample Form 1: Contact Form
INSERT INTO forms (title, description) 
VALUES ('Contact Form', 'Get in touch with us for any inquiries or support');

-- Sample Form 2: Feedback Survey
INSERT INTO forms (title, description) 
VALUES ('Customer Feedback Survey', 'Help us improve by sharing your experience');

-- Sample Form 3: Event Registration
INSERT INTO forms (title, description) 
VALUES ('Event Registration', 'Register for our upcoming tech conference');

-- Fields for Contact Form (form_id = 1)
INSERT INTO form_fields (form_id, label, type, options, required, field_order) VALUES
  (1, 'Full Name', 'text', NULL, true, 0),
  (1, 'Email Address', 'email', NULL, true, 1),
  (1, 'Phone Number', 'text', NULL, false, 2),
  (1, 'Subject', 'select', 'General Inquiry,Technical Support,Sales,Other', true, 3),
  (1, 'Message', 'textarea', NULL, true, 4);

-- Fields for Feedback Survey (form_id = 2)
INSERT INTO form_fields (form_id, label, type, options, required, field_order) VALUES
  (2, 'Overall Satisfaction', 'radio', 'Very Satisfied,Satisfied,Neutral,Dissatisfied,Very Dissatisfied', true, 0),
  (2, 'How did you hear about us?', 'select', 'Social Media,Search Engine,Friend,Advertisement,Other', true, 1),
  (2, 'Would you recommend us?', 'radio', 'Yes,No,Maybe', true, 2),
  (2, 'Additional Comments', 'textarea', NULL, false, 3),
  (2, 'Can we contact you for follow-up?', 'checkbox', NULL, false, 4);

-- Fields for Event Registration (form_id = 3)
INSERT INTO form_fields (form_id, label, type, options, required, field_order) VALUES
  (3, 'Full Name', 'text', NULL, true, 0),
  (3, 'Email', 'email', NULL, true, 1),
  (3, 'Company', 'text', NULL, false, 2),
  (3, 'Job Title', 'text', NULL, false, 3),
  (3, 'Dietary Restrictions', 'select', 'None,Vegetarian,Vegan,Gluten-Free,Other', false, 4),
  (3, 'T-Shirt Size', 'radio', 'S,M,L,XL,XXL', false, 5);

-- Sample Responses for Contact Form
INSERT INTO form_responses (form_id, respondent_name, respondent_email) 
VALUES 
  (1, 'John Doe', 'john.doe@example.com'),
  (1, 'Jane Smith', 'jane.smith@example.com');

-- Sample Response Data for first response
INSERT INTO response_data (response_id, field_label, field_value) VALUES
  (1, 'Full Name', 'John Doe'),
  (1, 'Email Address', 'john.doe@example.com'),
  (1, 'Phone Number', '+91-545450123'),
  (1, 'Subject', 'Technical Support'),
  (1, 'Message', 'I am having trouble logging into my account. Can you help?');

-- Sample Response Data for second response
INSERT INTO response_data (response_id, field_label, field_value) VALUES
  (2, 'Full Name', 'Jane Smith'),
  (2, 'Email Address', 'jane.smith@example.com'),
  (2, 'Phone Number', '+91-899950456'),
  (2, 'Subject', 'General Inquiry'),
  (2, 'Message', 'What are your business hours?');

-- ============================================
-- CREATE USEFUL VIEWS (Optional)
-- ============================================

-- View to get form statistics
CREATE OR REPLACE VIEW form_statistics AS
SELECT 
  f.id,
  f.title,
  f.description,
  f.created_at,
  COUNT(DISTINCT ff.id) as field_count,
  COUNT(DISTINCT fr.id) as response_count,
  MAX(fr.submitted_at) as last_response_at
FROM forms f
LEFT JOIN form_fields ff ON f.id = ff.form_id
LEFT JOIN form_responses fr ON f.id = fr.form_id
GROUP BY f.id, f.title, f.description, f.created_at;

COMMENT ON VIEW form_statistics IS 'Provides quick statistics for each form';

-- ============================================
-- CREATE FUNCTIONS (Optional)
-- ============================================

-- Function to update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at on forms table
CREATE TRIGGER update_forms_updated_at
    BEFORE UPDATE ON forms
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VERIFY INSTALLATION
-- ============================================

-- Check if all tables were created
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
  AND table_name IN ('forms', 'form_fields', 'form_responses', 'response_data')
ORDER BY table_name;

-- Display sample data counts
SELECT 
  'forms' as table_name, COUNT(*) as row_count FROM forms
UNION ALL
SELECT 'form_fields', COUNT(*) FROM form_fields
UNION ALL
SELECT 'form_responses', COUNT(*) FROM form_responses
UNION ALL
SELECT 'response_data', COUNT(*) FROM response_data;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================
SELECT 
  '✓ Database initialized successfully!' as status,
  'All tables, indexes, and sample data have been created.' as message;