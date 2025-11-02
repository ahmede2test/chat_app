<h1 align="center">✨ NEBULA CHAT: The Real-Time Communication Engine</h1>
<p align="center">
<b>A High-Fidelity Mobile Application Demonstrating Expertise in Flutter, WebRTC, and Scalable Architecture.</b>
</p>

<p align="center">
<img src="https://readme-typing-svg.herokuapp.com?font=Fira+Code&size=25&pause=1000&color=9400D3&center=true&vCenter=true&width=750&lines=Advanced+Flutter+App+%7C+WebRTC+Calling+Implementation;Optimized+for+Performance+and+Maintainability;Built+by+Ahmed+Osman+Mohamed+El-Sisi" alt="Typing SVG" />
</p>

💡 I. Core Technical Achievements

This project is not just a chat application; it is a Real-Time Communication Platform built to showcase mastery in three critical areas of modern mobile development.

Area

Focus

Skill Demonstrated

Real-Time Media

WebRTC Integration

Implementing P2P (Peer-to-Peer) audio and video connectivity.

Data Signaling

Firestore Signalling Server

Managing the complex exchange of SDP (Session Description Protocol) and ICE Candidates for reliable call setup.

Architecture

Clean/Layered Structure

Separating business logic (Services) from UI (Screens) for high testability.

Scalability

Provider/Bloc State Management

Handling intricate states, especially during live call lifecycles.

🏗️ II. Architecture Deep Dive (Clean Code)

The repository structure reflects a commitment to Clean Architecture principles, making the codebase easy to navigate, maintain, and scale.

A. The Folder Structure

The clear separation of concerns guarantees that changes in the UI layer do not affect the core business logic, and vice versa.

B. Logical Components

lib/core/: Utility classes, constants, and global helper functions.

lib/models/: Defines the data blueprints: UserModel, MessageModel, CallDataModel.

lib/services/: The Engine. This layer encapsulates all backend interactions and complex protocols.

auth_service.dart: Handles Firebase Authentication flow.

chat_service.dart: Manages Firestore CRUD operations for messages.

call_service.dart: Critical component that manages the WebRTC RTCPeerConnection and all signaling logic.

lib/screens/: The Presentation Layer (UI and Widgets).

📞 III. Advanced Feature: WebRTC Call Handling

The ability to establish live P2P calls without routing media through a server is the project's most complex feature, handled entirely within the call_service.dart.

Initiation: Caller creates an SDP Offer.

Exchange: Offer is uploaded to Firestore and listened to by the Callee.

Connection: Callee sends an SDP Answer back.

Network Setup: Both parties continuously exchange ICE Candidates via Firestore to find the optimal direct connection path.

This mechanism ensures minimal latency and maximum data security during live communication.

🛠️ IV. Technology Stack

Category

Technologies

Framework



Database



Real-Time



State Management



📸 V. Interface Preview (Screenshots)

(هنا ستقوم بإضافة لقطات الشاشة الجميلة لتطبيقك)

<p align="center">
<!-- Replace these placeholders with your actual screenshot paths (e.g., assets/screenshots/chat_screen.png) -->
<img src="https://placehold.co/400x800/8A2BE2/FFFFFF?text=Main+Chat+List" alt="Main Chat List Screen" />
<img src="https://placehold.co/400x800/00CED1/FFFFFF?text=Live+Video+Call" alt="Live Video Call Screen" />
</p>

<p align="center">
Ahmed Osman Mohamed El-Sisi | Flutter Mobile App Developer
</p>
<p align="center">
<a href="mailto:ahmed.osmanis.fcai@gmail.com"><img src="https://img.shields.io/badge/Email-D14836?style=for-the-badge&logo=gmail&logoColor=white"></a>
<a href="https://linkedin.com/in/ahmed-osman22"><img src="https://img.shields.io/badge/LinkedIn-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white"></a>
</p>
