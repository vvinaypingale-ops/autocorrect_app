// Web Application Controller - Vinax AutoCorrect AI

// Backend API Base URL
const API_BASE_URL = 'http://localhost:5000';

// App State
const state = {
  theme: 'dark',
  currentLanguage: 'English',
  geminiApiKey: '',
  customDictionary: ['Vinax', 'AutoCorrect', 'DeepMind'],
  history: [],
  currentFile: null,
  activeView: 'write',
  editorText: '',
  suggestions: []
};

// Initializer
document.addEventListener('DOMContentLoaded', () => {
  loadSettings();
  initTheme();
  setupNavigation();
  setupEventListeners();
  updateAPIStatus();
  renderDictionaryChips();
  renderHistory();
  updateAnalytics();
});

// Load state from localStorage
function loadSettings() {
  const savedKey = localStorage.getItem('vinax_gemini_key');
  if (savedKey) {
    state.geminiApiKey = savedKey;
    document.getElementById('settings-gemini-key').value = savedKey;
  }
  
  const savedDict = localStorage.getItem('vinax_dictionary');
  if (savedDict) {
    state.customDictionary = JSON.parse(savedDict);
  }
  
  const savedHistory = localStorage.getItem('vinax_history');
  if (savedHistory) {
    state.history = JSON.parse(savedHistory);
  }

  const savedTheme = localStorage.getItem('vinax_theme');
  if (savedTheme) {
    state.theme = savedTheme;
  }
}

// Save helper
function saveState(key, data) {
  localStorage.setItem(`vinax_${key}`, JSON.stringify(data));
}

// 1. Theme Manager
function initTheme() {
  document.documentElement.setAttribute('data-theme', state.theme);
  const themeIcon = document.getElementById('theme-icon');
  themeIcon.innerText = state.theme === 'dark' ? 'light_mode' : 'dark_mode';
}

function toggleTheme() {
  state.theme = state.theme === 'dark' ? 'light' : 'dark';
  localStorage.setItem('vinax_theme', state.theme);
  initTheme();
}

// 2. Navigation / Routing Handler
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item');
  const sections = document.querySelectorAll('.view-section');
  const viewTitle = document.getElementById('current-view-title');

  function navigateTo(targetId) {
    const cleanId = targetId.replace('#', '') || 'write';
    state.activeView = cleanId;

    navItems.forEach(item => {
      if (item.getAttribute('href') === `#${cleanId}`) {
        item.classList.add('active');
      } else {
        item.classList.remove('active');
      }
    });

    sections.forEach(sec => {
      if (sec.getAttribute('id') === `view-${cleanId}`) {
        sec.classList.add('active-section');
      } else {
        sec.classList.remove('active-section');
      }
    });

    // Update Header Title
    const activeLabel = document.querySelector(`.nav-item[href="#${cleanId}"] .nav-label`);
    if (activeLabel) {
      viewTitle.innerText = activeLabel.innerText;
    }
    
    // Auto-fill from editor context if appropriate
    if (cleanId === 'tone' && state.editorText) {
      document.getElementById('tone-input').value = state.editorText;
    } else if (cleanId === 'rewrite' && state.editorText) {
      document.getElementById('rewrite-input').value = state.editorText;
    }

    // Mobile Sidebar collapse
    document.querySelector('.sidebar').classList.remove('mobile-open');
  }

  // Hash change routing
  window.addEventListener('hashchange', () => {
    navigateTo(window.location.hash);
  });

  // Handle click route directly
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const href = item.getAttribute('href');
      window.location.hash = href;
      navigateTo(href);
    });
  });

  // Initialize from hash if present
  if (window.location.hash) {
    navigateTo(window.location.hash);
  }
}

// Helper: Show API status
function updateAPIStatus() {
  const badge = document.getElementById('api-status-badge');
  const dot = badge.querySelector('.status-dot');
  const text = badge.querySelector('.status-text');

  if (state.geminiApiKey) {
    dot.className = 'status-dot active';
    text.innerText = 'AI Connected';
    badge.title = 'Using personal Gemini API Key';
  } else {
    dot.className = 'status-dot warning';
    text.innerText = 'Demo Mode';
    badge.title = 'Set Gemini API Key in Settings to connect';
  }
}

