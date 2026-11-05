import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/movie.dart';
import '../models/watchlist_item.dart';
import '../providers/app_settings_provider.dart';
import '../providers/watchlist_provider.dart';

/// Form tambah film ke watchlist:
/// - Opsi Pasang Pengingat Nonton (Tanggal & Jam)
/// - Pilihan status "Sudah Ditonton" atau "Belum Ditonton"
/// - Validasi rating jika sudah ditonton
class AddWatchlistScreen extends StatefulWidget {
  final Movie movie;
  const AddWatchlistScreen({super.key, required this.movie});

  @override
  State<AddWatchlistScreen> createState() => _AddWatchlistScreenState();
}

class _AddWatchlistScreenState extends State<AddWatchlistScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();

  int? _rating;
  bool _ratingError = false;
  bool _watched = false; // default false (belum ditonton)
  bool _saving = false;
  DateTime? _reminderTime; // Jadwal pengingat yang dipilih user

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'PILIH TANGGAL NONTON',
      confirmText: 'LANJUT',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
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
    if (_watched && _rating == null) {
      setState(() => _ratingError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karena sudah ditonton, silakan pilih rating (1–10)!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final finalRating = _rating ?? 5;

    final item = WatchlistItem(
      movieId: widget.movie.id,
      title: widget.movie.title,
      posterUrl: widget.movie.posterUrl,
      rating: finalRating,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      watched: _watched,
    );

    final error = await context.read<WatchlistProvider>().add(item);

    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      final settings = context.read<AppSettingsProvider>();
      if (_watched) {
        settings.removeReminder(widget.movie.id);
      } else if (_reminderTime != null) {
        settings.setReminder(widget.movie.id, _reminderTime!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _reminderTime != null
                ? '${widget.movie.title} disimpan & pengingat nonton aktif!'
                : '${widget.movie.title} berhasil disimpan ke watchlist!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah ke Watchlist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Info Film Ringkas ───
              _MovieInfoCard(movie: widget.movie),
              const SizedBox(height: 20),

              // ─── Switch Status: Sudah Ditonton? ───
              Card(
                elevation: 0,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _watched
                          ? Colors.green.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _watched
                          ? Icons.check_circle_rounded
                          : Icons.bookmark_add_outlined,
                      color: _watched ? Colors.green : Colors.grey,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    _watched
                        ? 'Sudah Ditonton'
                        : 'Belum Ditonton (Ingin Ditonton)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _watched
                        ? 'Ya, sudah selesai ditonton'
                        : 'Simpan ke daftar tontonan untuk ditonton nanti',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _watched,
                  onChanged: (v) {
                    setState(() {
                      _watched = v;
                      if (_watched) {
                        _reminderTime = null; // otomatis hapus pengingat jika sudah selesai ditonton
                      } else {
                        _ratingError = false;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 14),

              // ─── Fitur Pasang Pengingat Nonton (Hanya jika belum ditonton) ───
              if (!_watched) ...[
                Card(
                  elevation: 0,
                  color: _reminderTime != null
                      ? Colors.amber.shade50
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _reminderTime != null
                        ? BorderSide(color: Colors.amber.shade300, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _reminderTime != null
                            ? Colors.amber.shade200
                            : Colors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _reminderTime != null
                            ? Icons.notifications_active_rounded
                            : Icons.alarm_add_rounded,
                        color: Colors.amber.shade900,
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Pasang Pengingat Nonton',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _reminderTime != null
                          ? 'Jadwal: ${_reminderTime!.day}/${_reminderTime!.month} jam ${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')} WIB'
                          : 'Atur alarm/jadwal waktu menonton film ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: _reminderTime != null
                            ? Colors.amber.shade900
                            : null,
                        fontWeight: _reminderTime != null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: _reminderTime != null
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Batal pengingat',
                            onPressed: () =>
                                setState(() => _reminderTime = null),
                          )
                        : const Icon(Icons.calendar_month_rounded, size: 20),
                    onTap: _pickReminderTime,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── Rating: Muncul HANYA jika sudah ditonton ───
              if (_watched) ...[
                Card(
                  elevation: 0,
                  color: _ratingError
                      ? Colors.red.shade50
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: _ratingError
                        ? BorderSide(color: Colors.red.shade300, width: 1.5)
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header baris rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beri Rating Film Kamu *',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _ratingError
                                        ? Colors.red.shade700
                                        : null,
                                  ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _rating != null
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade400,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star,
                                      size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    _rating != null
                                        ? '$_rating / 10'
                                        : 'Belum dinilai',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Barisan 10 Bintang interaktif
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            children: List.generate(10, (i) {
                              final starNum = i + 1;
                              final isSelected =
                                  _rating != null && starNum <= _rating!;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _rating = starNum;
                                    _ratingError = false;
                                  });
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Icon(
                                    isSelected
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    color: isSelected
                                        ? Colors.amber.shade600
                                        : Colors.grey.shade400,
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Slider muncul setelah bintang dipilih
                        if (_rating != null)
                          Slider(
                            value: _rating!.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            label: '$_rating',
                            onChanged: (v) {
                              setState(() {
                                _rating = v.round();
                                _ratingError = false;
                              });
                            },
                          )
                        else
                          Center(
                            child: Text(
                              'Sentuh salah satu bintang 1–10 untuk memberi nilai',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: _ratingError
                                    ? Colors.red.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ─── Catatan / Alasan Ingin Menonton ───
              Text(
                _watched ? 'Catatan / Review (Opsional)' : 'Catatan Alasan Ingin Menonton',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 300,
                decoration: InputDecoration(
                  hintText: _watched
                      ? 'Tulis review singkat, kesan, atau adegan favoritmu...'
                      : 'Contoh: Rekomendasi teman, ada aktor favorit, dll...',
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

              // ─── Tombol Simpan ───
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
                      : const Icon(Icons.bookmark_add_rounded),
                  label: Text(
                    _saving ? 'Menyimpan...' : 'Simpan ke Watchlist',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
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
}

// ─── Widget Info Film Ringkas ───
class _MovieInfoCard extends StatelessWidget {
  final Movie movie;
  const _MovieInfoCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: movie.posterUrl != null
                  ? Image.network(
                      movie.posterUrl!,
                      width: 65,
                      height: 95,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(context),
                    )
                  : _placeholder(context),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (movie.releaseDate.length >= 4)
                    Text(
                      'Tahun: ${movie.releaseDate.substring(0, 4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'TMDB: ${movie.voteAverage.toStringAsFixed(1)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      width: 65,
      height: 95,
      color: Colors.grey.shade300,
      child: const Icon(Icons.movie_outlined, color: Colors.grey),
    );
  }
}
