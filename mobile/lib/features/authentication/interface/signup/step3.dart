// step3_member.dart  (used internally by Step3 router)
// Shows profile photo + fitness GOALS — rendered when role == member.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:mobile/core/providers/signup_provider.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/navigation/pages.dart';
import '../../../../core/widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';

class Step3Member extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  const Step3Member({super.key, required this.onNext, required this.onPrevious});

  @override
  State<Step3Member> createState() => _Step3MemberState();
}

class _Step3MemberState extends State<Step3Member> {
  File? _profileImage;
  ui.Image? _decodedImage;
  Offset _imageOffset = Offset.zero;
  double _imageScale = 1.0;
  Offset? _dragStart;
  Offset? _dragStartOffset;

  final ImagePicker _picker = ImagePicker();
  final double _avatarSize = 90.0;

  final List<String> _allGoals = [
    'Perte de poids',
    'Prise de masse',
    'Endurance',
    'Force',
    'Souplesse',
    'Santé générale',
  ];

  final Set<String> _selectedGoals = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SignupProvider>(context, listen: false);
    _selectedGoals.addAll(provider.data.goals);
    if (provider.data.originalImagePath != null) {
      _profileImage = File(provider.data.originalImagePath!);
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final decoded = frame.image;

    final minDim =
        decoded.width < decoded.height ? decoded.width : decoded.height;
    final scale = _avatarSize / minDim;
    final dx = (_avatarSize - decoded.width * scale) / 2;
    final dy = (_avatarSize - decoded.height * scale) / 2;

    setState(() {
      _profileImage = File(picked.path);
      _decodedImage = decoded;
      _imageScale = scale;
      _imageOffset = Offset(dx, dy);
    });
  }