// 3. Event Listeners Setup
function setupEventListeners() {
  // Theme click
  document.getElementById('theme-toggle-btn').addEventListener('click', toggleTheme);

  // Mobile drawer menu
  document.getElementById('menu-toggle-btn').addEventListener('click', () => {
    document.querySelector('.sidebar').classList.toggle('mobile-open');
  });

  // Language change
  document.getElementById('global-lang-select').addEventListener('change', (e) => {
    state.currentLanguage = e.target.value;
  });

  // Editor typing word counter
  const textarea = document.getElementById('editor-textarea');
  textarea.addEventListener('input', (e) => {
    state.editorText = e.target.value;
    updateWordCount(state.editorText, 'editor-word-count');
  });

  // Clear & Paste buttons
  document.getElementById('editor-clear-btn').addEventListener('click', () => {
    textarea.value = '';
    state.editorText = '';
    updateWordCount('', 'editor-word-count');
    clearSuggestions();
  });

  document.getElementById('editor-paste-btn').addEventListener('click', async () => {
    try {
      const text = await navigator.clipboard.readText();
      textarea.value = text;
      state.editorText = text;
      updateWordCount(text, 'editor-word-count');
    } catch (err) {
      alert('Clipboard access denied. Please paste manually.');
    }
  });

  // Write Check button
  document.getElementById('editor-check-btn').addEventListener('click', runGrammarCorrection);

  // Rewriter Chip choices
  const modeChips = document.querySelectorAll('.mode-chip');
  modeChips.forEach(chip => {
    chip.addEventListener('click', () => {
      modeChips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
    });
  });

  document.getElementById('rewrite-submit-btn').addEventListener('click', runTextRewrite);
  document.getElementById('rewrite-copy-btn').addEventListener('click', () => {
    copyToClipboard('rewrite-output-box');
  });

  // Email Generator
  document.getElementById('email-generate-btn').addEventListener('click', runEmailGeneration);
  document.getElementById('email-copy-btn').addEventListener('click', () => {
    const subject = document.getElementById('email-subject-text').innerText;
    const body = document.getElementById('email-body-display').innerText;
    const fullText = `Subject: ${subject}\n\n${body}`;
    copyTextToClipboard(fullText);
  });

  // Tone Converter Choices
  const toneBtns = document.querySelectorAll('.tone-btn');
  toneBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      toneBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
    });
  });
  document.getElementById('tone-submit-btn').addEventListener('click', runToneConversion);
  document.getElementById('tone-copy-btn').addEventListener('click', () => {
    copyToClipboard('tone-output-box');
  });

  // Document Proofreader Dropzone
  const dropZone = document.getElementById('proofread-drop-zone');
  const fileInput = document.getElementById('proofread-file-input');

  dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropZone.classList.add('dragover');
  });
  dropZone.addEventListener('dragleave', () => {
    dropZone.classList.remove('dragover');
  });
  dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropZone.classList.remove('dragover');
    if (e.dataTransfer.files.length > 0) {
      handleProofreadFile(e.dataTransfer.files[0]);
    }
  });
  fileInput.addEventListener('change', (e) => {
    if (e.target.files.length > 0) {
      handleProofreadFile(e.target.files[0]);
    }
  });

  document.getElementById('proofread-remove-file-btn').addEventListener('click', removeUploadedFile);
  document.getElementById('proofread-submit-btn').addEventListener('click', runDocumentProofread);

  // Settings: API Key Save
  document.getElementById('save-api-settings-btn').addEventListener('click', () => {
    const key = document.getElementById('settings-gemini-key').value.trim();
    state.geminiApiKey = key;
    localStorage.setItem('vinax_gemini_key', key);
    updateAPIStatus();
    showNotification('API settings saved successfully.');
  });

  // Settings: Custom Dictionary Add
  document.getElementById('add-dict-word-btn').addEventListener('click', () => {
    const wordInput = document.getElementById('settings-dictionary-input');
    const word = wordInput.value.trim();
    if (word && !state.customDictionary.includes(word)) {
      state.customDictionary.push(word);
      saveState('dictionary', state.customDictionary);
      renderDictionaryChips();
      wordInput.value = '';
      showNotification(`"${word}" added to custom dictionary.`);
    }
  });

  // Clear History
  document.getElementById('history-clear-all-btn').addEventListener('click', () => {
    if (confirm('Are you sure you want to clear all history logs?')) {
      state.history = [];
      saveState('history', state.history);
      renderHistory();
      updateAnalytics();
      showNotification('History cleared.');
    }
  });

  // Chat Assistant widget
  const chatToggle = document.getElementById('chat-toggle-btn');
  const chatPanel = document.getElementById('chat-panel');
  chatToggle.addEventListener('click', () => {
    chatPanel.style.display = chatPanel.style.display === 'none' ? 'flex' : 'none';
    const indicator = chatToggle.querySelector('.pulse-indicator');
    if (indicator) indicator.style.display = 'none';
  });
  document.getElementById('chat-close-btn').addEventListener('click', () => {
    chatPanel.style.display = 'none';
  });

  document.getElementById('chat-send-btn').addEventListener('click', submitChatMessage);
  document.getElementById('chat-input-field').addEventListener('keypress', (e) => {
    if (e.key === 'Enter') submitChatMessage();
  });

  // Voice Mic
  document.getElementById('voice-input-btn').addEventListener('click', openVoiceDialog);
  document.getElementById('voice-modal-close').addEventListener('click', closeVoiceDialog);
  document.getElementById('voice-cancel-btn').addEventListener('click', closeVoiceDialog);
  document.getElementById('voice-process-btn').addEventListener('click', applyVoiceCorrection);
}

