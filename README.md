<h1 align="center">👑 NEBULA CHAT</h1>
<h3 align="center">The Golden Standard for Real-Time Communication</h3>

<p align="center">
A next-generation chat experience built with Flutter — combining cutting-edge <b>WebRTC</b> technology, <b>Clean Architecture</b>, and a <b>luxurious black & gold design</b>.
</p>

<p align="center">
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/WebRTC-P2P%20Video-6495ED?style=for-the-badge&logo=webrtc&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
<img src="https://img.shields.io/badge/Architecture-Clean%20Code-006400?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Design-Black%20%26%20Gold-FFD700?style=for-the-badge&logoColor=black"/>
</p>

---

## 🌌 Overview

**Nebula Chat** redefines real-time communication with a luxurious and professional approach.  
Designed for performance, security, and elegance — it merges **aesthetic design**, **scalable architecture**, and **real-time peer-to-peer communication**.

This project showcases a high-end **Flutter application** with **P2P video calls**, **Firebase authentication**, and **dynamic chat experiences**, all powered by **WebRTC**.

---

## 💎 1. Golden User Experience & Visual Identity

Nebula Chat isn’t just functional — it’s *beautifully crafted*.  
The dark mode paired with golden highlights provides a premium look and feel.

- 🌑 **Premium Dark Theme** for eye comfort and aesthetic elegance.  
- ✨ **Golden Accents** to guide attention to important actions (e.g., active chats, call buttons).  
- 🧭 **Consistent UX Flow** across all screens.  

### 🎨 Key Screens

| Screen | Purpose | Highlights |
|:------:|:--------|:------------|
| **Login Screen** | Authentication entry point | Clean layout, golden CTA button |
| **Chat List** | Displays all conversations | Elegant user cards, smooth animations |
| **Video Call** | Real-time WebRTC calls | High-quality stream, latency optimized |

---

## 🚀 2. Technical Excellence — WebRTC for P2P Calls

The core innovation lies in **direct peer-to-peer voice and video communication** using **WebRTC**, without a central server for media streaming.

- 🔄 **P2P Streaming:** Ultra-low latency & maximum privacy.  
- ☁️ **Firebase Firestore Signaling:** Handles SDP Offers/Answers and ICE candidates to connect users securely.  
- 🧩 **Modular Lifecycle:** All WebRTC logic encapsulated in `call_service.dart` for clean, maintainable code.  

### 🔧 Technologies Behind the Magic

| Component | Technology | Description |
|:-----------|:------------|:-------------|
| Frontend | Flutter (Dart) | Cross-platform UI with adaptive layouts |
| Backend | Firebase Firestore | Signaling & data sync |
| Auth | Firebase Authentication | Email/Password & Google Sign-In |
| Calls | WebRTC | Direct peer-to-peer media exchange |

---

## 🧱 3. Clean Architecture & Code Structure

Nebula Chat follows **Clean Architecture** principles — ensuring scalability, testability, and modular growth.

```bash
lib/
├── models/             # Data models (User, Message, CallSession, etc.)
├── screens/            # Presentation layer (UI)
├── services/           # Business logic & integrations
│   ├── auth_service.dart
│   ├── chat_service.dart
│   └── call_service.dart
├── utils/              # Helpers, constants, and themes
└── main.dart           # App entry point
