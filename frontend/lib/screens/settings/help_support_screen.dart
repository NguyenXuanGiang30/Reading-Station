/// HelpSupportScreen - Trợ giúp và hỗ trợ
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'Làm thế nào để thêm sách mới?',
      'answer': 'Bạn có thể thêm sách bằng cách:\n• Quét mã barcode/ISBN trên bìa sách\n• Nhấn nút "+" và nhập thông tin thủ công\n• Tìm kiếm sách trong thư viện online',
      'expanded': false,
    },
    {
      'question': 'Flashcard hoạt động như thế nào?',
      'answer': 'Flashcard sử dụng phương pháp Spaced Repetition (Lặp lại ngắt quãng). Hệ thống sẽ tự động lên lịch ôn tập dựa trên mức độ ghi nhớ của bạn để tối ưu hóa việc học.',
      'expanded': false,
    },
    {
      'question': 'Làm sao để sử dụng OCR?',
      'answer': 'Từ màn hình chi tiết sách, nhấn vào biểu tượng camera để chụp ảnh trang sách. Ứng dụng sẽ tự động nhận dạng văn bản và cho phép bạn lưu thành ghi chú hoặc flashcard.',
      'expanded': false,
    },
    {
      'question': 'Dữ liệu của tôi có an toàn không?',
      'answer': 'Có! Dữ liệu của bạn được mã hóa và lưu trữ an toàn. Bạn cũng có thể sao lưu dữ liệu định kỳ trong phần Cài đặt > Quản lý dữ liệu.',
      'expanded': false,
    },
    {
      'question': 'Làm sao để kết nối với bạn bè?',
      'answer': 'Vào tab Xã hội, nhấn vào biểu tượng tìm kiếm để tìm bạn bè theo email hoặc tên người dùng. Bạn cũng có thể chia sẻ mã QR cá nhân để người khác thêm bạn.',
      'expanded': false,
    },
    {
      'question': 'Focus Mode là gì?',
      'answer': 'Focus Mode giúp bạn tập trung đọc sách bằng cách đếm thời gian và chặn các thông báo gây xao nhãng. Thời gian đọc sẽ được ghi lại vào tiến độ của bạn.',
      'expanded': false,
    },
    {
      'question': 'Làm sao để đặt mục tiêu đọc sách?',
      'answer': 'Vào Cài đặt > Mục tiêu đọc để đặt số sách bạn muốn đọc trong năm. Ứng dụng sẽ theo dõi tiến độ và nhắc nhở bạn.',
      'expanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Trợ giúp & Hỗ trợ',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Quick help
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryStart, AppColors.primaryEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(Icons.support_agent, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Bạn cần trợ giúp?',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chúng tôi luôn sẵn sàng hỗ trợ bạn',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Contact options
          _buildSection(
            title: 'Liên hệ',
            children: [
              _buildContactItem(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: 'support@tramdoc.app',
                onTap: () => _showContactDialog(context, 'Email'),
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 72),
              _buildContactItem(
                icon: Icons.chat_outlined,
                title: 'Chat trực tiếp',
                subtitle: 'Thời gian: 9:00 - 18:00 (T2-T6)',
                onTap: () => _showContactDialog(context, 'Chat'),
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 24),

          // FAQ Section
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'Câu hỏi thường gặp',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),

          ...List.generate(_faqs.length, (index) {
            final faq = _faqs[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: faq['expanded'],
                  onExpansionChanged: (expanded) {
                    setState(() => _faqs[index]['expanded'] = expanded);
                  },
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryStart,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    faq['question'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq['answer'],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.6,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 24),

          // Resources
          _buildSection(
            title: 'Tài liệu hướng dẫn',
            children: [
              _buildResourceItem(
                icon: Icons.book_outlined,
                title: 'Hướng dẫn sử dụng',
                onTap: () => _showResourceDialog(context, 'Hướng dẫn sử dụng'),
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 72),
              _buildResourceItem(
                icon: Icons.play_circle_outline,
                title: 'Video hướng dẫn',
                onTap: () => _showResourceDialog(context, 'Video hướng dẫn'),
                isDark: isDark,
              ),
              const Divider(height: 1, indent: 72),
              _buildResourceItem(
                icon: Icons.update,
                title: 'Nhật ký cập nhật',
                onTap: () => _showResourceDialog(context, 'Nhật ký cập nhật'),
                isDark: isDark,
              ),
            ],
            isDark: isDark,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryStart.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryStart, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  Widget _buildResourceItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.info.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.info, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  void _showContactDialog(BuildContext context, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == 'Email' 
              ? 'Vui lòng gửi email đến support@tramdoc.app' 
              : 'Tính năng chat đang được phát triển',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showResourceDialog(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title sẽ sớm có mặt!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