// 4. Feature Actions

// --- View 1: Write & Correct ---
async function runGrammarCorrection() {
  if (!state.editorText.trim()) {
    showNotification('Please enter some text to check.', 'warning');
    return;
  }

  const checkBtn = document.getElementById('editor-check-btn');
  const btnText = checkBtn.querySelector('span:not(.material-symbols-rounded)');
  const originalTextHTML = checkBtn.innerHTML;
  
  checkBtn.disabled = true;
  btnText.innerText = 'Analyzing...';

  try {
    const response = await fetch(`${API_BASE_URL}/api/correct`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gemini-key': state.geminiApiKey
      },
      body: JSON.stringify({
        text: state.editorText,
        language: state.currentLanguage
      })
    });

    const data = await response.json();
    checkBtn.disabled = false;
    checkBtn.innerHTML = originalTextHTML;

    if (data.error) {
      throw new Error(data.error);
    }

    state.suggestions = data.corrections || [];
    renderSuggestions(data.correctedText);

    if (data.isDemo) {
      showNotification('Demo correction loaded. Configure your Gemini key in Settings for full AI capabilities.', 'warning');
    } else {
      showNotification('Grammar audit complete!');
      // Save history log
      addHistoryRecord('Grammar Check', state.editorText, data.correctedText);
    }
  } catch (error) {
    console.error(error);
    checkBtn.disabled = false;
    checkBtn.innerHTML = originalTextHTML;
    showNotification('Failed to connect to backend server. Make sure node server.js is running.', 'warning');
    runFallbackGrammarCheck();
  }
}

function runFallbackGrammarCheck() {
  // Fallback simulator for demo ease
  const text = state.editorText;
  let corrected = text;
  const mockCorrections = [];

  if (text.toLowerCase().includes('helo')) {
    corrected = corrected.replace(/helo/gi, 'Hello');
    mockCorrections.push({ original: 'helo', replacement: 'Hello', explanation: 'Corrected spelling of greeting.' });
  }
  if (text.toLowerCase().includes('aree')) {
    corrected = corrected.replace(/aree/gi, 'are');
    mockCorrections.push({ original: 'aree', replacement: 'are', explanation: 'Fixed duplicated letter typo.' });
  }
  if (text.toLowerCase().includes('he go')) {
    corrected = corrected.replace(/he go/gi, 'he went');
    mockCorrections.push({ original: 'he go', replacement: 'he went', explanation: 'Fixed tense agreement for past action.' });
  }

  state.suggestions = mockCorrections;
  renderSuggestions(corrected);
  showNotification('Demo Mockup Autocorrect applied locally.', 'warning');
}

