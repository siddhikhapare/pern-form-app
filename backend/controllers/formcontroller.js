const pool = require('../db');

// GET all forms
const getAllForms = async (req, res) => {
  try {
    const { limit = 10, offset = 0 } = req.query;

    const query = `
      SELECT f.id, f.title, f.description, f.created_at, f.updated_at,
             COUNT(fr.id) AS response_count
      FROM forms f
      LEFT JOIN form_responses fr ON f.id = fr.form_id
      GROUP BY f.id
      ORDER BY f.created_at DESC
      LIMIT $1 OFFSET $2
    `;

    const result = await pool.query(query, [limit, offset]);

    res.json({ 
      success: true, 
      forms: result.rows, 
      count: result.rows.length 
    });
  } catch (err) {
    console.error('Error fetching forms:', err);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch forms', 
      message: err.message 
    });
  }
};

// GET single form by ID (with fields)
const getFormById = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get form details
    const formResult = await pool.query(
      `SELECT id, title, description, created_at, updated_at
       FROM forms
       WHERE id = $1`,
      [id]
    );
    
    if (formResult.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Form not found' 
      });
    }
    
    // Get form fields
    const fieldsResult = await pool.query(
      `SELECT id, label, type, options, required, field_order
       FROM form_fields
       WHERE form_id = $1
       ORDER BY field_order ASC`,
      [id]
    );
    
    // Parse options from string to array
    const fields = fieldsResult.rows.map(field => ({
      ...field,
      options: field.options ? field.options.split(',') : []
    }));
    
    const form = {
      ...formResult.rows[0],
      fields
    };
    
    res.json({
      success: true,
      form
    });
  } catch (error) {
    console.error('Error fetching form:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch form',
      message: error.message 
    });
  }
};

