import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

// ******************************************************
// الثوابت والتصميم
// ******************************************************
const Color _kBackgroundColor = Colors.black;
const Color _kPrimaryColor = Color(0xFFD4AF37); // Gold-like
const Color _kInputFill = Color(0xFF2C2C2C);
const Color _kTextColor = Colors.white;

class VideoCallScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatPartnerId;
  final bool isVideoCall; // لتحديد ما إذا كانت مكالمة فيديو أم صوت فقط
  final bool isCaller; // لتحديد ما إذا كان المستخدم الحالي هو المتصل

  const VideoCallScreen({
    Key? key,
    required this.chatRoomId,
    required this.chatPartnerId,
    required this.isVideoCall,
    required this.isCaller,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  // ******************************************************
  // WebRTC & Signaling State Variables
  // ******************************************************
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Renderers لعرض الفيديو على الشاشة
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إدارة اشتراك Firestore لمنع تسرب الذاكرة
  StreamSubscription<QuerySnapshot>? _signalingSubscription;

  // معرف المستخدم الحالي (يجب أن يتم جلبه من نظام المصادقة)
  late final String _currentUserId;

  // لتمييز أدوار المستخدمين (المتصل/المستجيب)
  late final bool _isCaller;
  late final String _signalingCollection;

  // متغيرات وحالة شاشة المكالمة
  String _callStatus = 'Connecting...';
  bool _isMuted = false;
  bool _isCameraOff = false;

  // ******************************************************
  // WebRTC Configuration
  // ******************************************************
  // خوادم ICE (STUN/TURN)
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
    ]
  };

  // قيود SDP للتحكم في ما إذا كان سيتم إرسال واستقبال الفيديو والصوت
  final Map<String, dynamic> _sdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  @override
  void initState() {
    super.initState();

    // الحصول على معرف المستخدم الحالي من Firebase Auth (افتراضياً)
    _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';

    _isCaller = widget.isCaller;

    // مسار الإشارات في Firestore
    // /calls/{chatRoomId}/signaling
    _signalingCollection = 'calls/${widget.chatRoomId}/signaling';

    initRenderers();
    _connect();
  }

  // تهيئة عارضي الفيديو
  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  // 1. إنشاء الاتصال الأقراني وتهيئة دفق الوسائط
  void _connect() async {
    try {
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': widget.isVideoCall ? {'facingMode': 'user'} : false,
      };

      // 1.1. الحصول على دفق الوسائط المحلي (الكاميرا والميكروفون)
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);

      // 1.2. إنشاء اتصال الأقران
      _peerConnection = await createPeerConnection(_iceServers, _sdpConstraints);

      // 1.3. إضافة المسارات المحلية إلى اتصال الأقران
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
      _localRenderer.srcObject = _localStream;
      if (mounted) setState(() {});

      // 1.4. الاستماع لأحداث WebRTC
      _peerConnection!.onIceCandidate = _onIceCandidate;
      _peerConnection!.onAddStream = _onAddStream;
      _peerConnection!.onConnectionState = (state) {
        print('Connection State: $state');
        if (mounted) {
          setState(() {
            switch(state) {
              case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
                _callStatus = 'Call Established';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
                _callStatus = 'Connection Failed. Retrying...';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
                _callStatus = 'Call Ended';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateConnecting:
                _callStatus = 'Connecting...';
                break;
              case RTCPeerConnectionState.RTCPeerConnectionStateNew:
                _callStatus = 'New Connection State';
                break;
              default:
                break;
            }
          });
        }
      };

      // 1.5. إذا كان المستخدم هو المتصل، يبدأ بإنشاء Offer
      if (_isCaller) {
        await _createOffer();
      }

      // 1.6. يبدأ بالاستماع لإشارات Firestore
      _listenForSignaling();
    } catch (e) {
      print('Failed to connect or get media: $e');
      if (mounted) setState(() { _callStatus = 'Error: Could not start call.'; });
    }
  }

  // 2. معالجة مرشحات ICE (الشبكة) وإرسالها إلى Firestore
  void _onIceCandidate(RTCIceCandidate candidate) {
    if (candidate == null) return;
    print('Sending ICE Candidate: ${candidate.sdpMid}');

    // التأكد من أن الاتصال ليس مغلقاً قبل الإرسال
    if (_peerConnection?.iceConnectionState == RTCIceConnectionState.RTCIceConnectionStateClosed) return;

    _firestore.collection(_signalingCollection).add({
      'type': 'candidate',
      'sdpMid': candidate.sdpMid,
      'sdpMlineIndex': candidate.sdpMLineIndex,
      'candidate': candidate.candidate,
      'senderId': _currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 3. معالجة دفق الوسائط البعيد
  void _onAddStream(MediaStream stream) {
    print('Remote stream added. Assigning to renderer.');
    _remoteRenderer.srcObject = stream;
    if (mounted) setState(() {});
  }

  // 4. إنشاء Offer (للمتصل)
  Future<void> _createOffer() async {
    try {
      RTCSessionDescription description =
      await _peerConnection!.createOffer(_sdpConstraints);
      await _peerConnection!.setLocalDescription(description);

      print('Sending Offer: ${description.sdp}');
      _firestore.collection(_signalingCollection).add({
        'type': description.type,
        'sdp': description.sdp,
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() { _callStatus = 'Awaiting Answer...'; });
    } catch (e) {
      print('Error creating offer: $e');
      if (mounted) setState(() { _callStatus = 'Error creating offer.'; });
    }
  }

  // 5. إنشاء Answer (للمستجيب)
  Future<void> _createAnswer() async {
    try {
      RTCSessionDescription description =
      await _peerConnection!.createAnswer(_sdpConstraints);
      await _peerConnection!.setLocalDescription(description);

      print('Sending Answer: ${description.sdp}');
      _firestore.collection(_signalingCollection).add({
        'type': description.type,
        'sdp': description.sdp,
        'senderId': _currentUserId,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() { _callStatus = 'Connecting...'; });
    } catch (e) {
      print('Error creating answer: $e');
      if (mounted) setState(() { _callStatus = 'Error creating answer.'; });
    }
  }

  // 6. الاستماع والتفاعل مع إشارات Firestore
  void _listenForSignaling() {
    _signalingSubscription = _firestore
        .collection(_signalingCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;

        // تجاهل الإشارات المرسلة من المستخدم نفسه
        if (data == null || data['senderId'] == _currentUserId) continue;

        if (change.type == DocumentChangeType.added) {
          switch (data['type']) {
            case 'offer':
              _handleOffer(data);
              break;
            case 'answer':
              _handleAnswer(data);
              break;
            case 'candidate':
              _handleCandidate(data);
              break;
            default:
              break;
          }

          // بعد معالجة الوثيقة، نحتاج إلى حذفها لتجنب معالجتها مرة أخرى
          // يفضل حذف الإشارات مباشرة بعد المعالجة الناجحة
          change.doc.reference.delete().catchError((e) => print("Error deleting signaling doc: $e"));
        }
      }
    }, onError: (error) {
      print("Signaling stream error: $error");
      if (mounted) setState(() { _callStatus = 'Signaling Error.'; });
    });
  }

  // 7. معالجة Offer الواردة (للمستجيب)
  void _handleOffer(Map<String, dynamic> data) async {
    if (!_isCaller && _peerConnection != null) {
      try {
        // <== التصحيح هنا: استخدام await للحصول على القيمة الفعلية
        final remoteDescription = await _peerConnection!.getRemoteDescription();

        // التحقق من وجود وصف بعيد حالي
        if (remoteDescription == null || remoteDescription.type == null) {
          print('Received Offer. Setting remote description...');
          final sdp = RTCSessionDescription(data['sdp'], data['type']);
          await _peerConnection!.setRemoteDescription(sdp);
          await _createAnswer();
        }
      } catch(e) {
        print("Error handling offer: $e");
      }
    }
  }

  // 8. معالجة Answer الواردة (للمتصل)
  void _handleAnswer(Map<String, dynamic> data) async {
    if (_isCaller && _peerConnection != null) {
      try {
        // <== التصحيح هنا: استخدام await للحصول على القيمة الفعلية
        final remoteDescription = await _peerConnection!.getRemoteDescription();

        // التحقق من وجود وصف بعيد حالي
        if (remoteDescription == null || remoteDescription.type == null) {
          print('Received Answer. Setting remote description...');
          final sdp = RTCSessionDescription(data['sdp'], data['type']);
          await _peerConnection!.setRemoteDescription(sdp);
          if (mounted) setState(() { _callStatus = 'Connecting...'; });
        }
      } catch(e) {
        print("Error handling answer: $e");
      }
    }
  }

  // 9. إضافة مرشح ICE الوارد
  void _handleCandidate(Map<String, dynamic> data) async {
    if (_peerConnection != null) {
      try {
        final candidate = RTCIceCandidate(
          data['candidate'],
          data['sdpMid'],
          data['sdpMlineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
        print('Added ICE Candidate.');
      } catch (e) {
        print('Error adding ICE candidate: $e');
      }
    }
  }

  // ******************************************************
  // UI Actions
  // ******************************************************
  void _toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_isMuted;
    });
    if (mounted) setState(() {});
  }

  void _toggleCamera() {
    if (!widget.isVideoCall) return;
    _isCameraOff = !_isCameraOff;
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_isCameraOff;
    });
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    if (!widget.isVideoCall) return;
    _localStream?.getVideoTracks().forEach((track) {
      track.switchCamera();
    });
  }

  void _endCall() async {
    // 1. إلغاء اشتراك Firestore
    await _signalingSubscription?.cancel();
    _signalingSubscription = null;

    // 2. إغلاق اتصال الأقران
    await _peerConnection?.close();
    _peerConnection = null;

    // 3. إيقاف وإلغاء تهيئة دفق الوسائط
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    _localStream = null;

    // 4. إلغاء تهيئة عارضي الفيديو
    await _localRenderer.dispose();
    await _remoteRenderer.dispose();

    // 5. تحديث حالة المكالمة في Firestore
    try {
      await _firestore.collection('calls').doc(widget.chatRoomId).set({
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('Call status updated to ended in Firestore.');
    } catch (e) {
      print('Error updating call status: $e');
    }

    // 6. الرجوع إلى الشاشة السابقة (إنهاء المكالمة)
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    // التأكد من إنهاء المكالمة وتنظيف الموارد عند مغادرة الشاشة
    _endCall();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.isVideoCall ? 'Video Call with ${widget.chatPartnerId}' : 'Voice Call with ${widget.chatPartnerId}',
          style: const TextStyle(color: _kTextColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kBackgroundColor.withOpacity(0.5),
        elevation: 0,
        actions: [
          if (widget.isVideoCall)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: _kPrimaryColor),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Remote Video Stream (Full Screen)
          if (widget.isVideoCall && _remoteRenderer.srcObject != null)
            Positioned.fill(
              child: RTCVideoView(_remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
            )
          else
            Positioned.fill(
              child: Container(
                color: _kBackgroundColor,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.isVideoCall ? Icons.person : Icons.call_end,
                        size: 80,
                        color: _kPrimaryColor.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.isVideoCall ? 'Awaiting Remote Stream...' : 'Voice Call Active',
                        style: TextStyle(color: _kTextColor.withOpacity(0.7), fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Local Video Stream (Small Window)
          if (widget.isVideoCall)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 100,
                height: 150,
                decoration: BoxDecoration(
                  color: _kInputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimaryColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _localRenderer.srcObject != null
                      ? RTCVideoView(_localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                      : Center(
                    child: Text(
                      'My View',
                      style: TextStyle(color: _kTextColor.withOpacity(0.8), fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),

          // Status Indicator
          Positioned(
            top: 180,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _callStatus,
                  style: const TextStyle(color: _kPrimaryColor, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // Control Bar at the Bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Icons.mic_off : Icons.mic,
                  color: _isMuted ? Colors.red : _kInputFill.withOpacity(0.8),
                  onPressed: _toggleMute,
                  label: _isMuted ? 'Unmute' : 'Mute',
                ),
                _buildControlButton(
                  icon: Icons.call_end,
                  color: Colors.red.shade700,
                  onPressed: _endCall,
                  label: 'End Call',
                ),
                if (widget.isVideoCall)
                  _buildControlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    color: _isCameraOff ? Colors.red : _kInputFill.withOpacity(0.8),
                    onPressed: _toggleCamera,
                    label: _isCameraOff ? 'Camera On' : 'Camera Off',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // أداة بناء زر التحكم
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      children: [
        FloatingActionButton(
          heroTag: label,
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: _kTextColor,
          elevation: 8,
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: _kTextColor, fontSize: 12),
        ),
      ],
    );
  }
}
