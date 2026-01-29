import 'package:flutter/material.dart';

/// Custom clipper that creates a WhatsApp-style chat bubble with a tail
class ChatBubbleClipper extends CustomClipper<Path> {
  final BubbleDirection direction;
  final double radius;
  final double nipWidth;
  final double nipHeight;

  ChatBubbleClipper({
    required this.direction,
    this.radius = 16.0,
    this.nipWidth = 8.0,
    this.nipHeight = 10.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final isLeft = direction == BubbleDirection.left;

    if (isLeft) {
      // Left bubble (Income) - tail on bottom left
      path.addRRect(
        RRect.fromLTRBR(
          nipWidth,
          0,
          size.width,
          size.height - nipHeight,
          Radius.circular(radius),
        ),
      );

      // Draw the tail (nip) on bottom left
      path.moveTo(nipWidth + radius, size.height - nipHeight);
      path.lineTo(nipWidth, size.height - nipHeight);
      path.quadraticBezierTo(
        0,
        size.height - nipHeight / 2,
        0,
        size.height,
      );
      path.lineTo(nipWidth + 2, size.height - nipHeight);
    } else {
      // Right bubble (Expense) - tail on bottom right
      path.addRRect(
        RRect.fromLTRBR(
          0,
          0,
          size.width - nipWidth,
          size.height - nipHeight,
          Radius.circular(radius),
        ),
      );

      // Draw the tail (nip) on bottom right
      path.moveTo(size.width - nipWidth - radius, size.height - nipHeight);
      path.lineTo(size.width - nipWidth, size.height - nipHeight);
      path.quadraticBezierTo(
        size.width,
        size.height - nipHeight / 2,
        size.width,
        size.height,
      );
      path.lineTo(size.width - nipWidth - 2, size.height - nipHeight);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(ChatBubbleClipper oldClipper) {
    return oldClipper.direction != direction ||
        oldClipper.radius != radius ||
        oldClipper.nipWidth != nipWidth ||
        oldClipper.nipHeight != nipHeight;
  }
}

/// Direction for the bubble tail
enum BubbleDirection { left, right }

/// WhatsApp-style bubble widget for transaction display
class WhatsAppStyleBubble extends StatelessWidget {
  final String title;
  final double amount;
  final IconData categoryIcon;
  final bool isIncome;
  final VoidCallback? onTap;

  const WhatsAppStyleBubble({
    super.key,
    required this.title,
    required this.amount,
    required this.categoryIcon,
    required this.isIncome,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final direction = isIncome ? BubbleDirection.left : BubbleDirection.right;
    final alignment = isIncome ? Alignment.centerLeft : Alignment.centerRight;
    
    // Colors based on transaction type
    final backgroundColor = isIncome
        ? const Color(0xFFF8F9FA) // Light grey for income
        : const Color(0xFFDCF8C6); // Soft teal/light green for expense
    
    final shadowColor = isIncome
        ? Colors.black.withOpacity(0.08)
        : const Color(0xFF2B7A91).withOpacity(0.12);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.only(
          left: isIncome ? 8 : 48,
          right: isIncome ? 48 : 8,
          top: 6,
          bottom: 6,
        ),
        child: GestureDetector(
          onTap: onTap,
          child: PhysicalModel(
            color: Colors.transparent,
            elevation: 2,
            shadowColor: shadowColor,
            borderRadius: BorderRadius.circular(16),
            child: ClipPath(
              clipper: ChatBubbleClipper(direction: direction),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                ),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title and Category Icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? const Color(0xFF10B981).withOpacity(0.15)
                                  : const Color(0xFF2B7A91).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              categoryIcon,
                              size: 18,
                              color: isIncome
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF2B7A91),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Amount with Euro symbol
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            isIncome ? '+' : '-',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isIncome
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '€${amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isIncome
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      
                      // Timestamp (optional - can be added later)
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(DateTime.now()),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