// POST create new form
const createForm = async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { title, description, fields = [] } = req.body;
    
    // Validation
    if (!title || !title.trim()) {
      return res.status(400).json({ 
        success: false, 
        error: 'Form title is required' 
      });
    }
    
    await client.query('BEGIN');
    
    // Insert form (without user_id)
    const formResult = await client.query(
      `INSERT INTO forms (title, description)
       VALUES ($1, $2)
       RETURNING id, title, description, created_at`,
      [title, description || '']
    );
    
    const formId = formResult.rows[0].id;
    
    // Insert form fields
    if (fields.length > 0) {
      for (let i = 0; i < fields.length; i++) {
        const field = fields[i];
        const optionsString = Array.isArray(field.options) 
          ? field.options.join(',') 
          : field.options || '';
        
        await client.query(
          `INSERT INTO form_fields (form_id, label, type, options, required, field_order)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [formId, field.label, field.type, optionsString, field.required || false, i]
        );
      }
    }
    
    await client.query('COMMIT');
    
    res.status(201).json({
      success: true,
      message: 'Form created successfully',
      formId,
      form: formResult.rows[0]
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating form:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to create form',
      message: error.message 
    });
  } finally {
    client.release();
  }
};

// PUT update form
const updateForm = async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { id } = req.params;
    const { title, description, fields = [] } = req.body;
    
    // Validation
    if (!title || !title.trim()) {
      return res.status(400).json({ 
        success: false, 
        error: 'Form title is required' 
      });
    }
    
    await client.query('BEGIN');
    
    // Update form
    const formResult = await client.query(
      `UPDATE forms 
       SET title = $1, description = $2, updated_at = CURRENT_TIMESTAMP
       WHERE id = $3
       RETURNING *`,
      [title, description || '', id]
    );
    
    if (formResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ 
        success: false, 
        error: 'Form not found' 
      });
    }
    
    // Delete existing fields
    await client.query('DELETE FROM form_fields WHERE form_id = $1', [id]);
    
    // Insert updated fields
    if (fields.length > 0) {
      for (let i = 0; i < fields.length; i++) {
        const field = fields[i];
        const optionsString = Array.isArray(field.options) 
          ? field.options.join(',') 
          : field.options || '';
        
        await client.query(
          `INSERT INTO form_fields (form_id, label, type, options, required, field_order)
           VALUES ($1, $2, $3, $4, $5, $6)`,
          [id, field.label, field.type, optionsString, field.required || false, i]
        );
      }
    }
    
    await client.query('COMMIT');
    
    res.json({
      success: true,
      message: 'Form updated successfully',
      form: formResult.rows[0]
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error updating form:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to update form',
      message: error.message 
    });
  } finally {
    client.release();
  }
};

// DELETE form
const deleteForm = async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      'DELETE FROM forms WHERE id = $1 RETURNING id',
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Form not found' 
      });
    }
    
    res.json({
      success: true,
      message: 'Form deleted successfully',
      deletedId: result.rows[0].id
    });
  } catch (error) {
    console.error('Error deleting form:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to delete form',
      message: error.message 
    });
  }
};

// ============================================
// FORM RESPONSE ROUTES
// ============================================

// POST submit form response
const submitFormResponse = async (req, res) => {
  const client = await pool.connect();
  
  try {
    const { id } = req.params;
    const { responses = {}, respondent_name, respondent_email } = req.body;
    
    // Verify form exists
    const formCheck = await client.query(
      'SELECT id FROM forms WHERE id = $1',
      [id]
    );
    
    if (formCheck.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Form not found' 
      });
    }
    
    await client.query('BEGIN');
    
    // Insert form response (without user_id)
    const responseResult = await client.query(
      `INSERT INTO form_responses (form_id, respondent_name, respondent_email)
       VALUES ($1, $2, $3)
       RETURNING id, form_id, respondent_name, respondent_email, submitted_at`,
      [id, respondent_name || 'Anonymous', respondent_email || null]
    );
    
    const responseId = responseResult.rows[0].id;
    
    // Insert response data
    for (const [fieldLabel, fieldValue] of Object.entries(responses)) {
      const valueString = typeof fieldValue === 'boolean' 
        ? fieldValue.toString() 
        : fieldValue;
      
      await client.query(
        `INSERT INTO response_data (response_id, field_label, field_value)
         VALUES ($1, $2, $3)`,
        [responseId, fieldLabel, valueString]
      );
    }
    
    await client.query('COMMIT');
    
    res.status(201).json({
      success: true,
      message: 'Response submitted successfully',
      responseId,
      response: responseResult.rows[0]
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error submitting response:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to submit response',
      message: error.message 
    });
  } finally {
    client.release();
  }
};

// GET all responses for a form
const getAllResponses = async (req, res) => {
  try {
    const { id } = req.params;
    
    // Get all responses with data
    const result = await pool.query(
      `SELECT 
         fr.id as response_id,
         fr.submitted_at,
         fr.respondent_name,
         fr.respondent_email,
         json_agg(
           json_build_object(
             'field_label', rd.field_label,
             'field_value', rd.field_value
           )
         ) as response_data
       FROM form_responses fr
       LEFT JOIN response_data rd ON fr.id = rd.response_id
       WHERE fr.form_id = $1
       GROUP BY fr.id, fr.respondent_name, fr.respondent_email
       ORDER BY fr.submitted_at DESC`,
      [id]
    );
    
    res.json({
      success: true,
      responses: result.rows,
      count: result.rows.length
    });
  } catch (error) {
    console.error('Error fetching responses:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch responses',
      message: error.message 
    });
  }
};

// GET single response details
const getSingleResponse = async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await pool.query(
      `SELECT 
         fr.id,
         fr.form_id,
         fr.submitted_at,
         fr.respondent_name,
         fr.respondent_email,
         f.title as form_title,
         json_agg(
           json_build_object(
             'field_label', rd.field_label,
             'field_value', rd.field_value
           )
         ) as response_data
       FROM form_responses fr
       LEFT JOIN forms f ON fr.form_id = f.id
       LEFT JOIN response_data rd ON fr.id = rd.response_id
       WHERE fr.id = $1
       GROUP BY fr.id, f.title, fr.respondent_name, fr.respondent_email`,
      [id]
    );
    
    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Response not found' 
      });
    }
    
    res.json({
      success: true,
      response: result.rows[0]
    });
  } catch (error) {
    console.error('Error fetching response:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch response',
      message: error.message 
    });
  }
};

module.exports = {
  getAllForms,
  getFormById,
  createForm,
  updateForm,
  deleteForm,
  submitFormResponse,
  getAllResponses,
  getSingleResponse
};