  void _onPanStart(DragStartDetails d) {
    _dragStart = d.localPosition;
    _dragStartOffset = _imageOffset;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_decodedImage == null || _dragStart == null) return;
    final delta = d.localPosition - _dragStart!;
    final w = _decodedImage!.width * _imageScale;
    final h = _decodedImage!.height * _imageScale;
    setState(() {
      _imageOffset = Offset(
        (_dragStartOffset!.dx + delta.dx).clamp(_avatarSize - w, 0.0),
        (_dragStartOffset!.dy + delta.dy).clamp(_avatarSize - h, 0.0),
      );
    });
  }

  void _toggleGoal(String goal) {
    setState(() {
      _selectedGoals.contains(goal)
          ? _selectedGoals.remove(goal)
          : _selectedGoals.add(goal);
    });
  }

  Future<File> _getCroppedImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _CropPainter(
      image: _decodedImage!,
      offset: _imageOffset,
      scale: _imageScale,
    ).paint(canvas, Size(_avatarSize, _avatarSize));

    final picture = recorder.endRecording();
    final img =
        await picture.toImage(_avatarSize.toInt(), _avatarSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final file =
        File('${Directory.systemTemp.path}/profile_cropped_member.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _submit() async {
    if (_selectedGoals.isEmpty) {
      setState(
          () => _errorMessage = 'Veuillez sélectionner au moins un objectif');
      return;
    }

    final provider = Provider.of<SignupProvider>(context, listen: false);
    provider.updateGoals(_selectedGoals.toList());

    if (_profileImage != null && _decodedImage != null) {
      final cropped = await _getCroppedImage();
      provider.updateProfileImages(
        original: _profileImage!.path,
        cropped: cropped.path,
      );
    }

    widget.onNext();
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo de profil (optionnel)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          _profileImage != null
              ? 'Glissez pour cadrer votre photo'
              : 'Appuyez sur la photo pour en choisir une',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _profileImage == null ? _pickImage : null,
                  onPanStart: _profileImage != null ? _onPanStart : null,
                  onPanUpdate: _profileImage != null ? _onPanUpdate : null,
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _profileImage != null
                            ? const Color(0xFFE50000)
                            : Colors.grey.shade300,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.grey.shade200,
                        child: _decodedImage != null
                            ? CustomPaint(
                                painter: _CropPainter(
                                  image: _decodedImage!,
                                  offset: _imageOffset,
                                  scale: _imageScale,
                                ),
                              )
                            : Icon(Icons.add_a_photo_outlined,
                                size: 28, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                if (_profileImage != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE50000), shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Choose File',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _profileImage != null
                                  ? _profileImage!.path.split('/').last
                                  : 'No file chosen',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('JPG, PNG, max 5MB',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Inscription',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Créez votre compte FitTech - Étape 3 sur 3',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 24),

              // Progress bar — all 3 filled
              _ProgressBar(filled: 3),
              const SizedBox(height: 32),

              _buildPhotoSection(),
              const SizedBox(height: 28),

              const Text('Objectifs fitness *',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Sélectionnez un ou plusieurs objectifs',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: _allGoals.map((goal) {
                  final isSelected = _selectedGoals.contains(goal);
                  return GestureDetector(
                    onTap: () => _toggleGoal(goal),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE50000)
                            : const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        goal,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!,
                    style: const TextStyle(
                        color: Color(0xFFE50000), fontSize: 13)),
              ],

              const SizedBox(height: 36),
              _NavButtons(onBack: widget.onPrevious, onNext: _submit),
              const SizedBox(height: 20),
              _LoginLink(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Coach variant ───────────────────────────────────────────────────────────

/// Step 3 for coaches — same photo section, but shows SPECIALTIES grid.
class Step3Coach extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  const Step3Coach(
      {super.key, required this.onNext, required this.onPrevious});

  @override
  State<Step3Coach> createState() => _Step3CoachState();
}

class _Step3CoachState extends State<Step3Coach> {
  File? _profileImage;
  ui.Image? _decodedImage;
  Offset _imageOffset = Offset.zero;
  double _imageScale = 1.0;
  Offset? _dragStart;
  Offset? _dragStartOffset;

  final ImagePicker _picker = ImagePicker();
  final double _avatarSize = 90.0;

  final List<String> _allSpecialties = [
    'Spinning',
    'CrossFit',
    'Yoga',
    'Stretching',
    'Cardio',
    'Musculation',
  ];

  final Set<String> _selectedSpecialties = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<SignupProvider>(context, listen: false);
    _selectedSpecialties.addAll(provider.data.specialties);
    if (provider.data.originalImagePath != null) {
      _profileImage = File(provider.data.originalImagePath!);
    }
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final decoded = frame.image;

    final minDim =
        decoded.width < decoded.height ? decoded.width : decoded.height;
    final scale = _avatarSize / minDim;
    final dx = (_avatarSize - decoded.width * scale) / 2;
    final dy = (_avatarSize - decoded.height * scale) / 2;

    setState(() {
      _profileImage = File(picked.path);
      _decodedImage = decoded;
      _imageScale = scale;
      _imageOffset = Offset(dx, dy);
    });
  }

  void _onPanStart(DragStartDetails d) {
    _dragStart = d.localPosition;
    _dragStartOffset = _imageOffset;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_decodedImage == null || _dragStart == null) return;
    final delta = d.localPosition - _dragStart!;
    final w = _decodedImage!.width * _imageScale;
    final h = _decodedImage!.height * _imageScale;
    setState(() {
      _imageOffset = Offset(
        (_dragStartOffset!.dx + delta.dx).clamp(_avatarSize - w, 0.0),
        (_dragStartOffset!.dy + delta.dy).clamp(_avatarSize - h, 0.0),
      );
    });
  }

  void _toggleSpecialty(String s) {
    setState(() {
      _selectedSpecialties.contains(s)
          ? _selectedSpecialties.remove(s)
          : _selectedSpecialties.add(s);
    });
  }

  Future<File> _getCroppedImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _CropPainter(
      image: _decodedImage!,
      offset: _imageOffset,
      scale: _imageScale,
    ).paint(canvas, Size(_avatarSize, _avatarSize));

    final picture = recorder.endRecording();
    final img =
        await picture.toImage(_avatarSize.toInt(), _avatarSize.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final file =
        File('${Directory.systemTemp.path}/profile_cropped_coach.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _submit() async {
    if (_selectedSpecialties.isEmpty) {
      setState(() =>
          _errorMessage = 'Veuillez sélectionner au moins une spécialité');
      return;
    }

    final provider = Provider.of<SignupProvider>(context, listen: false);
    provider.updateSpecialties(_selectedSpecialties.toList());

    if (_profileImage != null && _decodedImage != null) {
      final cropped = await _getCroppedImage();
      provider.updateProfileImages(
        original: _profileImage!.path,
        cropped: cropped.path,
      );
    }

    widget.onNext();
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photo de profil (optionnel)',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          _profileImage != null
              ? 'Glissez pour cadrer votre photo'
              : 'Appuyez sur la photo pour en choisir une',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _profileImage == null ? _pickImage : null,
                  onPanStart: _profileImage != null ? _onPanStart : null,
                  onPanUpdate: _profileImage != null ? _onPanUpdate : null,
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _profileImage != null
                            ? const Color(0xFFE50000)
                            : Colors.grey.shade300,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.grey.shade200,
                        child: _decodedImage != null
                            ? CustomPaint(
                                painter: _CropPainter(
                                  image: _decodedImage!,
                                  offset: _imageOffset,
                                  scale: _imageScale,
                                ),
                              )
                            : Icon(Icons.add_a_photo_outlined,
                                size: 28, color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                ),
                if (_profileImage != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                            color: Color(0xFFE50000), shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Choose File',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _profileImage != null
                                  ? _profileImage!.path.split('/').last
                                  : 'No file chosen',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.grey.shade500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('JPG, PNG, max 5MB',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Inscription',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Créez votre compte FitTech - Étape 3 sur 3',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 24),

              _ProgressBar(filled: 3),
              const SizedBox(height: 32),

              _buildPhotoSection(),
              const SizedBox(height: 28),

              // ── Specialties section (coach-specific) ────────────────────
              const Text('Spécialités *',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Sélectionnez vos spécialités',
                  style: TextStyle(
                      fontSize: 13, color: const Color(0xFFE50000))),
              const SizedBox(height: 14),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: _allSpecialties.map((s) {
                  final isSelected = _selectedSpecialties.contains(s);
                  return GestureDetector(
                    onTap: () => _toggleSpecialty(s),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFE50000)
                            : const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        s,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!,
                    style: const TextStyle(
                        color: Color(0xFFE50000), fontSize: 13)),
              ],

              const SizedBox(height: 36),
              _NavButtons(onBack: widget.onPrevious, onNext: _submit),
              const SizedBox(height: 20),
              _LoginLink(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Router widget ───────────────────────────────────────────────────────────

/// Public-facing Step3 — reads the role from [SignupProvider] and renders
/// [Step3Member] or [Step3Coach] accordingly.
class Step3 extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  const Step3({super.key, required this.onNext, required this.onPrevious});

  @override
  Widget build(BuildContext context) {
    final isCoach = context.watch<SignupProvider>().isCoach;
    if (isCoach) {
      return Step3Coach(onNext: onNext, onPrevious: onPrevious);
    }
    return Step3Member(onNext: onNext, onPrevious: onPrevious);
  }
}

// ─── Shared helpers ──────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int filled; // 1, 2, or 3
  const _ProgressBar({required this.filled});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i < filled;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 5),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFE50000)
                  : const Color(0xFFE8E8E8),
              borderRadius: i == 0
                  ? const BorderRadius.horizontal(left: Radius.circular(3))
                  : i == 2
                      ? const BorderRadius.horizontal(
                          right: Radius.circular(3))
                      : BorderRadius.zero,
            ),
          ),
        );
      }),
    );
  }
}

class _NavButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  const _NavButtons({required this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.grey.shade200,
              side: BorderSide.none,
            ),
            child: const Text('<  Retour',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded( child: Theme( data: Theme.of(context).copyWith( elevatedButtonTheme: ElevatedButtonThemeData( style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric( horizontal: 8, vertical: 10, ), ), ), ), child: PrimaryButton( text: 'Créer mon compte', fontSize: 14, onPressed: onNext, ), ), ),
      ],
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Vous avez déjà un compte ? ',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          children: [
            WidgetSpan(
              child: GestureDetector(
                onTap: () => context.push(Pages.login),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                      color: Color(0xFFE50000),
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Crop painter ────────────────────────────────────────────────────────────

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final Offset offset;
  final double scale;

  const _CropPainter(
      {required this.image, required this.offset, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(
          offset.dx, offset.dy, image.width * scale, image.height * scale),
      Paint(),
    );

    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 0.5;

    for (final t in [1 / 3, 2 / 3]) {
      canvas.drawLine(
          Offset(size.width * t, 0), Offset(size.width * t, size.height), gridPaint);
      canvas.drawLine(
          Offset(0, size.height * t), Offset(size.width, size.height * t), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.image != image || old.offset != offset || old.scale != scale;
}