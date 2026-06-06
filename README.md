# autocorrect_app
**AutoCorrect App** is a smart text correction tool that automatically detects and fixes spelling mistakes, grammar errors, and typing inconsistencies in real time. Built for speed and accuracy, it enhances writing quality, improves productivity, and provides a seamless user experience with an intuitive interface.
# 🚀 Vinax AutoCorrect AI

**Vinax AutoCorrect AI** is a modern AI-powered writing assistant designed to help users write faster, clearer, and more professionally. It combines real-time autocorrection, grammar checking, tone conversion, smart rewriting, email drafting, document proofreading, voice-to-text processing, analytics, custom dictionaries, and personalized AI learning into one powerful platform.

---

## ✨ Features

### 📝 Writing Assistant

* Real-time spelling correction
* Grammar and punctuation fixes
* Context-aware suggestions
* Smart sentence restructuring

### 🎯 Tone Converter

Convert text into:

* Professional
* Formal
* Casual
* Friendly
* Academic
* Business
* Marketing
* Social Media

### 📄 Document Proofreader

* Readability analysis
* Grammar checking
* Clarity scoring
* Content improvement suggestions

### 🔄 Smart Rewriter

* Shorten text
* Expand content
* Simplify language
* Humanize AI-generated text
* Persuasive rewriting

### 📧 Email Writer

* Professional email generation
* Subject line creation
* Follow-up suggestions
* Business communication templates

### 🎤 Voice-to-Text

* Speech recognition architecture
* Automatic grammar correction
* Voice-powered writing workflow

### 📊 Analytics Dashboard

* Grammar score tracking
* Readability metrics
* Writing improvement insights
* Usage history

### 📚 Custom Dictionary

* Add custom words
* Ignore specific terms
* Personalized correction behavior

### 🧠 AI Learning System

* Learns user writing preferences
* Stores preferred phrases
* Personalized correction suggestions

---

## 🏗️ Project Architecture

```text
auto_correct/
├── flutter_app/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   └── src/
│   │       ├── core/
│   │       ├── features/
│   │       └── models/
│   └── test/
│
├── backend/
│   ├── package.json
│   ├── server.js
│   ├── firebase.json
│   ├── firestore.rules
│   └── .env.example
│
└── web_app/
    ├── index.html
    ├── styles.css
    └── app.js
```

---

## 🛠️ Tech Stack

### Frontend

* Flutter
* Material 3
* Riverpod
* Dart

### Web Dashboard

* HTML5
* CSS3
* JavaScript
* Material Design 3

### Backend

* Node.js
* Express.js
* Firebase Cloud Functions

### Database

* Firebase Firestore

### AI Integration

* Google Gemini API
* Gemini 1.5 Flash
* Gemini 1.5 Pro

---

## 🗄️ Firestore Database Structure

### Users Collection

```json
/users/{userId}
{
  "uid": "string",
  "email": "string",
  "displayName": "string",
  "settings": {
    "themeMode": "light",
    "autoCorrectEnabled": true,
    "targetTone": "professional"
  }
}
```

### Documents Collection

```json
/users/{userId}/documents/{documentId}
{
  "title": "string",
  "content": "string",
  "readabilityScore": 85.2,
  "grammarScore": 90.0
}
```

### History Collection

```json
/users/{userId}/history/{historyId}
{
  "originalText": "string",
  "correctedText": "string",
  "featureUsed": "correct",
  "timestamp": "timestamp"
}
```

---

## 🤖 AI Prompt Design

### Grammar Correction

```text
You are an expert copyeditor and writing assistant.

Correct spelling mistakes, punctuation,
subject-verb agreement, and grammar errors.

Preserve meaning and return:
1. Corrected text
2. List of changes
3. Explanations
```

### Tone Conversion

```text
Rewrite the provided text in the selected tone.

Improve fluency and readability while
preserving the original meaning.
```

---

## ⚙️ Installation

### Clone Repository

```bash
git clone https://github.com/your-username/vinax-autocorrect-ai.git

cd vinax-autocorrect-ai
```

---

## Backend Setup

### Install Dependencies

```bash
cd backend

npm install
```

### Configure Environment

Create `.env`

```env
GEMINI_API_KEY=your_api_key_here
PORT=5000
```

### Start Backend

```bash
npm start
```

Server runs on:

```text
http://localhost:5000
```

---

## Web Dashboard Setup

```bash
cd web_app
```

Open:

```text
index.html
```

Or serve using:

```bash
npx http-server
```

---

## Flutter Setup

Install Flutter SDK:

```bash
flutter doctor
```

Install dependencies:

```bash
cd flutter_app

flutter pub get
```

Run:

```bash
flutter run
```

---

## 🧪 Testing

### Backend Tests

```bash
npm test
```

### Flutter Tests

```bash
flutter test
```

---

## 🔒 Security

* API keys stored in environment variables
* Firestore security rules enabled
* Authentication-ready architecture
* Sensitive files excluded via `.gitignore`

### Never Commit

```text
.env
.env.local
google-services.json
firebase-adminsdk.json
```

---

## 📈 Future Roadmap

* Multi-language support
* Chrome Extension
* Microsoft Word Add-in
* Mobile Offline Mode
* AI Writing Coach
* Team Collaboration
* PDF/DOCX Native Parsing
* Advanced Analytics

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch

```bash
git checkout -b feature-name
```

3. Commit changes

```bash
git commit -m "Added feature"
```

4. Push branch

```bash
git push origin feature-name
```

5. Open a Pull Request

---

## 📜 License

MIT License

---

## 👨‍💻 Author

**Vinay Pingale**

Built with ❤️ using Flutter, Firebase, Node.js, and Google Gemini AI.

---

### ⭐ If you find this project useful, consider giving it a star on GitHub!