function renderSuggestions(correctedText) {
  const container = document.getElementById('suggestions-list-container');
  const badge = document.getElementById('suggestions-count-badge');
  const footer = document.getElementById('suggestions-footer-actions');

  container.innerHTML = '';
  badge.innerText = `${state.suggestions.length} Suggestions`;

  if (state.suggestions.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <span class="material-symbols-rounded text-success empty-icon">check_circle</span>
        <p class="empty-title">Looks perfect!</p>
        <p class="empty-desc">No spelling or grammar issues detected in this text.</p>
      </div>
    `;
    footer.style.display = 'none';
    return;
  }

  footer.style.display = 'block';

  state.suggestions.forEach((item, index) => {
    const card = document.createElement('div');
    card.className = 'suggestion-item';
    card.innerHTML = `
      <div class="suggestion-meta">
        <span class="suggestion-type">Typo / Grammar</span>
      </div>
      <div class="suggestion-diff">
        <span class="diff-del">${item.original}</span>
        <span class="material-symbols-rounded diff-arrow">arrow_forward</span>
        <span class="diff-ins">${item.replacement}</span>
      </div>
      <p class="suggestion-desc">${item.explanation}</p>
      <div class="suggestion-actions">
        <button class="btn btn-secondary btn-sm" onclick="dismissSuggestion(${index})">Ignore</button>
        <button class="btn btn-primary btn-sm" onclick="applySuggestion(${index}, '${correctedText.replace(/'/g, "\\'")}')">Fix</button>
      </div>
    `;
    container.appendChild(card);
  });

  // Apply all corrections handler
  document.getElementById('apply-all-suggestions-btn').onclick = () => {
    document.getElementById('editor-textarea').value = correctedText;
    state.editorText = correctedText;
    updateWordCount(correctedText, 'editor-word-count');
    clearSuggestions();
    showNotification('Applied all corrections.');
  };
}

window.applySuggestion = function(index, fullCorrected) {
  const item = state.suggestions[index];
  const textarea = document.getElementById('editor-textarea');
  let currentVal = textarea.value;

  // Simple replacement
  const regex = new RegExp(item.original, 'g');
  currentVal = currentVal.replace(regex, item.replacement);
  
  textarea.value = currentVal;
  state.editorText = currentVal;
  updateWordCount(currentVal, 'editor-word-count');
  
  // Remove from suggestions array
  state.suggestions.splice(index, 1);
  renderSuggestions(fullCorrected);
  showNotification('Correction applied.');
};

window.dismissSuggestion = function(index) {
  state.suggestions.splice(index, 1);
  // Re-render suggestions
  renderSuggestions(state.editorText);
};

function clearSuggestions() {
  state.suggestions = [];
  renderSuggestions('');
}

// --- View 2: Smart Rewriter ---
async function runTextRewrite() {
  const input = document.getElementById('rewrite-input').value.trim();
  if (!input) {
    showNotification('Please enter text to rewrite.', 'warning');
    return;
  }

  const activeModeChip = document.querySelector('.mode-chip.active');
  const mode = activeModeChip ? activeModeChip.getAttribute('data-mode') : 'simplify';

  const outputBox = document.getElementById('rewrite-output-box');
  const expBox = document.getElementById('rewrite-explanation-box');
  const submitBtn = document.getElementById('rewrite-submit-btn');

  outputBox.innerHTML = '<p class="text-muted">Rewriting text in progress...</p>';
  expBox.style.display = 'none';
  submitBtn.disabled = true;

  try {
    const response = await fetch(`${API_BASE_URL}/api/rewrite`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gemini-key': state.geminiApiKey
      },
      body: JSON.stringify({ text: input, mode })
    });

    const data = await response.json();
    submitBtn.disabled = false;

    if (data.error) throw new Error(data.error);

    outputBox.innerText = data.correctedText;
    expBox.innerText = `AI Explanation: ${data.explanation}`;
    expBox.style.display = 'block';

    addHistoryRecord(`Rewriter (${mode})`, input, data.correctedText);
  } catch (error) {
    submitBtn.disabled = false;
    outputBox.innerHTML = `<p class="text-muted">[Backend not running] Simulating: ${mode.toUpperCase()} mode.<br>Configure API settings to enable Gemini rewrites.</p>`;
    expBox.innerText = `Fallback: Rephrased original phrasing into modern clean language.`;
    expBox.style.display = 'block';
  }
}

// --- View 3: Email Assistant ---
async function runEmailGeneration() {
  const prompt = document.getElementById('email-prompt').value.trim();
  if (!prompt) {
    showNotification('Please write what the email is about.', 'warning');
    return;
  }

  const template = document.getElementById('email-template').value;
  const tone = document.getElementById('email-tone').value;
  const recipient = document.getElementById('email-recipient').value.trim();

  const bodyDisplay = document.getElementById('email-body-display');
  const subjectDisplay = document.getElementById('email-subject-line');
  const subjectText = document.getElementById('email-subject-text');
  const followUpSec = document.getElementById('email-follow-ups');
  const generateBtn = document.getElementById('email-generate-btn');

  bodyDisplay.innerHTML = '<p class="text-muted">Drafting your email draft...</p>';
  subjectDisplay.style.display = 'none';
  followUpSec.style.display = 'none';
  generateBtn.disabled = true;

  try {
    const response = await fetch(`${API_BASE_URL}/api/email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gemini-key': state.geminiApiKey
      },
      body: JSON.stringify({ prompt, template, tone, recipient })
    });

    const data = await response.json();
    generateBtn.disabled = false;

    if (data.error) throw new Error(data.error);

    subjectText.innerText = data.subject;
    subjectDisplay.style.display = 'block';
    bodyDisplay.innerText = data.body;
    
    // Chips for replies
    const chipsContainer = document.getElementById('email-follow-up-chips');
    chipsContainer.innerHTML = '';
    
    if (data.followUpSuggestions && data.followUpSuggestions.length > 0) {
      data.followUpSuggestions.forEach(sug => {
        const chip = document.createElement('span');
        chip.className = 'follow-up-chip';
        chip.innerText = sug;
        chip.addEventListener('click', () => {
          document.getElementById('email-prompt').value = `Reply suggestion: "${sug}" for the email: "${data.subject}"`;
          runEmailGeneration();
        });
        chipsContainer.appendChild(chip);
      });
      followUpSec.style.display = 'block';
    }

    addHistoryRecord(`Email Writer (${template})`, prompt, `Subject: ${data.subject}\n\n${data.body}`);
  } catch (error) {
    generateBtn.disabled = false;
    subjectText.innerText = `Draft: ${prompt.slice(0, 30)}`;
    subjectDisplay.style.display = 'block';
    bodyDisplay.innerText = `Dear ${recipient || '[Name]'},\n\nThis is a local fallback draft. Regarding your request: "${prompt}".\n\nPlease let me know if you have any questions.\n\nBest Regards,\n[Your Name]`;
    showNotification('Running in local fallback mock.', 'warning');
  }
}

