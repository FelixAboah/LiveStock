import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'app_widgets.dart';
import 'farm_store.dart';

class VetScreen extends StatefulWidget {
  const VetScreen({super.key, required this.store});

  final FarmStore store;

  @override
  State<VetScreen> createState() => _VetScreenState();
}

class _VetScreenState extends State<VetScreen> {
  final _picker = ImagePicker();
  final _observations = TextEditingController();
  final List<XFile> _photos = [];
  String? _flockId;
  bool _urgent = false;
  String? _status;

  @override
  void dispose() {
    _observations.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      if (source == ImageSource.gallery) {
        final selected = await _picker.pickMultiImage(imageQuality: 80);
        setState(() {
          for (final photo in selected) {
            if (_photos.length >= 5) break;
            _photos.add(photo);
          }
          _status = selected.isEmpty ? null : '${_photos.length} of 5 photos selected.';
        });
      } else {
        if (_photos.length >= 5) {
          setState(() => _status = 'You can attach up to five photos.');
          return;
        }
        final photo = await _picker.pickImage(source: source, imageQuality: 80);
        if (photo != null) setState(() { _photos.add(photo); _status = '${_photos.length} of 5 photos selected.'; });
      }
    } catch (error) {
      if (mounted) setState(() => _status = 'Could not open photos. Check device permissions and try again.');
    }
  }

  Future<void> _saveReport() async {
    if (_observations.text.trim().isEmpty) {
      setState(() => _status = 'Add a short description of what you observed.');
      return;
    }
    final flock = widget.store.flocks.where((item) => item['id'] == _flockId).firstOrNull;
    await widget.store.addHealthReport({
      'flockId': _flockId,
      'flockName': flock?['name'] ?? 'Unassigned flock',
      'observations': _observations.text.trim(),
      'urgent': _urgent,
      'photoNames': _photos.map((photo) => photo.name).toList(),
      'date': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    setState(() => _status = 'Case notes saved on this device. Photos remain selected until you leave this screen.');
    _observations.clear();
  }

  Future<void> _shareWithVet() async {
    final flock = widget.store.flocks.where((item) => item['id'] == _flockId).firstOrNull;
    final text = 'Poultry health concern\nFlock: ${flock?['name'] ?? 'Unassigned'}\nUrgent signs marked: ${_urgent ? 'Yes' : 'No'}\nObservations: ${_observations.text.trim().isEmpty ? 'See saved case notes' : _observations.text.trim()}';
    try {
      final result = await SharePlus.instance.share(ShareParams(text: text, files: _photos.isEmpty ? null : List<XFile>.of(_photos)));
      if (mounted && result.status == ShareResultStatus.unavailable) {
        setState(() => _status = 'Sharing is not available here. Share the saved case notes manually with your vet.');
      }
    } catch (_) {
      if (mounted) setState(() => _status = 'Could not open sharing. Your case notes remain saved on this device.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final flocks = widget.store.flocks;
        if (_flockId == null && flocks.isNotEmpty) _flockId = flocks.first['id'].toString();
        return ListView(
          padding: const EdgeInsets.fromLTRB(17, 18, 17, 30),
          children: [
            const PageHeading(eyebrow: 'CARE & SUPPORT', title: 'Health & vets', subtitle: 'Record observations and prepare a clear report for veterinary support.'),
            const SizedBox(height: 15),
            LiveStockPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(title: 'Describe a concern', subtitle: 'LiveStock does not diagnose illness or prescribe treatment.'),
                  const SizedBox(height: 13),
                  if (flocks.isEmpty)
                    const Text('Add a flock before creating a health report.')
                  else
                    DropdownButtonFormField<String>(
                      key: ValueKey('health-flock-${_flockId ?? ''}'),
                      initialValue: _flockId,
                      decoration: const InputDecoration(labelText: 'Flock'),
                      items: flocks.map((flock) => DropdownMenuItem(value: flock['id'].toString(), child: Text(flock['name'].toString()))).toList(),
                      onChanged: (value) => setState(() => _flockId = value),
                    ),
                  const SizedBox(height: 11),
                  TextField(controller: _observations, maxLines: 4, maxLength: 500, decoration: const InputDecoration(labelText: 'What have you noticed?', hintText: 'Behavior, appetite, breathing, droppings, egg production...')),
                  const SizedBox(height: 4),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _urgent,
                    title: const Text('Severe signs observed'),
                    subtitle: const Text('Sudden deaths, breathing difficulty, inability to stand, or rapid spread'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) => setState(() => _urgent = value ?? false),
                  ),
                  if (_urgent)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(color: const Color(0xFFFFF1E8), borderRadius: BorderRadius.circular(8)),
                      child: const Text('Contact a qualified veterinary professional or your district veterinary office promptly. Do not start medication based only on app guidance.', style: TextStyle(color: Color(0xFF834C2D), height: 1.4)),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined, size: 18), label: const Text('Take photo')),
                      OutlinedButton.icon(onPressed: () => _pickPhoto(ImageSource.gallery), icon: const Icon(Icons.photo_library_outlined, size: 18), label: const Text('Choose photos')),
                    ],
                  ),
                  if (_photos.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 105,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => _PhotoPreview(photo: _photos[index], onRemove: () => setState(() => _photos.removeAt(index))),
                      ),
                    ),
                  ],
                  if (_status != null) ...[
                    const SizedBox(height: 8),
                    Text(_status!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.forest)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: FilledButton(onPressed: flocks.isEmpty ? null : _saveReport, child: const Text('Save case notes'))),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(onPressed: _shareWithVet, tooltip: 'Share report with vet', icon: const Icon(Icons.ios_share_rounded)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const LocalOnlyNote(message: 'Notes stay on this device. Photos are shared only when you choose Share; no vet directory or cloud upload is connected yet.'),
            const SizedBox(height: 20),
            const SectionHeading(title: 'Recent case notes'),
            const SizedBox(height: 8),
            if (widget.store.healthReports.isEmpty)
              const LiveStockPanel(child: EmptyHint(icon: Icons.health_and_safety_outlined, title: 'No case notes yet', detail: 'Your saved observations will appear here.'))
            else
              ...widget.store.healthReports.take(8).map((report) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LiveStockPanel(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(report['flockName'].toString(), style: const TextStyle(fontWeight: FontWeight.w800)),), if (report['urgent'] == true) const Icon(Icons.warning_amber_rounded, color: LiveStockColors.coral, size: 18)]), const SizedBox(height: 4), Text(report['observations'].toString(), style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4)), const SizedBox(height: 5), Text('${formatFarmDate(report['date'])} · ${(report['photoNames'] as List? ?? []).length} photo(s)', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: LiveStockColors.muted))]),
                    ),
                  )),
          ],
        );
      },
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.onRemove});

  final XFile photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: photo.readAsBytes(),
      builder: (context, snapshot) => Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(7),
            child: snapshot.hasData
                ? Image.memory(snapshot.data!, width: 104, height: 104, fit: BoxFit.cover)
                : Container(width: 104, height: 104, color: LiveStockColors.canvas, alignment: Alignment.center, child: const Icon(Icons.image_outlined, color: LiveStockColors.muted)),
          ),
          Positioned(right: 3, top: 3, child: IconButton.filledTonal(onPressed: onRemove, tooltip: 'Remove photo', iconSize: 16, visualDensity: VisualDensity.compact, icon: const Icon(Icons.close))),
        ],
      ),
    );
  }
}