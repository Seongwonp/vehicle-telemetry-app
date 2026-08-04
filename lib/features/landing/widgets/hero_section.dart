import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final Animation<double> reveal;
  final VoidCallback onGetStarted;
  final bool alignLeft;

  const HeroSection({
    required this.reveal,
    required this.onGetStarted,
    this.alignLeft = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final crossAlign =
        alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final textAlign = alignLeft ? TextAlign.left : TextAlign.center;

    return AnimatedBuilder(
      animation: reveal,
      builder: (context, child) => Opacity(
        opacity: reveal.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - reveal.value)),
          child: child,
        ),
      ),
      child: Column(
        crossAxisAlignment: crossAlign,
        children: [
          SizedBox(
            height: 92,
            width: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 로고 아이콘이 가로로 긴 비율이라 원형으로 잘라내는 대신,
                // 뒤에 은은한 원형 글로우만 깔고 아이콘은 잘리지 않게 그 위에 얹는다.
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.18),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
                Image.asset('assets/logo_icon.png',
                    height: 72, fit: BoxFit.contain),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _StatusPill(),
          const SizedBox(height: 18),
          Text(
            '내 차의 상태,\n더 빨리 알아채기',
            textAlign: textAlign,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.3,
              letterSpacing: -0.8,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'TELEMETRIX가 실시간으로 데이터를 모으고\nAI가 이상 징후를 먼저 알려드려요',
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppTheme.textSecondary.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 36),
          _GetStartedButton(onTap: onGetStarted, alignLeft: alignLeft),
        ],
      ),
    );
  }
}

// 계기판이 "켜졌다"는 인상을 주는 작은 상태 배지 — 일반적인 랜딩페이지엔
// 잘 안 쓰는 HUD 어휘(모노스페이스 + 점멸 점)라 제품 정체성을 바로 드러낸다.
class _StatusPill extends StatelessWidget {
  const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'SYSTEM ONLINE',
            style: AppTheme.gaugeNumberStyle(
              fontSize: 11,
              color: AppTheme.primary,
              weight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool alignLeft;
  const _GetStartedButton({required this.onTap, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '시작하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF241503),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: Color(0xFF241503)),
              ],
            ),
          ),
        ),
      ),
    );

    return alignLeft ? button : Center(child: button);
  }
}
