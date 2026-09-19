import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/community_note.dart';
import '../services/community_notes_service.dart';
import '../services/low_signal_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/add_note_bottom_sheet.dart';

class CommunityNotesScreen extends StatefulWidget {
  const CommunityNotesScreen({super.key});

  @override
  State<CommunityNotesScreen> createState() => _CommunityNotesScreenState();
}

class _CommunityNotesScreenState extends State<CommunityNotesScreen> {
  NoteCategory _selectedCategory = NoteCategory.all;
  List<CommunityNote> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    CommunityNotesService.instance.addListener(_onNotesChanged);
    _loadNotes();
  }

  @override
  void dispose() {
    CommunityNotesService.instance.removeListener(_onNotesChanged);
    super.dispose();
  }

  void _onNotesChanged() {
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await CommunityNotesService.instance.getNotes(category: _selectedCategory);
    if (mounted) {
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(NoteCategory category) {
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
    });
    _loadNotes();
  }

  void _openAddNoteDialog() {
    AddNoteBottomSheet.show(context);
  }

  void _showImagePreviewDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imagePath.startsWith('http://') || imagePath.startsWith('https://')
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _buildPhotoFallback(),
                    )
                  : Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => _buildPhotoFallback(),
                    ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(String initial) {
    final colors = [
      const Color(0xFF6C5CE7),
      const Color(0xFF00CEC9),
      const Color(0xFFFF7675),
      const Color(0xFFFD79A8),
      const Color(0xFF6C2BD9),
      const Color(0xFF0984E3),
      const Color(0xFF00B894),
      const Color(0xFFE17055),
    ];
    return colors[initial.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal =
        Theme.of(context).brightness == Brightness.dark || LowSignalController.instance.isLowSignalMode;

    final bgColor = isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg;
    final cardBg = isLowSignal ? const Color(0xFF14141D) : Colors.white;
    final borderColor = isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0);
    final primaryTextColor = isLowSignal ? AppTheme.lowSignalText : const Color(0xFF1E1E2D);
    final subtextColor = isLowSignal ? const Color(0xFFB0B0C0) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isLowSignal ? AppTheme.lowSignalBg : Colors.white,
        foregroundColor: primaryTextColor,
        elevation: isLowSignal ? 0 : 0.5,
        title: Row(
          children: [
            Icon(
              Icons.chat_bubble_rounded,
              color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Community Notes',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _openAddNoteDialog,
              icon: Icon(
                Icons.add_rounded,
                size: 18,
                color: isLowSignal ? Colors.black : Colors.white,
              ),
              label: Text(
                'Add Note',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? Colors.black : Colors.white,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isLowSignal ? const Color(0xFF111116) : Colors.white,
              border: Border(bottom: BorderSide(color: borderColor, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: NoteCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      avatar: Icon(
                        category.icon,
                        size: 15,
                        color: isSelected
                            ? (isLowSignal ? Colors.black : Colors.white)
                            : (isLowSignal ? AppTheme.lowSignalYellow : category.color),
                      ),
                      label: Text(
                        category.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (isLowSignal ? Colors.black : Colors.white)
                              : primaryTextColor,
                        ),
                      ),
                      backgroundColor: isLowSignal ? const Color(0xFF1A1A24) : const Color(0xFFF1F5F9),
                      selectedColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                      side: BorderSide(
                        color: isSelected
                            ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                            : borderColor,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      onSelected: (_) => _onCategorySelected(category),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Community Feed Header summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_notes.length} ${_notes.length == 1 ? "NOTE" : "NOTES"} • ${_selectedCategory.label.toUpperCase()}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Text(
                  'Real-time & anonymous',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                      ),
                    ),
                  )
                : _notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.note_alt_outlined,
                              size: 48,
                              color: subtextColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notes in this category yet',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Be the first to share an anonymous observation!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openAddNoteDialog,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add Note'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isLowSignal
                                    ? AppTheme.lowSignalYellow
                                    : AppTheme.primaryPurple,
                                foregroundColor: isLowSignal ? Colors.black : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
                        itemCount: _notes.length,
                        itemBuilder: (context, index) {
                          final note = _notes[index];
                          return _buildNoteCard(
                            note: note,
                            isLowSignal: isLowSignal,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            primaryTextColor: primaryTextColor,
                            subtextColor: subtextColor,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({
    required CommunityNote note,
    required bool isLowSignal,
    required Color cardBg,
    required Color borderColor,
    required Color primaryTextColor,
    required Color subtextColor,
  }) {
    final cat = note.category;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: isLowSignal
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Avatar, Author, Timestamp, Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Anonymous Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isLowSignal
                      ? AppTheme.lowSignalYellow.withValues(alpha: 0.25)
                      : _getAvatarColor(note.authorInitial).withValues(alpha: 0.18),
                  child: Text(
                    note.authorInitial,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isLowSignal
                          ? AppTheme.lowSignalYellow
                          : _getAvatarColor(note.authorInitial),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Handle & Timestamp & Verified badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.authorHandle,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            note.timeAgo,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: subtextColor,
                            ),
                          ),
                          if (note.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isLowSignal
                                    ? const Color(0xFF00382B)
                                    : const Color(0xFFE6F9F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF00C2A8),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 10.5,
                                    color: Color(0xFF00C2A8),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Community Verified',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF00C2A8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Category Chip Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLowSignal
                        ? const Color(0xFF22222E)
                        : cat.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLowSignal ? AppTheme.lowSignalBorder : cat.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.icon, size: 12, color: isLowSignal ? AppTheme.lowSignalYellow : cat.color),
                      const SizedBox(width: 4),
                      Text(
                        cat == NoteCategory.transit ? 'Transit' : cat.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isLowSignal ? AppTheme.lowSignalYellow : cat.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Location Tag Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLowSignal ? const Color(0xFF1B1B26) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      note.locationTag,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Note Text Content
            Text(
              note.text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                color: primaryTextColor,
              ),
            ),

            // Optional Attached Photo
            if (note.imagePath != null && note.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showImagePreviewDialog(note.imagePath!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      _buildPhotoWidget(note.imagePath!),
                      Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fullscreen, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'View Photo',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoWidget(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPhotoFallback(),
      );
    }

    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return _buildPhotoFallback();
  }

  Widget _buildPhotoFallback() {
    return Container(
      height: 100,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF64748B)),
      ),
    );
  }
}