// --- View 4: Document Proofreader ---
function handleProofreadFile(file) {
  state.currentFile = file;
  const card = document.getElementById('proofread-file-card');
  const details = document.getElementById('proofread-file-name');
  const size = document.getElementById('proofread-file-size');
  const submitBtn = document.getElementById('proofread-submit-btn');

  details.innerText = file.name;
  size.innerText = `${Math.round(file.size / 1024)} KB`;
  card.style.display = 'flex';
  
  // enable audit button
  submitBtn.disabled = false;
}

function removeUploadedFile() {
  state.currentFile = null;
  document.getElementById('proofread-file-card').style.display = 'none';
  document.getElementById('proofread-submit-btn').disabled = true;
  document.getElementById('proofread-file-input').value = '';
}

async function runDocumentProofread() {
  if (!state.currentFile) return;

  const submitBtn = document.getElementById('proofread-submit-btn');
  const originalTextHTML = submitBtn.innerHTML;
  submitBtn.disabled = true;
  submitBtn.innerHTML = 'Auditing Document...';

  // Read text
  const reader = new FileReader();
  reader.onload = async (e) => {
    const text = e.target.result;
    
    try {
      const response = await fetch(`${API_BASE_URL}/api/proofread`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-gemini-key': state.geminiApiKey
        },
        body: JSON.stringify({ text })
      });

      const data = await response.json();
      submitBtn.disabled = false;
      submitBtn.innerHTML = originalTextHTML;

      renderProofreadingReport(data);
    } catch (err) {
      submitBtn.disabled = false;
      submitBtn.innerHTML = originalTextHTML;
      // Fallback
      renderProofreadingReport({
        grammarScore: 92,
        readabilityScore: 81,
        clarityScore: 88,
        feedback: 'This is a demo audit report for your file. To generate real reports, deploy the backend server.',
        suggestions: [
          { original: 'in consistencies', replacement: 'inconsistencies', type: 'Spelling', message: 'Combined compound word.' }
        ]
      });
    }
  };

  reader.readAsText(state.currentFile);
}

