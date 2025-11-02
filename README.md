 <h1 align="center">
  <img src="https://i.ibb.co/5nH92f5/nebula-icon.png" width="110"/><br/>
  👑 NEBULA CHAT
</h1>

<h3 align="center">
  The Golden Standard for Real-Time Communication
</h3>

<p align="center">
Where luxury meets technology — <b>Nebula Chat</b> delivers a next-level chat experience powered by <b>Flutter</b>, <b>Firebase</b>, and <b>WebRTC</b>.<br/>
Designed with elegance. Engineered for performance.
</p>

<p align="center">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/WebRTC-P2P%20Calls-6495ED?style=for-the-badge&logo=webrtc&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-Cloud%20Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
<img src="https://img.shields.io/badge/Architecture-Clean%20Code-006400?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Design-Black%20%26%20Gold-FFD700?style=for-the-badge&logoColor=black"/>
</p>

---

## 🌌 Overview

**Nebula Chat** is not your typical chat app — it’s a premium digital experience.  
It redefines real-time communication through a flawless combination of **luxurious design**, **scalable architecture**, and **next-generation P2P calling**.

> 💬 Instant Messaging. 🎥 Real-Time Video Calls. 🔒 End-to-End Privacy.  
> Built for the future — inspired by perfection.

---

## 💫 Design Language: Black & Gold Elegance

<img src="https://i.ibb.co/yFZkpD6/mockup-blackgold.jpg" width="100%"/>

Every pixel of Nebula Chat is crafted with purpose.  
The **black & gold palette** communicates power, precision, and prestige — giving users a refined and modern interface that feels both *exclusive* and *effortless*.

### ✨ Design Highlights
- Premium **Dark Theme** for eye comfort and focus  
- **Golden Accents** highlight primary actions  
- **Smooth transitions** and **glass-effect surfaces**  
- Minimal UI → Maximum impact  

---

## 🚀 Real-Time Power: WebRTC Integration

<img src="https://i.ibb.co/fMVDsDn/mockup-webrtc.jpg" width="100%"/>

Behind Nebula Chat’s elegant exterior lies a **powerful core** — full **P2P video and voice communication** using WebRTC.

### ⚙️ How It Works
- 🔗 **Direct P2P Media Stream** — no central relay, ultra-low latency.  
- ☁️ **Firebase Firestore Signaling** — efficient metadata exchange (SDP/ICE).  
- 🧩 **call_service.dart** — encapsulates full WebRTC lifecycle: create offer, answer, ICE handling, connection states.  

### 💡 Benefits
- Lightning-fast calls ⚡  
- Maximum privacy 🔒  
- Optimized bandwidth & performance 🚀  

---

## 🧱 Clean Architecture & Scalability

```bash
lib/
├── models/             # Data Models (User, Message, CallSession)
├── screens/            # UI & Presentation Layer
├── services/           # Core Logic (Auth, Chat, Call)
│   ├── auth_service.dart
│   ├── chat_service.dart
│   └── call_service.dart
├── utils/              # Constants, Themes, Helpers
└── main.dart           # App Entry Point
