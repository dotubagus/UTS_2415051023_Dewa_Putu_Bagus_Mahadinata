import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../main.dart' show kIdlixRed;
import '../providers/profile_provider.dart';
import '../widgets/profile_avatar.dart';

/// Edit profil: hanya ganti nama dan foto profil.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  Uint8List? _newPhoto;
  bool _removePhoto = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: context.read<ProfileProvider>().name);
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      // Diperkecil agar ringan disimpan lokal
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _newPhoto = bytes;
        _removePhoto = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih foto')),
      );
    }
  }

  Future<void> _save() async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await context.read<ProfileProvider>().save(
          name: _name.text,
          photo: _newPhoto,
          removePhoto: _removePhoto,
        );
    messenger.showSnackBar(const SnackBar(content: Text('Profil diperbarui')));
    nav.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final theme = Theme.of(context);

    // Pratinjau: pakai foto baru / hapus / foto lama
    final preview = _ProfilePreview(
      name: _name.text,
      photo: _removePhoto ? null : (_newPhoto ?? profile.photo),
    );
    final hasPhoto = !_removePhoto && (_newPhoto ?? profile.photo) != null;
    final canSave = _name.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      ProfileAvatar(profile: preview, size: 108),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kIdlixRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(Icons.photo_camera_outlined,
                              size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _pickPhoto,
                    child: const Text('Ganti foto',
                        style: TextStyle(color: kIdlixRed)),
                  ),
                  if (hasPhoto)
                    TextButton(
                      onPressed: () => setState(() {
                        _newPhoto = null;
                        _removePhoto = true;
                      }),
                      child: Text('Hapus',
                          style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('NAMA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 40,
                decoration: const InputDecoration(hintText: 'Nama kamu'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: canSave ? _save : null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ProfileProvider ringan khusus pratinjau (tidak menyimpan apa pun).
class _ProfilePreview extends ProfileProvider {
  final String _n;
  final Uint8List? _p;
  _ProfilePreview({required String name, Uint8List? photo})
      : _n = name,
        _p = photo;

  @override
  String get name => _n;
  @override
  Uint8List? get photo => _p;
}