function renderProofreadingReport(data) {
  const container = document.getElementById('proofread-report-container');
  container.style.display = 'block';

  document.getElementById('proofread-score-grammar').innerText = `${data.grammarScore}%`;
  document.getElementById('proofread-score-readability').innerText = data.readabilityScore;
  document.getElementById('proofread-score-clarity').innerText = `${data.clarityScore}%`;

  document.getElementById('proofread-feedback-text').innerHTML = `
    <strong>Executive Audit Feedback:</strong><br>
    ${data.feedback || 'The overall writing is sound. Clean sentence structures and professional style detected.'}
    ${data.vocabularyRichness ? `<br><br><strong>Vocabulary Index:</strong> ${data.vocabularyRichness}` : ''}
  `;

  const list = document.getElementById('proofread-corrections-checklist');
  list.innerHTML = '';

  if (!data.suggestions || data.suggestions.length === 0) {
    list.innerHTML = '<p class="text-muted">No structural errors found in file!</p>';
    return;
  }

  data.suggestions.forEach((sug, idx) => {
    const item = document.createElement('div');
    item.className = 'checklist-item';
    item.innerHTML = `
      <span class="material-symbols-rounded text-primary checklist-check">check_box_outline_blank</span>
      <div>
        <strong>Change "${sug.original}" to "${sug.replacement}"</strong> (${sug.type})
        <p class="text-muted" style="font-size:12px; margin-top:2px;">${sug.message}</p>
      </div>
    `;
    item.querySelector('.checklist-check').addEventListener('click', (e) => {
      e.target.innerText = e.target.innerText === 'check_box' ? 'check_box_outline_blank' : 'check_box';
      e.target.classList.toggle('text-muted');
      e.target.classList.toggle('text-primary');
    });
    list.appendChild(item);
  });
}

// --- View 5: Tone Converter ---
async function runToneConversion() {
  const text = document.getElementById('tone-input').value.trim();
  if (!text) {
    showNotification('Please enter text to re-tone.', 'warning');
    return;
  }

  const activeBtn = document.querySelector('.tone-btn.active');
  const tone = activeBtn ? activeBtn.getAttribute('data-tone') : 'Professional';

  const outputBox = document.getElementById('tone-output-box');
  const expBox = document.getElementById('tone-explanation-box');
  const submitBtn = document.getElementById('tone-submit-btn');

  outputBox.innerHTML = '<p class="text-muted">Rephrasing to tone...</p>';
  expBox.style.display = 'none';
  submitBtn.disabled = true;

  try {
    const response = await fetch(`${API_BASE_URL}/api/tone`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gemini-key': state.geminiApiKey
      },
      body: JSON.stringify({ text, tone })
    });

    const data = await response.json();
    submitBtn.disabled = false;

    if (data.error) throw new Error(data.error);

    outputBox.innerText = data.correctedText;
    expBox.innerText = `Explanation: ${data.explanation}`;
    expBox.style.display = 'block';

    addHistoryRecord(`Tone (${tone})`, text, data.correctedText);
  } catch (error) {
    submitBtn.disabled = false;
    outputBox.innerText = `[Local Fallback: ${tone}] ${text}`;
    expBox.innerText = 'Could not fetch tone conversion from backend. Gemini API key required.';
    expBox.style.display = 'block';
  }
}

