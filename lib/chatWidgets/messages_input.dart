import 'package:flutter/material.dart';

class MessageInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendMessage;
  final VoidCallback onAttachImage;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onAttachImage,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _isTyping = false;

  void _onMessageChanged(String value) {
    final isNowTyping = value.trim().isNotEmpty;
    if (isNowTyping != _isTyping) {
      setState(() => _isTyping = isNowTyping);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add_photo_alternate,
                color: Colors.grey[600],
                size: 26,
              ),
              onPressed: widget.onAttachImage,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: widget.controller,
                  onChanged: _onMessageChanged,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => widget.onSendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    suffixIcon: _isTyping
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              widget.controller.clear();
                              setState(() => _isTyping = false);
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _isTyping ? widget.onSendMessage : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isTyping ? const Color(0xFF8B5CF6) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send,
                  color: _isTyping ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}