import 'package:flutter/material.dart';

import '../data/models/member.dart';
import '../theme/app_colors.dart';


class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.size = 40, this.ring = false});

  final Member member;
  final double size;

  /// A white ring, used when avatars overlap.
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final Color tint = AppColors.avatarPalette[
        member.id.hashCode.abs() % AppColors.avatarPalette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint,
        shape: BoxShape.circle,
        border: ring ? Border.all(color: AppColors.background, width: 2) : null,
      ),
      child: Text(
        member.initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

/// Overlapping avatars.
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.members, this.size = 36, this.max = 4});

  final List<Member> members;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) {
    final int shown = members.length > max ? max : members.length;
    final int extra = members.length - shown;
    final double step = size * 0.7; // how far each avatar is shifted right
    final int slots = shown + (extra > 0 ? 1 : 0);

    final List<Widget> layers = <Widget>[
      for (int i = 0; i < shown; i++)
        Positioned(
          left: i * step,
          child: MemberAvatar(member: members[i], size: size, ring: true),
        ),
      if (extra > 0)
        Positioned(
          left: shown * step,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.black,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 2),
            ),
            child: Text(
              '+$extra',
              style: TextStyle(
                fontSize: size * 0.32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
    ];

    return SizedBox(
      width: slots == 0 ? 0 : (slots - 1) * step + size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: layers),
    );
  }
}