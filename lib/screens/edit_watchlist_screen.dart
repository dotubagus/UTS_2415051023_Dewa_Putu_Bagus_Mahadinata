import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart' show kIdlixRed;
import '../models/watchlist_item.dart';
import '../providers/app_settings_provider.dart';
import '../providers/watchlist_provider.dart';

/// Form edit item watchlist yang sudah tersimpan.
/// Pengguna bisa mengubah rating, catatan, status ditonton, dan pengingat nonton.
class EditWatchlistScreen extends StatefulWidget {
  final WatchlistItem item;
  const EditWatchlistScreen({super.key, required this.item});

  @override
  State<EditWatchlistScreen> createState() => _EditWatchlistScreenState();
}

class _EditWatchlistScreenState extends State<EditWatchlistScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;

  late int _rating;
  late bool _watched;
  bool _saving = false;

  DateTime? _reminderTime;
  bool _reminderLoaded = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.item.rating;
    _watched = widget.item.watched;
    _noteController = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reminderLoaded) {
      _reminderTime =
          context.read<AppSettingsProvider>().getReminder(widget.item.movieId);
      _reminderLoaded = true;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'PILIH TANGGAL NONTON',
      confirmText: 'LANJUT',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime != null
          ? TimeOfDay.fromDateTime(_reminderTime!)
          : TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
      helpText: 'PILIH JAM PENGINGAT',
      confirmText: 'PASANG PENGINGAT',
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _reminderTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pengingat disetel untuk ${pickedDate.day}/${pickedDate.month} jam ${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')} WIB',
        ),
        backgroundColor: Colors.amber.shade800,
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final updated = widget.item.copyWith(
      rating: _rating,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      watched: _watched,
    );

    final error = await context.read<WatchlistProvider>().update(updated);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      // Simpan / update / hapus pengingat di AppSettingsProvider
      final settings = context.read<AppSettingsProvider>();
      if (_watched) {
        // Jika sudah selesai menonton, hapus pengingat otomatis
        settings.removeReminder(widget.item.movieId);
      } else if (_reminderTime != null) {
        settings.setReminder(widget.item.movieId, _reminderTime!);
      } else {
        settings.removeReminder(widget.item.movieId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watchlist berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Watchlist',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul film dalam banner card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.item.posterUrl != null
                            ? Image.network(
                                widget.item.posterUrl!,
                                width: 55,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Switch Status Sudah Ditonton
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: SwitchListTile(
                  activeColor: kIdlixRed,
                  secondary: Icon(
                    _watched
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _watched ? Colors.green : muted,
                  ),
                  title: const Text('Sudah Ditonton',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    _watched
                        ? 'Tandai bahwa kamu sudah menonton film ini'
                        : 'Masih dalam daftar ingin ditonton',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                  value: _watched,
                  onChanged: (v) {
                    setState(() {
                      _watched = v;
                      if (_watched) {
                        // Jika sudah selesai menonton, otomatis hapus jadwal pengingat
                        _reminderTime = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ─── Fitur Pengingat Nonton (Hanya jika belum selesai ditonton) ───
              if (!_watched) ...[
                Card(
                  elevation: 0,
                  color: _reminderTime != null
                      ? Colors.amber.withOpacity(0.12)
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: _reminderTime != null
                        ? BorderSide(color: Colors.amber.shade700, width: 1.2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _reminderTime != null
                            ? Colors.amber.withOpacity(0.25)
                            : muted.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _reminderTime != null
                            ? Icons.notifications_active_rounded
                            : Icons.alarm_add_rounded,
                        color: _reminderTime != null
                            ? Colors.amber.shade800
                            : muted,
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Pengingat Nonton',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _reminderTime != null
                          ? 'Jadwal: ${_reminderTime!.day}/${_reminderTime!.month} jam ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')} WIB'
                          : 'Atur jadwal pengingat untuk menonton film ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: _reminderTime != null
                            ? Colors.amber.shade800
                            : muted,
                        fontWeight: _reminderTime != null
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _reminderTime != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Hapus pengingat',
                            onPressed: () =>
                                setState(() => _reminderTime = null),
                          )
                        : const Icon(Icons.calendar_month_rounded, size: 20),
                    onTap: _pickReminderTime,
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Rating Slider Card
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _watched
                                ? 'Rating Pribadi'
                                : 'Ekspektasi Rating (Opsional)',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  '$_rating / 10',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        activeColor: kIdlixRed,
                        value: _rating.toDouble(),
                        min: 1,
                        max: 10,
                        divisions: 9,
                        label: '$_rating',
                        onChanged: (v) => setState(() => _rating = v.round()),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(10, (i) {
                          return GestureDetector(
                            onTap: () => setState(() => _rating = i + 1),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                i < _rating
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber.shade600,
                                size: 26,
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Input Catatan
              Text(
                'Catatan Film (Opsional)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'Catatan',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty && val.trim().isEmpty) {
                    return 'Catatan tidak boleh hanya spasi.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol Simpan Perubahan
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    _saving ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: kIdlixRed,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 55,
      height: 80,
      color: Colors.grey.shade300,
      child: const Icon(Icons.movie_outlined, color: Colors.grey),
    );
  }
}
