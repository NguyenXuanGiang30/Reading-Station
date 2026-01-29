/// TermsScreen - Điều khoản sử dụng
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/colors.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Điều khoản sử dụng',
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
          // Last updated
          Center(
            child: Text(
              'Cập nhật lần cuối: 01/01/2024',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),

          const SizedBox(height: 24),

          _buildSection(
            title: '1. Chấp nhận điều khoản',
            content: 'Bằng việc sử dụng ứng dụng Trạm Đọc, bạn đồng ý tuân thủ các điều khoản và điều kiện được nêu trong tài liệu này. Nếu bạn không đồng ý với bất kỳ điều khoản nào, vui lòng ngừng sử dụng ứng dụng.',
            isDark: isDark,
          ),

          _buildSection(
            title: '2. Tài khoản người dùng',
            content: '''• Bạn phải cung cấp thông tin chính xác khi đăng ký tài khoản.
• Bạn có trách nhiệm bảo mật thông tin đăng nhập của mình.
• Bạn chịu trách nhiệm về mọi hoạt động diễn ra trên tài khoản của mình.
• Chúng tôi có quyền tạm ngưng hoặc chấm dứt tài khoản vi phạm điều khoản.''',
            isDark: isDark,
          ),

          _buildSection(
            title: '3. Quyền sở hữu trí tuệ',
            content: '''• Nội dung ứng dụng (logo, giao diện, mã nguồn) thuộc quyền sở hữu của Trạm Đọc.
• Bạn giữ quyền sở hữu với các ghi chú, flashcard và nội dung bạn tạo.
• Bạn không được sao chép, phân phối hoặc sửa đổi ứng dụng mà không có sự cho phép.''',
            isDark: isDark,
          ),

          _buildSection(
            title: '4. Quy tắc cộng đồng',
            content: '''Khi sử dụng tính năng xã hội, bạn cam kết:
• Không đăng nội dung vi phạm pháp luật, thô tục hoặc xúc phạm.
• Tôn trọng quyền riêng tư của người dùng khác.
• Không spam hoặc quấy rối người dùng khác.
• Không chia sẻ thông tin sai lệch hoặc gây hiểu lầm.''',
            isDark: isDark,
          ),

          _buildSection(
            title: '5. Giới hạn trách nhiệm',
            content: '''• Trạm Đọc được cung cấp "nguyên trạng" mà không có bảo đảm nào.
• Chúng tôi không chịu trách nhiệm về việc mất dữ liệu do lỗi kỹ thuật.
• Chúng tôi khuyến khích bạn thường xuyên sao lưu dữ liệu.''',
            isDark: isDark,
          ),

          _buildSection(
            title: '6. Bảo mật dữ liệu',
            content: 'Việc thu thập và xử lý dữ liệu cá nhân của bạn được thực hiện theo Chính sách bảo mật của chúng tôi. Chúng tôi cam kết bảo vệ thông tin của bạn và không chia sẻ với bên thứ ba mà không có sự đồng ý.',
            isDark: isDark,
          ),

          _buildSection(
            title: '7. Thay đổi điều khoản',
            content: 'Chúng tôi có quyền cập nhật điều khoản này theo thời gian. Các thay đổi quan trọng sẽ được thông báo qua ứng dụng. Việc tiếp tục sử dụng sau khi thay đổi đồng nghĩa với việc bạn chấp nhận các điều khoản mới.',
            isDark: isDark,
          ),

          _buildSection(
            title: '8. Liên hệ',
            content: 'Nếu bạn có câu hỏi về điều khoản sử dụng, vui lòng liên hệ:\n\n📧 Email: support@tramdoc.app\n🌐 Website: https://tramdoc.app',
            isDark: isDark,
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.6,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
