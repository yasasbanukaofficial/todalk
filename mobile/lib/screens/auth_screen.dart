import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isRegister = false;
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    if (_isRegister && _nameCtrl.text.trim().isEmpty) return;

    final navigator = Navigator.of(context);
    final notifier = ref.read(authProvider.notifier);
    bool success;

    if (_isRegister) {
      success = await notifier.register(email, password, _nameCtrl.text.trim());
    } else {
      success = await notifier.login(email, password);
    }

    if (success && mounted) {
      navigator.pushReplacementNamed('/home');
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: AppColors.textTertiary),
    filled: false,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.hairline, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.hairline, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.white, width: 1),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 80),
              CustomPaint(
                size: const Size(200, 80),
                painter: _WaveformPainter(),
              ),
              const SizedBox(height: 32),
              const Text(
                'TODALK',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Speak it.\nGet it done.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final success = await ref.read(authProvider.notifier).signInWithGoogle();
                          if (success && mounted) {
                            navigator.pushReplacementNamed('/home');
                          }
                        },
                  icon: const _GoogleG(),
                  label: const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.hairline),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.hairline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or continue with email',
                      style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.hairline)),
                ],
              ),
              const SizedBox(height: 20),
              if (auth.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.priorityHigh.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    auth.error!,
                    style: const TextStyle(color: AppColors.priorityHigh, fontSize: 13),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isRegister = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _isRegister ? AppColors.hairline : AppColors.white,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'LOGIN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                            color: _isRegister ? AppColors.textTertiary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isRegister = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _isRegister ? AppColors.white : AppColors.hairline,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'REGISTER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w500,
                            color: _isRegister ? AppColors.textPrimary : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isRegister)
                TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _inputDecoration('Name'),
                ),
              if (_isRegister) const SizedBox(height: 12),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDecoration('Password'),
              ),
              const SizedBox(height: 20),
              PillButton(
                label: auth.isLoading ? 'PLEASE WAIT...' : (_isRegister ? 'CREATE ACCOUNT' : 'SIGN IN'),
                onTap: auth.isLoading ? null : _submit,
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path();
    final bars = 24;
    final barWidth = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final x = i * barWidth + barWidth / 2;
      final height = (size.height / 2) * (0.2 + 0.8 * (1 - (i % 5) / 5));
      final top = (size.height - height) / 2;
      if (i == 0) path.moveTo(x, top);
      path.lineTo(x, top + height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final cx = w / 2;
    final cy = h / 2;
    final r = h * 0.42;

    final bg = Paint()..color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(cx, cy), h / 2, bg);

    final blue = Paint()..color = const Color(0xFF4285F4);
    final red = Paint()..color = const Color(0xFFEA4335);
    final yellow = Paint()..color = const Color(0xFFFBBC05);
    final green = Paint()..color = const Color(0xFF34A853);

    canvas.drawPath(Path()
      ..moveTo(cx, cy - r)
      ..lineTo(cx, cy)
      ..lineTo(cx + r * 0.85, cy)
      ..close(), blue);

    canvas.drawPath(Path()
      ..moveTo(cx + r * 0.3, cy)
      ..lineTo(cx + r * 0.85, cy - r * 0.5)
      ..lineTo(cx + r * 0.85, cy)
      ..close(), red);

    canvas.drawPath(Path()
      ..moveTo(cx + r * 0.3, cy)
      ..lineTo(cx + r * 0.85, cy + r * 0.5)
      ..lineTo(cx + r * 0.85, cy)
      ..close(), yellow);

    canvas.drawPath(Path()
      ..moveTo(cx, cy)
      ..lineTo(cx + r * 0.3, cy)
      ..lineTo(cx, cy + r)
      ..close(), green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
