import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/member.dart';
import '../routes.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/avatar_stack.dart';

/// Sign In. OWNER: Admire.
///
/// Two ways in, both ending in the same place:
///   1. Email + password, validated like a real form.
///   2. "Continue as" avatars - one tap, no typing.
/// Either way AppState.signIn() stores the session member in SharedPreferences
/// and we land on the Dashboard.
///
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

/// A spacer that works in both directions: `size` wide inside a Row and `size`
/// tall inside a Column, so the same helper reads the same way in either layout.
///
/// It must set **both** dimensions. A `SizedBox(height: n)` has a width of zero,
/// so using one for horizontal spacing silently butts two widgets together.
Widget _gap([double size = 16]) => SizedBox(width: size, height: size);

class _SignInScreenState extends State<SignInScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  /// True while sign-in is in flight; disables the button.
  bool _submitting = false;

  /// The password field can be shown or hidden with the eye icon.
  bool _hidePassword = true;

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
        _toast('No team member matches that email. Pick a member below.');
        return;
      }
      await _enter(state, match);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }


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

  /// The whole screen, top to bottom: brand, headline, form card, divider,
  /// member avatars.
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
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: <Widget>[
            _brand(),
            _gap(28),
            _headline(),
            _gap(16),
            _formCard(state),
            _gap(28),
            _orDivider(),
            _gap(18),
            _memberRow(state),
          ],
        ),
      ),
    );
  }

  // ============================================================== build pieces

  Widget _brand() {
    final Widget logo = Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 36),
    );

    const Widget name = Text(
      'PulseTrack',
      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.ink),
    );

    const Widget tagline = Text(
      'Plan. Track. Deliver.',
      style: TextStyle(fontSize: 14, color: AppColors.muted),
    );

    return Column(
      children: <Widget>[logo, _gap(14), name, _gap(4), tagline],
    );
  }


  Widget _headline() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            TextSpan(
              text: 'Welcome ',
              style: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFFAAAAB5)),
            ),
            TextSpan(
              text: 'back',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
          ],
        ),
        style: TextStyle(fontSize: 34, height: 1.1),
      ),
    );
  }


  Widget _formCard(AppState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.sheetRadius),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _label('Email'),
            _emailField(),
            _gap(16),
            _label('Password'),
            _passwordField(state),
            _gap(22),
            _signInButton(state),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    );
  }

  TextFormField _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        hintText: 'you@team.com',
        prefixIcon: Icon(Icons.mail_outline),
      ),
      validator: _validateEmail,
    );
  }

  TextFormField _passwordField(AppState state) {
    return TextFormField(
      controller: _passwordController,
      obscureText: _hidePassword,
      textInputAction: TextInputAction.done,
      // Pressing "done" on the keyboard = tapping the sign-in button.
      onFieldSubmitted: (_) => _signInWithEmail(state),
      decoration: InputDecoration(
        hintText: 'At least 6 characters',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _hidePassword ? 'Show password' : 'Hide password',
          icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _hidePassword = !_hidePassword),
        ),
      ),
      validator: _validatePassword,
    );
  }


  Widget _signInButton(AppState state) {
    final Widget arrow = Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: _submitting
          ? const Padding(
              padding: EdgeInsets.all(11),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black),
            )
          : const Icon(Icons.arrow_outward, size: 20, color: AppColors.black),
    );

    return Material(
      color: AppColors.black,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _submitting ? null : () => _signInWithEmail(state),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _submitting ? 'Signing in...' : 'Sign in',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              arrow,
            ],
          ),
        ),
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

  Widget _memberRow(AppState state) {
    if (state.members.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'No members found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    }

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: state.members.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 14),
        itemBuilder: (BuildContext context, int index) {
          final Member m = state.members[index];
          return _MemberChoice(
            member: m,
            active: state.currentUser?.id == m.id,
            onTap: () => _enter(state, m),
          );
        },
      ),
    );
  }
}

/// "Continue as" choice.
class _MemberChoice extends StatelessWidget {
  const _MemberChoice({
    required this.member,
    required this.active,
    required this.onTap,
  });

  final Member member;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String firstName = member.name.split(' ').first;

    final Widget avatar = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: MemberAvatar(member: member, size: 56),
    );

    final Widget badge = Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 2),
        ),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      ),
    );

    return Semantics(
      button: true,
      label: 'Continue as ${member.name}',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: <Widget>[
              Stack(children: <Widget>[avatar, if (active) badge]),
              _gap(8),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              Text(
                member.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}