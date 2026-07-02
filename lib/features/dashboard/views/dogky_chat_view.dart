import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/ai_assistant_controller.dart';
import '../models/ai_chat_message.dart';
import '../widgets/dogky_video_player.dart';

class DogkyChatView extends StatefulWidget {
  const DogkyChatView({super.key});

  @override
  State<DogkyChatView> createState() => _DogkyChatViewState();
}

class _DogkyChatViewState extends State<DogkyChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(AiAssistantController controller) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    controller.sendUserMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AiAssistantController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Tự động cuộn xuống khi có tin nhắn mới hoặc bot đang tải
    if (controller.isLoading) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F52BA),
        foregroundColor: Colors.white,
        elevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bác sĩ Dogky',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Đang trực khám · Tư vấn 24/7',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            controller.toggleChat(false);
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Xóa lịch sử chat',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xóa hội thoại?'),
                  content: const Text('Bạn có chắc chắn muốn xóa toàn bộ lịch sử trò chuyện với Dogky không?'),
                  actions: [
                    TextButton(
                      child: const Text('Hủy'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: const Text('Xóa sạch', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        controller.clearChatHistory();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Khung chứa hội thoại
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: controller.messages.length,
              itemBuilder: (context, index) {
                final msg = controller.messages[index];
                return _buildMessageItem(msg, controller, isDark);
              },
            ),
          ),

          // Typing Indicator
          if (controller.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Text('Dogky đang nghĩ ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        _buildDot(0),
                        _buildDot(1),
                        _buildDot(2),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Gợi ý câu hỏi nhanh (Quick options)
          if (controller.messages.length <= 2 && !controller.isLoading)
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildQuickActionChip('Đặt lịch khám', controller),
                  _buildQuickActionChip('Tư vấn triệu chứng', controller),
                  _buildQuickActionChip('Xem đơn thuốc gần nhất', controller),
                  _buildQuickActionChip('Xem hóa đơn viện phí', controller),
                  _buildQuickActionChip('Xem hồ sơ bệnh án', controller),
                ],
              ),
            ),

          // Thanh nhập tin nhắn
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(controller),
                      decoration: InputDecoration(
                        hintText: 'Hỏi Dogky về triệu chứng, đặt lịch...',
                        hintStyle: const TextStyle(fontSize: 13),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _sendMessage(controller),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F52BA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQuickActionChip(String text, AiAssistantController controller) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        onPressed: () {
          controller.sendUserMessage(text);
          _scrollToBottom();
        },
      ),
    );
  }

  Widget _buildMessageItem(AiChatMessage msg, AiAssistantController controller, bool isDark) {
    final isMe = msg.sender == 'user';
    final primaryColor = const Color(0xFF0F52BA);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              width: 32,
              height: 32,
              child: const DogkyVideoPlayer(size: 32.0),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Text Message Bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? primaryColor
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
                      bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: isDark ? Colors.transparent : Colors.grey.shade100),
                    boxShadow: isMe
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      height: 1.45,
                    ),
                  ),
                ),

                // 1. RENDER TABLE DATA TEMPLATE (Bệnh án, đơn thuốc, hóa đơn)
                if (msg.tableRows != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: msg.tableRows!.map((row) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 90,
                                child: Text(
                                  row.label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  row.value,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // 2. RENDER CHOOSE SPECIALTY TEMPLATE (Grid 2 cột)
                if (msg.specialtySelector != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 280,
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: msg.specialtySelector!.length,
                      itemBuilder: (context, index) {
                        final opt = msg.specialtySelector![index];
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: primaryColor,
                            elevation: 0.5,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                          ),
                          onPressed: () => controller.selectSpecialty(opt.specialtyId, opt.specialtyName),
                          child: Text(
                            opt.specialtyName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),

                // 3. RENDER CHOOSE DOCTOR TEMPLATE (Avatar + Tên bác sĩ + Giá khám)
                if (msg.doctorSelector != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 280,
                    child: Column(
                      children: msg.doctorSelector!.map((doc) {
                        return Card(
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              backgroundColor: primaryColor.withOpacity(0.1),
                              child: Icon(Icons.person_rounded, color: primaryColor),
                            ),
                            title: Text(doc.doctorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Giá khám: ${_formatCurrency(doc.examFee)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => controller.selectDoctor(
                              doc.doctorId,
                              doc.doctorName,
                              doc.examFee,
                              controller.activeBooking!.specialtyId!,
                              controller.activeBooking!.specialtyName!,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                // 4. RENDER CHOOSE TIME SLOT TEMPLATE (Horizontal / Wrapped Chips)
                if (msg.timeSlotSelector != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 280,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: msg.timeSlotSelector!.map((slot) {
                        return ChoiceChip(
                          label: Text(slot, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          selected: false,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          onSelected: (_) => controller.selectTimeSlot(slot),
                        );
                      }).toList(),
                    ),
                  ),

                // 5. RENDER CONFIRM BOOKING TEMPLATE (Hóa đơn tóm tắt và nhập lý do khám)
                if (msg.bookingConfirm != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 280,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Phiếu Đăng Ký Lịch Khám', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F52BA))),
                        const Divider(height: 16),
                        _buildConfirmRow('Chuyên khoa:', msg.bookingConfirm!.specialtyName),
                        _buildConfirmRow('Bác sĩ:', msg.bookingConfirm!.doctorName),
                        _buildConfirmRow('Ngày khám:', msg.bookingConfirm!.dateText),
                        _buildConfirmRow('Giờ khám:', msg.bookingConfirm!.slotTime),
                        _buildConfirmRow('Phí khám:', _formatCurrency(msg.bookingConfirm!.fee), isOrange: true),
                        const SizedBox(height: 12),
                        
                        // Ô nhập lý do khám trực quan
                        TextField(
                          controller: _reasonController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Nhập lý do khám (ví dụ: đau bụng...)',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => controller.cancelBooking(),
                              child: const Text('Hủy bỏ', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                controller.confirmBooking(_reasonController.text);
                                _reasonController.clear();
                              },
                              child: const Text('Xác nhận', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // 6. RENDER BOOKING SUCCESS TEMPLATE
                if (msg.bookingSuccess != null)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 280,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          'Đặt Lịch Thành Công!',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        _buildConfirmRow('Mã lịch hẹn:', msg.bookingSuccess!.appointmentCode),
                        _buildConfirmRow('Phí khám:', _formatCurrency(msg.bookingSuccess!.fee), isOrange: true),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isOrange = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isOrange ? Colors.orange : null,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      buffer.write(str[i]);
      final reverseIdx = str.length - 1 - i;
      if (reverseIdx > 0 && reverseIdx % 3 == 0) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} ₫';
  }
}
