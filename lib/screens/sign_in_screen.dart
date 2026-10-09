import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Sign In. OWNER: Admire.
///
/// Two ways in, both ending in the same place:
///   1. Email + password, validated like a real form.
///   2. "Continue as" member cards - one tap, no typing.
/// Either way AppState.signIn() stores the session member in SharedPreferences
/// and we land on the Dashboard.
///
///
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

Widget _gap([double height = 16]) => SizedBox(height: height);

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// True while sign-in is in flight; disables the button.
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================================================ validation

  String? _validateEmail(String? value) {
    final String email = (value ?? '').trim();

    if (email.isEmpty) {
      return 'Email is required.';
    }

    final int at = email.indexOf('@');
    final bool hasLocalPart = at > 0;
    final bool hasDomain = at >= 0 &&
        at < email.length - 1 &&
        email.substring(at).contains('.');

    if (!hasLocalPart || !hasDomain) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  // ==================================================================== actions

  Future<void> _signInWithEmail(AppState state) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true); // <- triggers a rebuild
    try {
      final String query = _emailController.text.trim().toLowerCase();
      final Member? match = _findByEmail(state, query);

      if (match == null) {
        _toast('No team member matches that email. Use a card below.');
        return;
      }
      await _enter(state, match);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  /// The seed data ships without emails, so we also accept a member whose
  /// NAME matches what was typed ("John Doe"). Delete the second loop once
  /// real emails are seeded.
  Member? _findByEmail(AppState state, String query) {
    for (final Member m in state.members) {
      if (m.email.toLowerCase() == query) {
        return m;
      }
    }
    for (final Member m in state.members) {
      if (m.name.toLowerCase() == query) {
        return m;
      }
    }
    return null;
  }

  /// Remember the session, go to the Dashboard.
  Future<void> _enter(AppState state, Member member) async {
    await state.signIn(member); // stores the member id in SharedPreferences
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.dashboard);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ====================================================================== build

  /// The whole screen, top to bottom: brand, form, divider, member cards.
  @override
  Widget build(BuildContext context) {
    final AppState state = context.watch<AppState>();

    if (state.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          children: <Widget>[
            _brand(),
            _gap(32),
            _form(state),
            _gap(28),
            _orDivider(),
            _gap(16),
            ..._memberCards(state),
          ],
        ),
      ),
    );
  }

  // ============================================================== build pieces

  Widget _brand() {
    final Widget logo = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.monitor_heart, color: Colors.white, size: 32),
    );

    const Widget name = Text(
      'PulseTrack',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );

    const Widget tagline = Text(
      "Stay on top of your team's SLAs.",
      style: TextStyle(fontSize: 14, color: AppColors.muted),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[logo, _gap(16), name, _gap(6), tagline],
    );
  }

  Form _form(AppState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _emailField(),
          _gap(14),
          _passwordField(state),
          _gap(20),
          _signInButton(state),
        ],
      ),
    );
  }

  TextFormField _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Email',
        hintText: 'you@team.com',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: _validateEmail,
    );
  }

  TextFormField _passwordField(AppState state) {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      textInputAction: TextInputAction.done,
      // Pressing "done" on the keyboard = tapping the sign-in button.
      onFieldSubmitted: (_) => _signInWithEmail(state),
      decoration: const InputDecoration(
        labelText: 'Password',
        hintText: 'At least 6 characters',
        prefixIcon: Icon(Icons.lock_outline),
      ),
      validator: _validatePassword,
    );
  }

  Widget _signInButton(AppState state) {
    final Widget label = Text(_submitting ? 'Signing in...' : 'Sign in');
    final Widget icon = _submitting
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.login);

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _submitting ? null : () => _signInWithEmail(state),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: icon,
        label: label,
      ),
    );
  }

  Widget _orDivider() {
    const Widget caption = Text(
      'OR CONTINUE AS',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1,
        color: AppColors.muted,
      ),
    );

    const Widget captionPadded = Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: caption,
    );

    return const Row(
      children: <Widget>[
        Expanded(child: Divider()),
        captionPadded,
        Expanded(child: Divider()),
      ],
    );
  }

  List<Widget> _memberCards(AppState state) {
    if (state.members.isEmpty) {
      return const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text(
            'No members found.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
      ];
    }

    // Collection-for: builds one card per member, right inside the list.
    return <Widget>[
      for (final Member m in state.members)
        _MemberCard(member: m, onTap: () => _enter(state, m)),
    ];
  }
}

/// One "Continue as" card: avatar, name + role, chevron.
class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.onTap});

  final Member member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget avatar = CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Text(
        member.initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );

    final Widget details = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          _gap(2),
          Text(
            member.role,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );

    final Widget row = Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          avatar,
          _gap(12),
          details,
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: row,
        ),
      ),
    );
  }
}