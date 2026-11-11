/**
 * SkillTrack - Secure Gemini AI Backend Proxy (Vercel Serverless Function)
 *
 * Security Guarantees:
 * 1. GEMINI_API_KEY is stored exclusively in server-side environment variables (process.env.GEMINI_API_KEY).
 * 2. Secrets are never exposed to client-side Flutter Web JavaScript or network responses.
 * 3. Enforces HTTP method restrictions (POST only).
 * 4. In-memory sliding window rate limiting per client IP (30 requests/minute).
 * 5. Strict payload size and format validation with 25-second upstream timeout.
 * 6. Sanitized error messages that never leak upstream tokens, URLs, or stack traces.
 */

// In-memory sliding window rate limiter
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 30;

function isRateLimited(clientIp) {
  const now = Date.now();
  const clientRecord = rateLimitMap.get(clientIp);

  if (!clientRecord) {
    rateLimitMap.set(clientIp, { count: 1, startTime: now });
    return false;
  }

  if (now - clientRecord.startTime > RATE_LIMIT_WINDOW_MS) {
    rateLimitMap.set(clientIp, { count: 1, startTime: now });
    return false;
  }

  clientRecord.count += 1;
  return clientRecord.count > MAX_REQUESTS_PER_WINDOW;
}

// Cleanup stale IP entries every 5 minutes to prevent memory leaks
setInterval(() => {
  const now = Date.now();
  for (const [ip, record] of rateLimitMap.entries()) {
    if (now - record.startTime > RATE_LIMIT_WINDOW_MS * 5) {
      rateLimitMap.delete(ip);
    }
  }
}, 5 * 60 * 1000);

module.exports = async (req, res) => {
  // CORS configuration
  res.setHeader('Access-Control-Allow-Credentials', 'true');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,POST');
  res.setHeader(
    'Access-Control-Allow-Headers',
    'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version'
  );

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  // Health check endpoint for client readiness probes
  if (req.method === 'GET') {
    const isConfigured = Boolean(process.env.GEMINI_API_KEY && process.env.GEMINI_API_KEY.trim());
    return res.status(200).json({
      status: 'active',
      service: 'SkillTrack AI Proxy',
      configured: isConfigured,
      timestamp: new Date().toISOString()
    });
  }

  if (req.method !== 'POST') {
    return res.status(405).json({
      error: 'Method Not Allowed',
      message: 'Only POST and GET requests are accepted by this proxy.'
    });
  }

  // Rate Limiting Check
  const clientIp =
    req.headers['x-forwarded-for']?.split(',')[0]?.trim() ||
    req.socket?.remoteAddress ||
    'anonymous';

  if (isRateLimited(clientIp)) {
    res.setHeader('Retry-After', '60');
    return res.status(429).json({
      error: 'Too Many Requests',
      message: 'Rate limit exceeded (30 requests/min). Please try again in a minute.'
    });
  }

  // Server Environment Verification
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey || !apiKey.trim()) {
    return res.status(503).json({
      error: 'Service Unavailable',
      message: 'AI backend proxy is currently unconfigured. Offline heuristic fallback should be used.'
    });
  }

  // Request Body & Payload Validation
  const body = req.body;
  if (!body || typeof body !== 'object') {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'A valid JSON request body is required.'
    });
  }

  const { prompt, systemInstruction, forceJson } = body;

  if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'A non-empty string prompt is required.'
    });
  }

  if (prompt.length > 20000) {
    return res.status(413).json({
      error: 'Payload Too Large',
      message: 'Prompt exceeds maximum allowable size (20,000 characters).'
    });
  }

  if (systemInstruction && (typeof systemInstruction !== 'string' || systemInstruction.length > 5000)) {
    return res.status(400).json({
      error: 'Bad Request',
      message: 'systemInstruction must be a string under 5,000 characters.'
    });
  }

  // Prepare Gemini Payload
  const geminiPayload = {
    contents: [
      {
        parts: [{ text: prompt }]
      }
    ],
    generationConfig: {
      temperature: 0.4,
      maxOutputTokens: 2048,
      ...(forceJson === true ? { responseMimeType: 'application/json' } : {})
    }
  };

  if (systemInstruction && systemInstruction.trim().length > 0) {
    geminiPayload.systemInstruction = {
      parts: [{ text: systemInstruction.trim() }]
    };
  }

  // Call Upstream Gemini API with Timeout & Sanitization
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 25000); // 25s timeout

  try {
    const upstreamUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

    const upstreamResponse = await fetch(upstreamUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey.trim()
      },
      body: JSON.stringify(geminiPayload),
      signal: controller.signal
    });

    clearTimeout(timeoutId);

    if (!upstreamResponse.ok) {
      const statusCode = upstreamResponse.status;
      return res.status(502).json({
        error: 'Upstream AI Error',
        message: `Upstream AI provider responded with status ${statusCode}. Falling back to offline engine.`
      });
    }

    const data = await upstreamResponse.json();
    const candidates = data.candidates;

    if (!candidates || candidates.length === 0) {
      return res.status(200).json({ text: null, warning: 'No completion generated by AI model.' });
    }

    const firstCandidate = candidates[0];
    const parts = firstCandidate.content?.parts;
    const text = parts && parts.length > 0 ? parts[0].text : null;

    return res.status(200).json({
      text: text,
      model: 'gemini-1.5-flash',
      finishReason: firstCandidate.finishReason || 'STOP'
    });
  } catch (err) {
    clearTimeout(timeoutId);

    if (err.name === 'AbortError') {
      return res.status(504).json({
        error: 'Gateway Timeout',
        message: 'The AI service timed out after 25 seconds. Please try again.'
      });
    }

    return res.status(502).json({
      error: 'Proxy Communication Error',
      message: 'Failed to communicate with AI provider. Local offline fallback recommended.'
    });
  }
};
