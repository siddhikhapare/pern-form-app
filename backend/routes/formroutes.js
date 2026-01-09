const express = require('express');
const router = express.Router();
const formController = require('../controllers/formcontroller.js');
const winston = require('winston');

// Configure Winston Logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
  ),
  defaultMeta: { service: 'form-service' },
  transports: [
    // Write all logs with level 'error' and below to error.log
    new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
    // Write all logs with level 'info' and below to combined.log
    new winston.transports.File({ filename: 'logs/combined.log' }),
  ],
});

// If not in production, log to console as well
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

// Logging middleware
const logRequest = (req, res, next) => {
  logger.info({
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('user-agent')
  });
  next();
};

// Apply logging middleware to all routes
router.use(logRequest);

// ============================================
// FORM CRUD ROUTES
// ============================================

// GET all forms
router.get('/', async (req, res, next) => {
  try {
    logger.info('Fetching all forms', { 
      query: req.query 
    });
    await formController.getAllForms(req, res);
    logger.info('Successfully fetched forms');
  } catch (err) {
    logger.error('Error fetching all forms', { 
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// GET single form by ID
router.get('/:id', async (req, res, next) => {
  try {
    logger.info('Fetching form by ID', { 
      formId: req.params.id 
    });
    await formController.getFormById(req, res);
    logger.info('Successfully fetched form', { 
      formId: req.params.id 
    });
  } catch (err) {
    logger.error('Error fetching form by ID', { 
      formId: req.params.id,
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// POST create new form
router.post('/', async (req, res, next) => {
  try {
    logger.info('Creating new form', { 
      title: req.body.title 
    });
    await formController.createForm(req, res);
    logger.info('Successfully created form', { 
      title: req.body.title 
    });
  } catch (err) {
    logger.error('Error creating form', { 
      error: err.message, 
      stack: err.stack,
      body: req.body 
    });
    next(err);
  }
});

// PUT update form
router.put('/:id', async (req, res, next) => {
  try {
    logger.info('Updating form', { 
      formId: req.params.id,
      title: req.body.title 
    });
    await formController.updateForm(req, res);
    logger.info('Successfully updated form', { 
      formId: req.params.id 
    });
  } catch (err) {
    logger.error('Error updating form', { 
      formId: req.params.id,
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// DELETE form
router.delete('/:id', async (req, res, next) => {
  try {
    logger.info('Deleting form', { 
      formId: req.params.id 
    });
    await formController.deleteForm(req, res);
    logger.info('Successfully deleted form', { 
      formId: req.params.id 
    });
  } catch (err) {
    logger.error('Error deleting form', { 
      formId: req.params.id,
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// ============================================
// FORM RESPONSE ROUTES
// ============================================

// POST submit form response
router.post('/:id/responses', async (req, res, next) => {
  try {
    logger.info('Submitting form response', { 
      formId: req.params.id,
      respondentName: req.body.respondent_name 
    });
    await formController.submitFormResponse(req, res);
    logger.info('Successfully submitted form response', { 
      formId: req.params.id 
    });
  } catch (err) {
    logger.error('Error submitting form response', { 
      formId: req.params.id,
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// GET all responses for a form
router.get('/:id/responses', async (req, res, next) => {
  try {
    logger.info('Fetching all responses for form', { 
      formId: req.params.id 
    });
    await formController.getAllResponses(req, res);
    logger.info('Successfully fetched responses', { 
      formId: req.params.id 
    });
  } catch (err) {
    logger.error('Error fetching responses', { 
      formId: req.params.id,
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// GET single response details
router.get('/responses/:id', async (req, res, next) => {
  try {
    logger.info('Fetching single response', { 
      responseId: req.params.id 
    });
    await formController.getSingleResponse(req, res);
    logger.info('Successfully fetched response', { 
      responseId: req.params.id 
    });
  } catch (err) {
    logger.error('Error fetching single response', { 
      responseId: req.params.id,
      error: err.message, 
      stack: err.stack 
    });
    next(err);
  }
});

// ============================================
// ERROR HANDLING MIDDLEWARE
// ============================================

// Global error handler for routes
const errorHandler = (err, req, res, next) => {
  // Log the error
  logger.error('Global error handler', {
    error: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip
  });

  // Determine status code
  const statusCode = err.statusCode || err.status || 500;
  
  // Determine error message
  const message = err.message || 'Something went wrong';

  // Send error response
  res.status(statusCode).json({
    success: false,
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
  });
};

// Apply error handling middleware
router.use(errorHandler);

module.exports = router;