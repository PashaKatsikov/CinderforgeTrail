import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/design/app_theme.dart';
import '../core/design/palette.dart';
import '../core/design/typography.dart';
import '../core/services/avatar_service.dart';

/// Круглый аватар с кнопкой редактирования.
///
/// При нажатии показывает bottom-sheet с выбором источника.
/// Вся работа с файлом — через [AvatarService].
class AvatarPicker extends StatefulWidget {
  const AvatarPicker({
    super.key,
    this.size = 90,
    this.initials = 'CF',
  });

  final double size;
  final String initials;

  @override
  State<AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<AvatarPicker> {
  final _service = AvatarService();
  File? _avatar;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final f = await _service.load();
    if (mounted) setState(() => _avatar = f);
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _loading = true);
    try {
      final f = await _service.pick(source);
      if (mounted) setState(() => _avatar = f);
    } catch (_) {
      // пользователь отменил или нет прав — молча игнорируем
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    await _service.delete();
    if (mounted) setState(() => _avatar = null);
  }

  void _showSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Insets.page),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Palette.hairlineStrong,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: Insets.l),
              Text(
                'Change avatar',
                style: AppText.section,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Insets.xl),
              _SheetOption(
                icon: Icons.photo_camera_rounded,
                label: 'Take a photo',
                color: Palette.ember,
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.camera);
                },
              ),
              const SizedBox(height: Insets.m),
              _SheetOption(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                color: Palette.ice,
                onTap: () {
                  Navigator.pop(context);
                  _pick(ImageSource.gallery);
                },
              ),
              if (_avatar != null) ...[
                const SizedBox(height: Insets.m),
                _SheetOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove photo',
                  color: Palette.danger,
                  onTap: () {
                    Navigator.pop(context);
                    _delete();
                  },
                ),
              ],
              const SizedBox(height: Insets.m),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size;
    return GestureDetector(
      onTap: _showSheet,
      child: SizedBox(
        width: d,
        height: d,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _avatar == null ? Palette.emberGradient : null,
                color: _avatar != null ? Palette.surface : null,
                border: Border.all(
                  color: Palette.ember.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Palette.emberDeep.withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: ClipOval(
                child: _loading
                    ? const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : _avatar != null
                        ? Image.file(
                            _avatar!,
                            fit: BoxFit.cover,
                            key: ValueKey(_avatar!.path),
                          )
                        : Center(
                            child: Text(
                              widget.initials,
                              style: AppText.hero.copyWith(
                                fontSize: d * 0.35,
                                color: Colors.white,
                              ),
                            ),
                          ),
              ),
            ),
            // Маленький значок карандаша
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: d * 0.30,
                height: d * 0.30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.surface,
                  border: Border.all(color: Palette.hairlineStrong),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  size: d * 0.155,
                  color: Palette.ember,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.surface.withValues(alpha: 0.85),
      borderRadius: Corners.m,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.l,
            vertical: Insets.m + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: Insets.l),
              Text(label, style: AppText.label),
            ],
          ),
        ),
      ),
    );
  }
}
