import 'package:flutter/material.dart';

import '../providers/profile_provider.dart';

/// Avatar bulat: foto jika ada, jika tidak inisial dengan gradasi merah.
class ProfileAvatar extends StatelessWidget {
  final ProfileProvider profile;
  final double size;
  const ProfileAvatar({super.key, required this.profile, this.size = 80});

  @override
  Widget build(BuildContext context) {
    if (profile.photo != null) {
      return ClipOval(
        child: Image.memory(
          profile.photo!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE11D2E), Color(0xFF8E0F1A)],
        ),
      ),
      child: Text(
        profile.initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
