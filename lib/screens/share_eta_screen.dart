import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/trusted_contact.dart';
import '../services/eta_sharing_service.dart';
import '../services/low_signal_controller.dart';
import '../services/offline_cache_service.dart';
import '../theme/app_theme.dart';
import '../widgets/arrived_safely_dialog.dart';

class ShareEtaScreen extends StatefulWidget {
  const ShareEtaScreen({super.key});

  @override
  State<ShareEtaScreen> createState() => _ShareEtaScreenState();
}

class _ShareEtaScreenState extends State<ShareEtaScreen> {
  final List<TrustedContact> _contacts = TrustedContact.defaultContacts;
  late TrustedContact _selectedContact;

  String _selectedRouteName = 'Main Arterial Route';
  int _durationMinutes = 25;
  late TimeOfDay _expectedArrival;

  bool _isSharingActive = false;

  final List<String> _availableRoutes = [
    'Main Arterial Route',
    'Metro Line & Well-lit Boulevard',
    'South Ext Ring Corridor',
  ];

  @override
  void initState() {
    super.initState();
    _selectedContact = _contacts.first; // Mom / Anjali by default
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: _durationMinutes));
    _expectedArrival = TimeOfDay(hour: arrival.hour, minute: arrival.minute);
    _initTimeAndRoute();
    LowSignalController.instance.addListener(_onStateChange);
    EtaSharingService.instance.addListener(_onEtaServiceChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _onEtaServiceChange() {
    if (mounted) {
      setState(() {
        _isSharingActive = EtaSharingService.instance.isTripActive;
      });
    }
  }

  @override
  void dispose() {
    LowSignalController.instance.removeListener(_onStateChange);
    EtaSharingService.instance.removeListener(_onEtaServiceChange);
    super.dispose();
  }

  Future<void> _initTimeAndRoute() async {
    // Try to load route from offline cache if available
    try {
      final cachedRoute = await OfflineCacheService.getLastCachedRoute();
      if (mounted) {
        setState(() {
          _selectedRouteName = cachedRoute.routeTitle;
          if (!_availableRoutes.contains(cachedRoute.routeTitle)) {
            _availableRoutes.insert(0, cachedRoute.routeTitle);
          }
        });
      }
    } catch (_) {}

    // Set initial arrival time = current time + 25 mins
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: _durationMinutes));
    setState(() {
      _expectedArrival = TimeOfDay(hour: arrival.hour, minute: arrival.minute);
      _isSharingActive = EtaSharingService.instance.isTripActive;
    });
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String get _formattedEtaMessage {
    return EtaSharingService.formatEtaMessage(
      routeName: _selectedRouteName,
      durationMinutes: _durationMinutes,
      formattedArrivalTime: _formatTimeOfDay(_expectedArrival),
    );
  }

  Future<void> _pickArrivalTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expectedArrival,
      builder: (context, child) {
        final isLowSignal = LowSignalController.instance.isLowSignalMode;
        return Theme(
          data: isLowSignal
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppTheme.lowSignalYellow,
                    onPrimary: Colors.black,
                    surface: AppTheme.lowSignalCard,
                    onSurface: Colors.white,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppTheme.primaryPurple,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF1E1E2D),
                  ),
                ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _expectedArrival = picked;
      });
    }
  }

  void _setQuickDuration(int mins) {
    setState(() {
      _durationMinutes = mins;
      final now = DateTime.now();
      final arrival = now.add(Duration(minutes: mins));
      _expectedArrival = TimeOfDay(hour: arrival.hour, minute: arrival.minute);
    });
  }

  Future<void> _shareEtaWithContact() async {
    final message = _formattedEtaMessage;
    final phone = _selectedContact.phone;

    // Start active trip in service
    EtaSharingService.instance.startTrip(
      contact: _selectedContact,
      routeName: _selectedRouteName,
      durationMinutes: _durationMinutes,
      expectedArrival: _expectedArrival,
    );

    setState(() {
      _isSharingActive = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening native SMS app for ${_selectedContact.name}...'),
        backgroundColor: AppTheme.primaryPurple,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    final launched = await EtaSharingService.openSmsApp(
      phone: phone,
      message: message,
    );

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not launch SMS app directly. Message copied to clipboard!',
          ),
          backgroundColor: AppTheme.secondaryMagenta,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Clipboard.setData(ClipboardData(text: message));
    }
  }

  void _onArrivedSafelyPressed() {
    ArrivedSafelyDialog.show(
      context,
      contact: _selectedContact,
      routeName: _selectedRouteName,
      onDismiss: () {
        EtaSharingService.instance.markArrivedSafely();
        setState(() {
          _isSharingActive = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLowSignal = LowSignalController.instance.isLowSignalMode;

    return Scaffold(
      backgroundColor: isLowSignal ? AppTheme.lowSignalBg : AppTheme.softLavenderBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                decoration: BoxDecoration(
                  color: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
                  border: isLowSignal
                      ? const Border(
                          bottom: BorderSide(
                            color: AppTheme.lowSignalBorder,
                            width: 1.5,
                          ),
                        )
                      : null,
                  boxShadow: isLowSignal
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: isLowSignal
                            ? null
                            : const LinearGradient(
                                colors: [AppTheme.primaryPurple, AppTheme.secondaryMagenta],
                              ),
                        color: isLowSignal ? AppTheme.lowSignalYellow : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.share_location_rounded,
                        size: 22,
                        color: isLowSignal ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share ETA',
                          style: GoogleFonts.poppins(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'One-time updates • Zero continuous tracking',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Active Trip Status Card (when trip is active)
            if (_isSharingActive)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isLowSignal
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isLowSignal ? AppTheme.lowSignalCard : null,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isLowSignal ? AppTheme.lowSignalCyan : const Color(0xFF00C2A8),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF00C2A8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TRIP ACTIVE • ETA SHARED',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00C2A8),
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTimeOfDay(_expectedArrival),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Shared with ${_selectedContact.name} (${_selectedContact.relation})',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Big "I've Arrived Safely" Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _onArrivedSafelyPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C2A8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.verified_rounded, size: 20),
                            label: Text(
                              "I've Arrived Safely",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Content Sections
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 1. SELECT TRUSTED CONTACT
                  _buildSectionHeader(
                    title: '1. Select Trusted Contact',
                    subtitle: 'Choose who receives your arrival time',
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(height: 10),
                  _buildContactsList(isLowSignal),

                  const SizedBox(height: 22),

                  // 2. ROUTE & DURATION
                  _buildSectionHeader(
                    title: '2. Route & Travel Time',
                    subtitle: 'Current safe corridor and estimated duration',
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(height: 10),
                  _buildRouteSelectorCard(isLowSignal),

                  const SizedBox(height: 12),
                  _buildDurationChips(isLowSignal),

                  const SizedBox(height: 22),

                  // 3. EXPECTED ARRIVAL TIME
                  _buildSectionHeader(
                    title: '3. Expected Arrival Time',
                    subtitle: 'Tap time to adjust arrival schedule',
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(height: 10),
                  _buildArrivalTimeCard(isLowSignal),

                  const SizedBox(height: 22),

                  // 4. LIVE MESSAGE PREVIEW
                  _buildSectionHeader(
                    title: '4. Message Preview',
                    subtitle: 'Real message that will be sent via SMS',
                    isLowSignal: isLowSignal,
                  ),
                  const SizedBox(height: 10),
                  _buildMessagePreviewBox(isLowSignal),

                  const SizedBox(height: 22),

                  // 5. ACTION BUTTON: "Share ETA with [Contact]"
                  _buildShareActionButton(isLowSignal),

                  // Follow-up Arrived Safely Button (always available for easy access)
                  if (!_isSharingActive) ...[
                    const SizedBox(height: 12),
                    _buildArrivedSafelyQuickButton(isLowSignal),
                  ],

                  const SizedBox(height: 40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isLowSignal,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF1E1E2D),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: isLowSignal ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsList(bool isLowSignal) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _contacts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        final isSelected = contact.id == _selectedContact.id;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedContact = contact;
            });
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isLowSignal
                  ? (isSelected ? AppTheme.lowSignalCard : Colors.black)
                  : (isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                    : (isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0)),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected && !isLowSignal
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryPurple.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Avatar Circle with Initials
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isLowSignal ? AppTheme.lowSignalCard : contact.avatarColor,
                    shape: BoxShape.circle,
                    border: isLowSignal
                        ? Border.all(
                            color: isSelected ? AppTheme.lowSignalYellow : AppTheme.lowSignalBorder,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    contact.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isLowSignal ? AppTheme.lowSignalYellow : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name, Relationship, and Phone
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            contact.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLowSignal
                                  ? AppTheme.lowSignalBorder
                                  : AppTheme.primaryPurple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              contact.relation,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isLowSignal
                                    ? AppTheme.lowSignalCyan
                                    : AppTheme.primaryPurple,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contact.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isLowSignal ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection Radio Indicator
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                          : const Color(0xFF94A3B8),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: isLowSignal ? Colors.black : Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRouteSelectorCard(bool isLowSignal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route_rounded,
            size: 22,
            color: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.primaryPurple,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRouteName,
                isExpanded: true,
                dropdownColor: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isLowSignal ? Colors.white : const Color(0xFF64748B),
                ),
                items: _availableRoutes.map((route) {
                  return DropdownMenuItem<String>(
                    value: route,
                    child: Text(
                      route,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isLowSignal ? Colors.white : const Color(0xFF1E1E2D),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRouteName = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationChips(bool isLowSignal) {
    final durations = [15, 25, 40, 60];

    return Row(
      children: durations.map((mins) {
        final isSelected = _durationMinutes == mins;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => _setQuickDuration(mins),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                      : (isLowSignal ? AppTheme.lowSignalCard : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? (isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple)
                        : (isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  '+$mins min',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? (isLowSignal ? Colors.black : Colors.white)
                        : (isLowSignal ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildArrivalTimeCard(bool isLowSignal) {
    return InkWell(
      onTap: _pickArrivalTime,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isLowSignal ? AppTheme.lowSignalCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLowSignal ? AppTheme.lowSignalBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLowSignal
                    ? AppTheme.lowSignalYellow.withValues(alpha: 0.15)
                    : AppTheme.primaryPurple.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.access_time_filled_rounded,
                size: 22,
                color: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expected Arrival',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isLowSignal ? Colors.white70 : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    _formatTimeOfDay(_expectedArrival),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF1E1E2D),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isLowSignal
                    ? AppTheme.lowSignalBorder
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.edit,
                    size: 13,
                    color: isLowSignal ? Colors.white : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Change',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isLowSignal ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagePreviewBox(bool isLowSignal) {
    final message = _formattedEtaMessage;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLowSignal ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLowSignal ? AppTheme.lowSignalCyan : const Color(0xFFCBD5E1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sms_outlined,
                size: 16,
                color: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.primaryPurple,
              ),
              const SizedBox(width: 6),
              Text(
                'SMS PREVIEW',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isLowSignal ? AppTheme.lowSignalCyan : AppTheme.primaryPurple,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              // Copy Button
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: isLowSignal ? Colors.white70 : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: isLowSignal ? Colors.white70 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            message,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: isLowSignal ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                size: 13,
                color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF00C2A8),
              ),
              const SizedBox(width: 5),
              Text(
                'Zero live tracking • Sent directly to ${_selectedContact.name}',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: isLowSignal ? AppTheme.lowSignalYellow : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareActionButton(bool isLowSignal) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _shareEtaWithContact,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLowSignal ? AppTheme.lowSignalYellow : AppTheme.primaryPurple,
          foregroundColor: isLowSignal ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: isLowSignal ? 0 : 3,
          shadowColor: AppTheme.primaryPurple.withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              size: 18,
              color: isLowSignal ? Colors.black : Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              'Share ETA with ${_selectedContact.name}',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isLowSignal ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrivedSafelyQuickButton(bool isLowSignal) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        onPressed: _onArrivedSafelyPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF00C2A8),
          side: const BorderSide(color: Color(0xFF00C2A8), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
        label: Text(
          "I've Arrived Safely",
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
