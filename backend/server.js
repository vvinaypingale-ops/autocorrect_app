const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../web_app')));

// Helper to initialize Gemini API Client
function getGeminiClient(req) {
  // Try loading key from:
  // 1. Request Header (x-gemini-key)
  // 2. Request body
  // 3. Environment Variable
  const apiKey = req.headers['x-gemini-key'] || req.body.geminiApiKey || process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return null;
  }
  return new GoogleGenerativeAI(apiKey);
}

// Helper to calculate basic text statistics locally (fallback/enrichment)
function calculateStats(text) {
  if (!text || text.trim() === '') {
    return { grammarScore: 100, readabilityScore: 100, clarityScore: 100, wordCount: 0, charCount: 0 };
  }
  const chars = text.length;
  const words = text.trim().split(/\s+/).filter(w => w.length > 0);
  const sentences = text.split(/[.!?]+/).filter(s => s.trim().length > 0);
  
  const wordCount = words.length;
  const sentenceCount = Math.max(1, sentences.length);
  const charCount = chars;

  // Simple Flesch-Kincaid Ease estimate
  // Formula: 206.835 - 1.015 * (words/sentences) - 84.6 * (syllables/words)
  // We'll estimate syllables as roughly (charCount / 3) for English
  const avgSentenceLength = wordCount / sentenceCount;
  const estimatedSyllables = wordCount * 1.5; // average english word has 1.5 syllables
  const readabilityScore = Math.max(0, Math.min(100, Math.round(206.835 - 1.015 * avgSentenceLength - 84.6 * (estimatedSyllables / wordCount))));

  return {
    wordCount,
    charCount,
    readabilityScore,
    grammarScore: 95, // Default/placeholder starting value
    clarityScore: 92
  };
}

// 1. Real-time Autocorrect / Grammar Correction Route
app.post('/api/correct', async (req, res) => {
  const { text, language = 'English' } = req.body;
  if (!text) {
    return res.status(400).json({ error: 'Text field is required' });
  }

  const ai = getGeminiClient(req);
  if (!ai) {
    // Return friendly local demo mock if no key is configured
    return res.json({
      correctedText: text.replace(/helo/gi, 'Hello').replace(/aree/gi, 'are').replace(/go to office yesterday/gi, 'went to the office yesterday'),
      corrections: [
        { original: 'helo', replacement: 'Hello', explanation: 'Correct spelling.' },
        { original: 'aree', replacement: 'are', explanation: 'Correct spelling.' }
      ],
      isDemo: true,
      message: 'Add your Gemini API key in Settings for live AI corrections.'
    });
  }

  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `You are Vinax AutoCorrect AI, a professional grammar corrector and copyeditor.
Analyze the following text written in ${language}. Fix spelling mistakes, punctuation, grammar, subject-verb agreement, and basic formatting.
Do not change the vocabulary style unless it is grammatically incorrect. Keep the edits as minimal and natural as possible.

Return the result strictly as a valid JSON object with the following structure:
{
  "correctedText": "fully corrected version of the text",
  "corrections": [
    {
      "original": "substring in original text that changed",
      "replacement": "substring in corrected text that replaced it",
      "explanation": "concise description of why this change was made"
    }
  ]
}

Input text:
"${text}"`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: 'application/json' }
    });

    const responseText = result.response.text();
    const responseData = JSON.parse(responseText);
    res.json(responseData);
  } catch (error) {
    console.error('Error in /api/correct:', error);
    res.status(500).json({ error: 'AI processing failed', details: error.message });
  }
});

// 2. Writing Tone Converter Route
app.post('/api/tone', async (req, res) => {
  const { text, tone } = req.body;
  if (!text || !tone) {
    return res.status(400).json({ error: 'Text and tone are required' });
  }

  const ai = getGeminiClient(req);
  if (!ai) {
    return res.json({
      originalText: text,
      correctedText: `[Demo Tone: ${tone}] ${text}`,
      explanation: 'Please provide a Gemini API Key to enable AI Tone conversion.',
      isDemo: true
    });
  }

  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `Rewrite the following text in a "${tone}" tone. Make it sound natural, professional, and coherent for that tone.
Provide the output strictly in this JSON format:
{
  "originalText": "the original text",
  "correctedText": "the rewritten text in the requested tone",
  "explanation": "brief explanation of how the tone was changed"
}`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `${prompt}\n\nInput Text:\n${text}` }] }],
      generationConfig: { responseMimeType: 'application/json' }
    });

    res.json(JSON.parse(result.response.text()));
  } catch (error) {
    console.error('Error in /api/tone:', error);
    res.status(500).json({ error: 'AI tone conversion failed', details: error.message });
  }
});

// 3. Smart Rewriter Route
app.post('/api/rewrite', async (req, res) => {
  const { text, mode } = req.body; // modes: shorten, expand, simplify, persuasive, humanize, readability
  if (!text || !mode) {
    return res.status(400).json({ error: 'Text and mode are required' });
  }

  const ai = getGeminiClient(req);
  if (!ai) {
    return res.json({
      correctedText: `[Demo Smart Rewriter - Mode: ${mode}] ${text}`,
      explanation: 'Set up your Gemini API Key in Settings to rewrite text.',
      isDemo: true
    });
  }

  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `Rewrite the following text with the goal of "${mode}".
Goal explanations:
- shorten: Make it more concise and to the point.
- expand: Add details, elaboration, and vocabulary depth.
- simplify: Use simpler language and clear syntax to make it easy to understand.
- persuasive: Rephrase it to be convincing, professional, and engaging.
- humanize: Remove robotic transitions and make it sound natural and human-written.
- readability: Improve reading flow and sentence structure.

Return your response strictly in this JSON format:
{
  "correctedText": "the rewritten text according to the mode",
  "explanation": "brief description of modifications made"
}`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `${prompt}\n\nInput Text:\n${text}` }] }],
      generationConfig: { responseMimeType: 'application/json' }
    });

    res.json(JSON.parse(result.response.text()));
  } catch (error) {
    console.error('Error in /api/rewrite:', error);
    res.status(500).json({ error: 'AI rewrite failed', details: error.message });
  }
});