// --- View 6: Writing Analytics & SVG Gauges ---
function updateAnalytics() {
  const score = state.history.length > 0 ? 94 : 90;
  
  const ring = document.getElementById('ring-grammar');
  if (ring) {
    // Dasharray is 440 (circle circumference)
    // Dashoffset: 440 * (1 - score/100)
    const offset = 440 * (1 - score / 100);
    ring.style.strokeDashoffset = offset;
    const textNode = ring.parentNode.querySelector('.progress-ring-text');
    if (textNode) textNode.textContent = `${score}%`;
  }
  
  // Update numbers based on local history count
  const count = state.history.length;
  document.getElementById('stats-errors-corrected').innerText = count * 2 + 12;
  document.getElementById('stats-total-words').innerText = (count * 150 + 1240).toLocaleString();
}

// --- View 7: History Logs ---
function addHistoryRecord(feature, original, corrected) {
  const record = {
    feature,
    originalText: original,
    correctedText: corrected,
    timestamp: new Date().toLocaleTimeString()
  };

  state.history.unshift(record);
  if (state.history.length > 30) state.history.pop();
  
  saveState('history', state.history);
  renderHistory();
  updateAnalytics();
}

function renderHistory() {
  const container = document.getElementById('history-list-container');
  container.innerHTML = '';

  if (state.history.length === 0) {
    container.innerHTML = `
      <div class="empty-state">
        <span class="material-symbols-rounded empty-icon">update</span>
        <p class="empty-title">History is clean</p>
        <p class="empty-desc">Your writing improvements will automatically save here.</p>
      </div>
    `;
    return;
  }

  state.history.forEach(item => {
    const card = document.createElement('div');
    card.className = 'history-item';
    card.innerHTML = `
      <div class="history-item-header">
        <span class="history-item-feature">${item.feature}</span>
        <span class="history-item-time">${item.timestamp}</span>
      </div>
      <div class="history-diff-box">
        <strong>Original:</strong> <span class="text-muted">${item.originalText}</span>
        <br><br>
        <strong>Polished:</strong> <span>${item.correctedText}</span>
      </div>
    `;
    container.appendChild(card);
  });
}

// --- View 8: Settings ---
function renderDictionaryChips() {
  const container = document.getElementById('dictionary-chips-container');
  container.innerHTML = '';

  state.customDictionary.forEach((word, index) => {
    const chip = document.createElement('span');
    chip.className = 'dictionary-chip';
    chip.innerHTML = `
      <span>${word}</span>
      <button class="dict-remove-btn" onclick="removeDictionaryWord(${index})">
        <span class="material-symbols-rounded" style="font-size:16px;">close</span>
      </button>
    `;
    container.appendChild(chip);
  });
}

window.removeDictionaryWord = function(index) {
  const word = state.customDictionary[index];
  state.customDictionary.splice(index, 1);
  saveState('dictionary', state.customDictionary);
  renderDictionaryChips();
  showNotification(`"${word}" removed from dictionary.`);
};

// --- View 9: Voice to Text Simulation ---
let mediaRecorder;
let speechRecognizer;

function openVoiceDialog() {
  const modal = document.getElementById('voice-modal');
  modal.style.display = 'flex';
  
  const status = document.getElementById('voice-status');
  const preview = document.getElementById('voice-preview');
  const processBtn = document.getElementById('voice-process-btn');

  status.innerText = 'Listening...';
  preview.innerText = 'Say something like: "Helo how aree you, i need this asap"';
  processBtn.style.display = 'none';

  // If Web Speech API is supported
  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (SpeechRecognition) {
    speechRecognizer = new SpeechRecognition();
    speechRecognizer.continuous = false;
    speechRecognizer.interimResults = true;
    speechRecognizer.lang = 'en-US';

    speechRecognizer.onresult = (e) => {
      const transcript = Array.from(e.results)
        .map(result => result[0])
        .map(result => result.transcript)
        .join('');
      preview.innerText = `"${transcript}"`;
      processBtn.style.display = 'inline-flex';
    };

    speechRecognizer.onerror = () => {
      simulateVoiceTyping();
    };

    speechRecognizer.onend = () => {
      status.innerText = 'Audio captured successfully!';
    };

    speechRecognizer.start();
  } else {
    // Web Speech API not supported -> Run simulated timer
    simulateVoiceTyping();
  }
}

