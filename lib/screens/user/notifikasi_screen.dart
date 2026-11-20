import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  orderReceived,
  paymentVerified,
  scheduleReminder,
}

class NotificationItemModel {
  final String id;
  final String title;
  final String message;
  final DateTime? createdAt;
  final NotificationType type;
  final bool isRead;
  final String? orderId;

  NotificationItemModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
    this.orderId,
  });

  factory NotificationItemModel.fromFirestore(
      String id,
      Map<String, dynamic> data,
      ) {
    final Timestamp? ts = data['createdAt'] as Timestamp?;

    return NotificationItemModel(
      id: id,
      title: (data['title'] ?? 'Notifikasi').toString(),
      message: (data['message'] ?? data['body'] ?? '').toString(),
      createdAt: ts?.toDate(),
      type: _parseType((data['type'] ?? 'order').toString()),
      isRead: data['isRead'] == true,
      orderId: data['orderId']?.toString(),
    );
  }

  static NotificationType _parseType(String rawType) {
    switch (rawType.toLowerCase()) {
      case 'payment':
      case 'payment_verified':
      case 'pembayaran':
        return NotificationType.paymentVerified;
      case 'schedule':
      case 'reminder':
      case 'jadwal':
        return NotificationType.scheduleReminder;
      case 'order':
      case 'order_received':
      default:
        return NotificationType.orderReceived;
    }
  }
}

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  static const Color _bgColor = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF8896AB);
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _softBlue = Color(0xFFEBF2FF);
  static const Color _successGreen = Color(0xFF15805B);
  static const Color _softGreen = Color(0xFFE6F7F0);
  static const Color _dangerRed = Color(0xFFE5484D);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isMenuOpen = false;
  bool _isProcessingBatch = false;

  String? get _currentUid => _auth.currentUser?.uid;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _closeMenu() {
    if (_isMenuOpen) {
      setState(() {
        _isMenuOpen = false;
      });
    }
  }

  Future<void> _markSingleAsRead(NotificationItemModel item) async {
    if (item.isRead) return;
    try {
      await _firestore.collection('notifications').doc(item.id).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint('Gagal update status baca notifikasi: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    final uid = _currentUid;
    _closeMenu();
    if (uid == null || _isProcessingBatch) return;

    setState(() => _isProcessingBatch = true);
    try {
      final unreadSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in unreadSnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menandai notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingBatch = false);
    }
  }

  Future<void> _deleteAllNotifications() async {
    final uid = _currentUid;
    _closeMenu();
    if (uid == null || _isProcessingBatch) return;

    setState(() => _isProcessingBatch = true);
    try {
      final allSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();

      if (allSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in allSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus notifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingBatch = false);
    }
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Baru saja';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24 && now.day == dateTime.day) {
      return '${diff.inHours} jam lalu';
    } else {
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
      if (targetDate == yesterday) {
        return 'Kemarin';
      } else if (diff.inDays < 7) {
        return '${diff.inDays < 1 ? 1 : diff.inDays} hari lalu';
      } else {
        final d = dateTime.day.toString().padLeft(2, '0');
        final m = dateTime.month.toString().padLeft(2, '0');
        final y = dateTime.year;
        return '$d/$m/$y';
      }
    }
  }

  bool _isToday(DateTime? dateTime) {
    if (dateTime == null) return true;
    final now = DateTime.now();
    return now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
  }

  @override
  Widget build(BuildContext context) {
    final uid = _currentUid;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        leadingWidth: 64,
        leading: IconButton(
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: _textPrimary,
            size: 28,
          ),
        ),
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: InkWell(
                onTap: _toggleMenu,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.more_vert_rounded,
                    color: _textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: uid == null
                ? _buildEmptyState()
                : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (
                  BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot,
                  ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: _primaryBlue,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Gagal memuat notifikasi.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _textSecondary),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                final items = docs.map((doc) {
                  final rawData = doc.data();
                  final Map<String, dynamic> data =
                  rawData is Map<String, dynamic>
                      ? rawData
                      : Map<String, dynamic>.from(
                    rawData as Map? ?? {},
                  );
                  return NotificationItemModel.fromFirestore(
                    doc.id,
                    data,
                  );
                }).toList()
                  ..sort((a, b) {
                    final timeA = a.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    final timeB = b.createdAt ??
                        DateTime.fromMillisecondsSinceEpoch(0);
                    return timeB.compareTo(timeA);
                  });

                return _buildNotificationList(items);
              },
            ),
          ),
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  color: const Color(0x2E0F172A),
                ),
              ),
            ),
          if (_isMenuOpen)
            Positioned(
              top: 6,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 245,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1F0F172A),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _markAllAsRead,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_rounded,
                                color: _primaryBlue,
                                size: 19,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tandai semua sudah dibaca',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFF1F5F9),
                      ),
                      InkWell(
                        onTap: _deleteAllNotifications,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.close_rounded,
                                color: _dangerRed,
                                size: 19,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Hapus semua',
                                  style: TextStyle(
                                    color: _dangerRed,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: _softBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: _primaryBlue,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada notifikasi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Informasi pemesanan, pembayaran, dan perjalanan NOV Rent akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationItemModel> items) {
    final todayItems = items.where((e) => _isToday(e.createdAt)).toList();
    final earlierItems = items.where((e) => !_isToday(e.createdAt)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
      children: [
        if (todayItems.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 2, bottom: 14),
            child: Text(
              'Hari ini',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...todayItems.map(_buildNotificationCard),
        ],
        if (earlierItems.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(
              left: 2,
              top: todayItems.isNotEmpty ? 8 : 0,
              bottom: 14,
            ),
            child: const Text(
              'Sebelumnya',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...earlierItems.map(_buildNotificationCard),
        ],
      ],
    );
  }

  Widget _buildNotificationCard(NotificationItemModel item) {
    final bool isPayment = item.type == NotificationType.paymentVerified;
    final Color badgeBg = isPayment ? _softGreen : _softBlue;
    final Color accentColor = isPayment ? _successGreen : _primaryBlue;

    return GestureDetector(
      onTap: () => _markSingleAsRead(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: _buildLeadingIcon(item.type, accentColor),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatRelativeTime(item.createdAt),
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(NotificationType type, Color color) {
    switch (type) {
      case NotificationType.orderReceived:
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1.8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              color: color,
            ),
          ),
        );
      case NotificationType.paymentVerified:
        return Icon(
          Icons.check_rounded,
          color: color,
          size: 20,
        );
      case NotificationType.scheduleReminder:
        return Icon(
          Icons.access_time_rounded,
          color: color,
          size: 19,
        );
    }
  }
}