// 4. Email Writer Route
app.post('/api/email', async (req, res) => {
  const { prompt, template = 'Business', tone = 'Professional', recipient = '', replyToText = '' } = req.body;
  if (!prompt) {
    return res.status(400).json({ error: 'Prompt is required' });
  }

  const ai = getGeminiClient(req);
  if (!ai) {
    return res.json({
      subject: `Draft: ${prompt.slice(0, 30)}...`,
      body: `This is a demo email draft for: "${prompt}".\n\nPlease add a Gemini API Key in Settings to get high-quality email drafts generated instantly.`,
      followUpSuggestions: ['Ask for feedback', 'Confirm date and time'],
      isDemo: true
    });
  }

  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const emailPrompt = `You are Vinax Email Writer, an AI specialized in drafting effective emails.
Draft an email based on the details below:
- Context/Topic: ${prompt}
- Template/Type: ${template}
- Intended Tone: ${tone}
- Recipient: ${recipient || 'Not specified'}
- Replying to message: ${replyToText || 'None'}

Generate a professional email layout including a subject line, proper salutations, body text, call to action, and professional closing.
Also provide 2 or 3 short follow-up reply/next-step suggestions for the sender.

Return the response strictly as a JSON object:
{
  "subject": "Clear email subject line",
  "body": "Formatted email body with placeholders like [Your Name]",
  "followUpSuggestions": [
    "Suggestion 1",
    "Suggestion 2"
  ]
}`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: emailPrompt }] }],
      generationConfig: { responseMimeType: 'application/json' }
    });

    res.json(JSON.parse(result.response.text()));
  } catch (error) {
    console.error('Error in /api/email:', error);
    res.status(500).json({ error: 'AI email drafting failed', details: error.message });
  }
});

// 5. Document Proofreader / Analytics Route
app.post('/api/proofread', async (req, res) => {
  const { text } = req.body;
  if (!text) {
    return res.status(400).json({ error: 'Text is required' });
  }

  const stats = calculateStats(text);
  const ai = getGeminiClient(req);

  if (!ai) {
    return res.json({
      ...stats,
      feedback: 'Please configure your Gemini API Key in Settings to generate a detailed proofreading audit and structural suggestions.',
      suggestions: [
        { original: 'Demo check', replacement: 'live check', type: 'Spelling', message: 'API key not configured' }
      ],
      isDemo: true
    });
  }

  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const prompt = `You are an AI Document Proofreader. Analyze the document below and evaluate its scores.
1. Grammar Score (0-100)
2. Readability Score (0-100)
3. Clarity Score (0-100)
4. Key suggestions to improve the writing
5. Vocabulary richness summary

Return the response strictly as a JSON object:
{
  "grammarScore": 85,
  "readabilityScore": 75,
  "clarityScore": 80,
  "vocabularyRichness": "Moderate vocabulary. Consider using more varied action verbs.",
  "feedback": "Overall good structure. Some passive sentences detected.",
  "suggestions": [
    {
      "original": "phrase to change",
      "replacement": "improved phrase",
      "type": "Grammar | Clarity | Style | Punctuation",
      "message": "why it should be changed"
    }
  ]
}

Document text:
"${text}"`;

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: prompt }] }],
      generationConfig: { responseMimeType: 'application/json' }
    });

    const aiResponse = JSON.parse(result.response.text());
    res.json({
      ...stats,
      ...aiResponse
    });
  } catch (error) {
    console.error('Error in /api/proofread:', error);
    res.status(500).json({ error: 'AI proofreading failed', details: error.message });
  }
});

// 6. Chat Assistant Route
app.post('/api/chat', async (req, res) => {
  const { message, history = [], contextText = '' } = req.body;
  if (!message) {
    return res.status(400).json({ error: 'Message is required' });
  }

  const ai = getGeminiClient(req);
  if (!ai) {
    return res.json({
      response: `I'm in demo mode! You asked: "${message}". Please configure your Gemini API Key in Settings to start a live AI writing assistant session.`,
      isDemo: true
    });
  }

  try {
    const model = ai.getGenerativeModel({ model: 'gemini-1.5-flash' });
    
    // Convert history format to Gemini API role format
    const contents = [];
    if (contextText) {
      contents.push({
        role: 'user',
        parts: [{ text: `System Context: The user is currently editing or reading this text:\n"${contextText}"\nKeep this text in mind when responding to user commands.` }]
      });
      contents.push({
        role: 'model',
        parts: [{ text: "Understood. I will use the provided document context to assist with edits and writing requests." }]
      });
    }

    for (const msg of history) {
      contents.push({
        role: msg.sender === 'user' ? 'user' : 'model',
        parts: [{ text: msg.text }]
      });
    }

    contents.push({
      role: 'user',
      parts: [{ text: message }]
    });

    const result = await model.generateContent({ contents });
    res.json({ response: result.response.text() });
  } catch (error) {
    console.error('Error in /api/chat:', error);
    res.status(500).json({ error: 'Chat assistance failed', details: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Vinax AutoCorrect AI Backend running on port ${PORT}`);
});
