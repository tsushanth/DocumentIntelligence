const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Security middleware
app.use(helmet());
app.use(express.json({ limit: '10mb' }));

// CORS - restrict to your app bundle IDs in production
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  methods: ['POST'],
  allowedHeaders: ['Content-Type', 'X-API-Key', 'X-Bundle-ID']
}));

// Rate limiting - 100 requests per 15 minutes per IP
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later.' }
});
app.use('/api/', limiter);

// API Key validation middleware
const validateApiKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  const bundleId = req.headers['x-bundle-id'];

  // Validate app API key (you generate this for your apps)
  const validAppKeys = (process.env.APP_API_KEYS || '').split(',');

  if (!apiKey || !validAppKeys.includes(apiKey)) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  // Optional: validate bundle ID
  const validBundleIds = [
    'com.documentintelligence.docuscan',
    'com.documentintelligence.pdfgenius',
    'com.documentintelligence.invoiceflow'
  ];

  if (bundleId && !validBundleIds.includes(bundleId)) {
    return res.status(403).json({ error: 'Invalid app' });
  }

  next();
};

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// OpenAI Chat Completions Proxy
app.post('/api/chat/completions', validateApiKey, async (req, res) => {
  try {
    const { messages, model = 'gpt-4', temperature = 0.7, max_tokens } = req.body;

    if (!messages || !Array.isArray(messages)) {
      return res.status(400).json({ error: 'Messages array is required' });
    }

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model,
        messages,
        temperature,
        ...(max_tokens && { max_tokens })
      })
    });

    if (!response.ok) {
      const error = await response.json();
      console.error('OpenAI API error:', error);
      return res.status(response.status).json({
        error: error.error?.message || 'OpenAI API error'
      });
    }

    const data = await response.json();

    // Log usage for monitoring (optional)
    console.log(`[${new Date().toISOString()}] Chat completion - tokens: ${data.usage?.total_tokens || 'N/A'}`);

    res.json(data);

  } catch (error) {
    console.error('Proxy error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Document Analysis endpoint (convenience wrapper)
app.post('/api/analyze', validateApiKey, async (req, res) => {
  try {
    const { text, task } = req.body;

    if (!text) {
      return res.status(400).json({ error: 'Text is required' });
    }

    const systemPrompts = {
      summarize: 'You are a document summarization assistant. Create a concise summary of the provided document.',
      categorize: 'Categorize this document. Respond with only one word: invoice, receipt, contract, letter, report, form, bill, statement, or other.',
      title: 'Generate a short, descriptive title for this document (under 60 characters). Include document type, key entity, and date if available. Respond with only the title.',
      extract: 'Extract key fields from this document as JSON: date, vendorName, totalAmount, currency, invoiceNumber. Use null for missing fields.'
    };

    const systemPrompt = systemPrompts[task] || systemPrompts.summarize;

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: text }
        ],
        temperature: task === 'extract' ? 0.2 : 0.5
      })
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json({ error: error.error?.message });
    }

    const data = await response.json();
    const content = data.choices?.[0]?.message?.content || '';

    res.json({
      result: content,
      usage: data.usage
    });

  } catch (error) {
    console.error('Analysis error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Question Answering endpoint
app.post('/api/ask', validateApiKey, async (req, res) => {
  try {
    const { document, question } = req.body;

    if (!document || !question) {
      return res.status(400).json({ error: 'Document and question are required' });
    }

    const response = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-4',
        messages: [
          {
            role: 'system',
            content: 'You are a document Q&A assistant. Answer questions based only on the provided document. If the information is not in the document, say so.'
          },
          {
            role: 'user',
            content: `Document:\n${document}\n\nQuestion: ${question}`
          }
        ],
        temperature: 0.7
      })
    });

    if (!response.ok) {
      const error = await response.json();
      return res.status(response.status).json({ error: error.error?.message });
    }

    const data = await response.json();

    res.json({
      answer: data.choices?.[0]?.message?.content || '',
      usage: data.usage
    });

  } catch (error) {
    console.error('Q&A error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Document Intelligence Proxy running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});
