import 'package:flutter/material.dart';
import 'dart:async';

class ChatRoomCountdown extends StatefulWidget {
  final String expiresAt;
  final VoidCallback? onExpired;
  final bool isTemporary;

  const ChatRoomCountdown({
    Key? key,
    required this.expiresAt,
    this.onExpired,
    this.isTemporary = true,
  }) : super(key: key);

  @override
  State<ChatRoomCountdown> createState() => _ChatRoomCountdownState();
}

class _ChatRoomCountdownState extends State<ChatRoomCountdown> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    
    // 每秒更新一次
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _calculateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    try {
      final expiryTime = DateTime.parse(widget.expiresAt);
      final now = DateTime.now();
      final diff = expiryTime.difference(now);

      setState(() {
        if (diff.isNegative) {
          _remaining = Duration.zero;
          if (!_isExpired) {
            _isExpired = true;
            widget.onExpired?.call();
          }
        } else {
          _remaining = diff;
          _isExpired = false;
        }
      });
    } catch (e) {
      // 解析失敗，可能是永久聊天室
      setState(() {
        _isExpired = false;
        _remaining = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Color _getTimerColor() {
    final totalSeconds = _remaining.inSeconds;
    
    if (_isExpired) {
      return Colors.red;
    } else if (totalSeconds <= 10) {
      return Colors.red;
    } else if (totalSeconds <= 60) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  IconData _getTimerIcon() {
    final totalSeconds = _remaining.inSeconds;
    
    if (_isExpired) {
      return Icons.timer_off;
    } else if (totalSeconds <= 10) {
      return Icons.warning_amber;
    } else {
      return Icons.timer;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 如果不是臨時聊天室，顯示永久標記
    if (!widget.isTemporary) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 16, color: Colors.blue),
            SizedBox(width: 6),
            Text(
              '永久聊天室',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // 臨時聊天室倒計時
    final timerColor = _getTimerColor();
    final timerIcon = _getTimerIcon();
    final timeText = _isExpired ? '已過期' : _formatDuration(_remaining);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: timerColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(timerIcon, size: 16, color: timerColor),
          SizedBox(width: 6),
          Text(
            timeText,
            style: TextStyle(
              color: timerColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// 完整的聊天室倒計時卡片（可用於顯示更多信息）
class ChatRoomCountdownCard extends StatelessWidget {
  final String expiresAt;
  final VoidCallback? onExpired;
  final bool isTemporary;
  final VoidCallback? onFriendInvite;

  const ChatRoomCountdownCard({
    Key? key,
    required this.expiresAt,
    this.onExpired,
    this.isTemporary = true,
    this.onFriendInvite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isTemporary) {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '永久聊天室',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '你們已經是好友，可以永久聊天',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
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

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '臨時聊天室',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '剩餘時間: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.orange.shade700,
                            ),
                          ),
                          ChatRoomCountdown(
                            expiresAt: expiresAt,
                            onExpired: onExpired,
                            isTemporary: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '聊天室過期後可以選擇成為好友',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (onFriendInvite != null) ...[
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onFriendInvite,
                  icon: Icon(Icons.person_add, size: 18),
                  label: Text('立即邀請成為好友'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
