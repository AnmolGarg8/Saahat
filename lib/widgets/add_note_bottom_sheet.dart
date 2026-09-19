import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/community_note.dart';
import '../services/community_notes_service.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';

/// Modal bottom sheet form for creating a new anonymous crowdsourced note.
class AddNoteBottomSheet extends StatefulWidget {
  const AddNoteBottomSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: isLowSignal ? Colors.black.withValues(alpha: 0.85) : Colors.black54,
      builder: (_) => const AddNoteBottomSheet(),
    );
  }

  @override
  State<AddNoteBottomSheet> createState() => _AddNoteBottomSheetState();
}

class _AddNoteBottomSheetState extends State<AddNoteBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedCategoryId = 'streetlights';
  String? _pickedImagePath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _pickedImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach image: $e'),
            backgroundColor: AppTheme.sosCoralRed,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attach Photo',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLowSignal
                        ? AppTheme.lowSignalYellow.withValues(alpha: 0.15)
                        : AppTheme.primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                  ),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E293B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLowSignal
                        ? AppTheme.lowSignalYellow.withValues(alpha: 0.15)
                        : AppTheme.accentTeal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.accentTeal,
                  ),
                ),
                title: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E293B),
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final randomNum = 100 + Random().nextInt(899);
    final initials = ['A', 'R', 'S', 'M', 'P', 'V', 'K', 'T'];
    final initial = initials[Random().nextInt(initials.length)];

    final newNote = CommunityNote(
      id: 'user-note-${DateTime.now().millisecondsSinceEpoch}',
      authorInitial: initial,
      authorHandle: 'Traveler #$randomNum',
      categoryId: _selectedCategoryId,
      locationTag: _locationController.text.trim(),
      text: _textController.text.trim(),
      imagePath: _pickedImagePath,
      isVerified: false,
      timestamp: DateTime.now(),
    );

    await CommunityNotesService.instance.addNote(newNote);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Note posted anonymously to community feed ✓',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF00C2A8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.88;

    final bgColor = isLowSignal ? AppTheme.lowSignalBg : Colors.white;
    final headerBg = isLowSignal ? const Color(0xFF141414) : const Color(0xFFF9F7FE);
    final borderColor = isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0);
    final textColor = isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E293B);

    final categories = NoteCategory.values.where((c) => c != NoteCategory.all).toList();

    return Container(
      height: sheetHeight,
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: isLowSignal ? Border.all(color: AppTheme.lowSignalBorder, width: 2) : null,
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isLowSignal
                        ? AppTheme.lowSignalYellow.withValues(alpha: 0.2)
                        : AppTheme.primaryPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.add_comment_rounded,
                      color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add a Community Note',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '100% anonymous • Objective observations only',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isLowSignal ? const Color(0xFFB0B0C0) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector label
                    Text(
                      'CATEGORY',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isLowSignal ? const Color(0xFF1C1C24) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          dropdownColor: isLowSignal ? const Color(0xFF1C1C24) : Colors.white,
                          icon: Icon(
                            Icons.arrow_drop_down_rounded,
                            color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                          ),
                          items: categories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat.id,
                              child: Row(
                                children: [
                                  Icon(cat.icon, size: 18, color: cat.color),
                                  const SizedBox(width: 10),
                                  Text(
                                    cat.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategoryId = val);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Location tag input
                    Text(
                      'LOCATION TAG',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationController,
                      style: GoogleFonts.poppins(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        hintText: 'e.g. Hauz Khas Metro Gate 2 / Saket Mall Road',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isLowSignal ? const Color(0xFF888888) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                        ),
                        filled: true,
                        fillColor: isLowSignal ? const Color(0xFF1C1C24) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                            width: 1.8,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please specify a location tag';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Note text input
                    Text(
                      'OBSERVATION NOTE',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _textController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 13, color: textColor),
                      decoration: InputDecoration(
                        hintText:
                            'Describe condition objectively (e.g. Streetlights working, steady footfall, active transit kiosk). No area stigma.',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 12.5,
                          height: 1.4,
                          color: isLowSignal ? const Color(0xFF888888) : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isLowSignal ? const Color(0xFF1C1C24) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                            width: 1.8,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 8) {
                          return 'Please enter at least 8 characters describing conditions';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    // Photo attachment section
                    Text(
                      'ATTACH PHOTO (OPTIONAL)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_pickedImagePath == null)
                      InkWell(
                        onTap: _showImageSourceDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                          decoration: BoxDecoration(
                            color: isLowSignal ? const Color(0xFF1C1C24) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: borderColor,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to upload photo from Gallery or Camera',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isLowSignal ? AppTheme.lowSignalText : const Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Help fellow travelers verify lighting and conditions visually',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isLowSignal ? const Color(0xFF888888) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor, width: 1.5),
                              image: DecorationImage(
                                image: FileImage(File(_pickedImagePath!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setState(() => _pickedImagePath = null);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black87,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Photo attached ✓',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                          foregroundColor: isLowSignal ? Colors.black : Colors.white,
                          elevation: isLowSignal ? 0 : 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 18,
                                    color: isLowSignal ? Colors.black : Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Post Anonymous Note',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isLowSignal ? Colors.black : Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