function simulateVoiceTyping() {
  const status = document.getElementById('voice-status');
  const preview = document.getElementById('voice-preview');
  const processBtn = document.getElementById('voice-process-btn');

  status.innerText = 'Listening (Simulated)...';
  
  setTimeout(() => {
    preview.innerText = '"Helo how aree you today? I go to office yesterday."';
    status.innerText = 'Speech recognized!';
    processBtn.style.display = 'inline-flex';
  }, 3000);
}

function closeVoiceDialog() {
  document.getElementById('voice-modal').style.display = 'none';
  if (speechRecognizer) {
    speechRecognizer.stop();
  }
}

async function applyVoiceCorrection() {
  const transcribedText = document.getElementById('voice-preview').innerText.replace(/^"|"$/g, '');
  closeVoiceDialog();

  // Load into main editor
  const textarea = document.getElementById('editor-textarea');
  textarea.value = transcribedText;
  state.editorText = transcribedText;
  updateWordCount(transcribedText, 'editor-word-count');

  // Trigger autocorrect immediately
  runGrammarCorrection();
}

// --- Chat assistant ---
async function submitChatMessage() {
  const field = document.getElementById('chat-input-field');
  const query = field.value.trim();
  if (!query) return;

  appendChatMessage('user', query);
  field.value = '';

  const messagesBox = document.getElementById('chat-body-messages');
  // scrolling bottom
  messagesBox.scrollTop = messagesBox.scrollHeight;

  try {
    const response = await fetch(`${API_BASE_URL}/api/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-gemini-key': state.geminiApiKey
      },
      body: JSON.stringify({
        message: query,
        contextText: state.editorText,
        history: getLocalChatHistory()
      })
    });

    const data = await response.json();
    if (data.error) throw new Error(data.error);

    appendChatMessage('bot', data.response);
  } catch (error) {
    appendChatMessage('bot', `Demo fallback response: I noticed you asked: "${query}". Ensure the node server is active to enable live writing chats.`);
  }
  
  messagesBox.scrollTop = messagesBox.scrollHeight;
}

function appendChatMessage(sender, text) {
  const container = document.getElementById('chat-body-messages');
  const bubble = document.createElement('div');
  bubble.className = `chat-message ${sender}`;
  bubble.innerText = text;
  container.appendChild(bubble);
}

function getLocalChatHistory() {
  const elements = document.querySelectorAll('.chat-message');
  const list = [];
  elements.forEach(el => {
    const sender = el.classList.contains('user') ? 'user' : 'bot';
    list.push({ sender, text: el.innerText });
  });
  return list.slice(-10); // last 10 messages
}

// --- Global Utilities ---
function updateWordCount(text, elementId) {
  const count = text.trim() === '' ? 0 : text.trim().split(/\s+/).filter(w => w.length > 0).length;
  document.getElementById(elementId).innerText = count;
}

function copyToClipboard(elementId) {
  const text = document.getElementById(elementId).innerText;
  copyTextToClipboard(text);
}

function copyTextToClipboard(text) {
  navigator.clipboard.writeText(text)
    .then(() => showNotification('Copied to clipboard.'))
    .catch(() => alert('Failed to copy.'));
}

// Toast notification helper
function showNotification(msg, type = 'success') {
  const toast = document.createElement('div');
  toast.style.position = 'fixed';
  toast.style.bottom = '24px';
  toast.style.left = '24px';
  toast.style.background = type === 'success' ? 'var(--success-color)' : 'var(--accent-color)';
  toast.style.color = '#fff';
  toast.style.padding = '12px 24px';
  toast.style.borderRadius = 'var(--radius-md)';
  toast.style.boxShadow = '0 4px 12px rgba(0,0,0,0.2)';
  toast.style.fontFamily = 'var(--font-display)';
  toast.style.fontWeight = '600';
  toast.style.fontSize = '14px';
  toast.style.zIndex = '1000';
  toast.style.animation = 'fadeIn 0.3s ease';
  toast.innerText = msg;

  document.body.appendChild(toast);
  setTimeout(() => {
    toast.style.animation = 'fadeOut 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3000);
}
