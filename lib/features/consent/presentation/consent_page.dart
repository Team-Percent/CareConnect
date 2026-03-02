import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/theme/app_insets.dart';
import 'package:health_wallet/core/theme/app_text_style.dart';
import 'package:health_wallet/core/utils/build_context_extension.dart';
import 'package:health_wallet/core/widgets/custom_app_bar.dart';
import 'package:health_wallet/features/consent/data/uhi_switch_service.dart';
import 'package:health_wallet/features/user/presentation/bloc/user_bloc.dart';
import 'package:health_wallet/features/user/presentation/preferences_modal/sections/patient/bloc/patient_bloc.dart';

/// Tab 1 — Consent Management via UHI-switch key store server.
@RoutePage()
class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  List<UhiConsentArtifact>? _consents;
  bool _isLoading = true;
  String? _error;
  bool _serverUnavailable = false;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  String _getPatientId(BuildContext context) {
    try {
      final patientState = context.read<PatientBloc>().state;
      final selectedId = patientState.selectedPatientId;
      if (selectedId != null && selectedId.isNotEmpty) return selectedId;
    } catch (_) {}
    try {
      final userState = context.read<UserBloc>().state;
      if (userState.user.name.isNotEmpty) return userState.user.name;
    } catch (_) {}
    return 'PATIENT_001';
  }

  Future<void> _loadConsents() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _serverUnavailable = false;
    });

    try {
      final patientId = _getPatientId(context);
      final reachable = await UhiSwitchService.isServerReachable();
      if (!reachable) {
        setState(() {
          _isLoading = false;
          _serverUnavailable = true;
        });
        return;
      }
      final consents = await UhiSwitchService.listConsents(patientId);
      setState(() {
        _consents = consents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showGrantConsentSheet() async {
    final hospitalController = TextEditingController();
    final doctorController = TextEditingController();
    final selectedPermissions = <String>['Observation', 'Condition'];
    DateTime expiresAt = DateTime.now().add(const Duration(days: 30));

    // Cache patientId before the async operation to avoid use_build_context_synchronously
    final patientId = _getPatientId(context);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GrantConsentSheet(
        hospitalController: hospitalController,
        doctorController: doctorController,
        initialPermissions: selectedPermissions,
        initialExpiry: expiresAt,
        onExpirChanged: (d) => expiresAt = d,
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        final request = UhiConsentGrantRequest(
          patientAbhaId: patientId,
          doctorId: doctorController.text.trim().isEmpty
              ? 'DR_UNKNOWN'
              : doctorController.text.trim(),
          hospitalId: hospitalController.text.trim().isEmpty
              ? 'HOSPITAL_UNKNOWN'
              : hospitalController.text.trim(),
          permissions: selectedPermissions,
          expiresAt: expiresAt,
        );
        await UhiSwitchService.grantConsent(request);
        await _loadConsents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Consent granted successfully'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        setState(() {
          _error = 'Failed to grant consent: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Consent Manager',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined,
                color: context.colorScheme.onSurface),
            onPressed: _loadConsents,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            Insets.normal, Insets.medium, Insets.normal, 100),
        children: [
          // Status banner
          _buildBanner(context),

          const SizedBox(height: Insets.large),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_serverUnavailable)
            _buildServerUnavailableCard(context)
          else if (_error != null)
            _buildErrorCard(context)
          else ...[
            // Active Consents
            Text(
              'Active Consents',
              style: AppTextStyle.titleSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Insets.normal),

            if (_consents == null || _consents!.isEmpty)
              _buildNoConsentsCard(context)
            else
              Builder(
                builder: (_) {
                  final activeConsents =
                      _consents!.where((c) => c.isActive).toList();
                  final pastConsents =
                      _consents!.where((c) => !c.isActive).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final c in activeConsents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Insets.small),
                          child: _ConsentCard(
                              artifact: c, onRevoke: _loadConsents),
                        ),
                      if (pastConsents.isNotEmpty) ...[
                        const SizedBox(height: Insets.medium),
                        Text(
                          'Past Consents',
                          style: AppTextStyle.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: Insets.normal),
                        for (final c in pastConsents)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: Insets.small),
                            child: _ConsentCard(
                                artifact: c, onRevoke: _loadConsents),
                          ),
                      ],
                    ],
                  );
                },
              ),

            const SizedBox(height: Insets.large),

            // Grant button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _showGrantConsentSheet,
                icon: const Icon(Icons.add_circle_outline, size: 20),
                label: const Text('Grant New Consent'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],

          const SizedBox(height: Insets.large),
          _buildInfoSection(context),
        ],
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colorScheme.primary.withValues(alpha: 0.08),
            context.colorScheme.primary.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.colorScheme.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: context.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: Insets.normal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UHI Network Consent',
                  style: AppTextStyle.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Control which hospitals can access your health data',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerUnavailableCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.large),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.orange.withValues(alpha: 0.05)
            : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 48, color: Colors.orange.shade400),
          const SizedBox(height: Insets.normal),
          Text(
            'UHI Server Unavailable',
            style:
                AppTextStyle.titleSmall.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Insets.small),
          Text(
            'The UHI-switch server is not reachable.\nMake sure the server is running at:\n${UhiSwitchService.baseUrl}',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
              height: 1.5,
            ),
          ),
          const SizedBox(height: Insets.medium),
          OutlinedButton.icon(
            onPressed: _loadConsents,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        color: context.colorScheme.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: context.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 36, color: context.colorScheme.error),
          const SizedBox(height: Insets.small),
          Text(
            'Failed to load consents',
            style:
                AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: Insets.small),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall.copyWith(
              color: context.colorScheme.error.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: Insets.medium),
          OutlinedButton.icon(
            onPressed: _loadConsents,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoConsentsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: Insets.large, horizontal: Insets.normal),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.approval_outlined,
              size: 40,
              color: context.colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: Insets.normal),
          Text(
            'No active consents',
            style: AppTextStyle.bodyMedium.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: Insets.small),
          Text(
            'Grant access to a hospital to share your health records securely.',
            textAlign: TextAlign.center,
            style: AppTextStyle.bodySmall.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.medium),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 16,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text(
                'How Consent Works',
                style: AppTextStyle.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.small),
          _InfoPoint(
            icon: Icons.lock_outline,
            text: 'Your data stays on your device until you grant access',
          ),
          _InfoPoint(
            icon: Icons.timer_outlined,
            text: 'Consents are time-limited and auto-expire',
          ),
          _InfoPoint(
            icon: Icons.link_outlined,
            text: 'Connected via UHI-switch inter-hospital key store',
          ),
          _InfoPoint(
            icon: Icons.visibility_outlined,
            text: 'Choose exactly which record types to share',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Consent card widget
// ─────────────────────────────────────────────

class _ConsentCard extends StatelessWidget {
  final UhiConsentArtifact artifact;
  final VoidCallback onRevoke;

  const _ConsentCard({required this.artifact, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final isActive = artifact.isActive;
    final statusColor = isActive ? Colors.green : Colors.orange;
    final statusLabel = artifact.isActive
        ? 'Active'
        : artifact.status == 'REVOKED'
            ? 'Revoked'
            : 'Expired';

    String formatDate(DateTime dt) =>
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.small),
      padding: const EdgeInsets.all(Insets.normal),
      decoration: BoxDecoration(
        color: context.isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: context.isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.local_hospital_outlined,
                    size: 20, color: context.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artifact.hospitalId,
                      style: AppTextStyle.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Dr: ${artifact.doctorId}',
                      style: AppTextStyle.labelSmall.copyWith(
                        color: context.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyle.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.small),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: artifact.permissions.map((p) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p,
                  style: AppTextStyle.labelSmall.copyWith(
                    color: context.colorScheme.primary,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Insets.small),
          Row(
            children: [
              _DateChip(label: 'Granted', date: formatDate(artifact.grantedAt)),
              const SizedBox(width: Insets.small),
              _DateChip(label: 'Expires', date: formatDate(artifact.expiresAt)),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String date;
  const _DateChip({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: AppTextStyle.labelSmall.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.35),
            fontSize: 10,
          ),
        ),
        Text(
          date,
          style: AppTextStyle.labelSmall.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 14,
              color: context.colorScheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.bodySmall.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Grant consent bottom sheet
// ─────────────────────────────────────────────

class _GrantConsentSheet extends StatefulWidget {
  final TextEditingController hospitalController;
  final TextEditingController doctorController;
  final List<String> initialPermissions;
  final DateTime initialExpiry;
  final ValueChanged<DateTime> onExpirChanged;

  const _GrantConsentSheet({
    required this.hospitalController,
    required this.doctorController,
    required this.initialPermissions,
    required this.initialExpiry,
    required this.onExpirChanged,
  });

  @override
  State<_GrantConsentSheet> createState() => _GrantConsentSheetState();
}

class _GrantConsentSheetState extends State<_GrantConsentSheet> {
  final _availablePermissions = [
    'Observation',
    'Condition',
    'MedicationRequest',
    'AllergyIntolerance',
    'Procedure',
    'DiagnosticReport',
    'Encounter',
    'Immunization',
  ];

  late List<String> _selectedPermissions;
  late DateTime _expiresAt;

  @override
  void initState() {
    super.initState();
    _selectedPermissions = List.from(widget.initialPermissions);
    _expiresAt = widget.initialExpiry;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        Insets.normal,
        Insets.normal,
        Insets.normal,
        MediaQuery.of(context).viewInsets.bottom + Insets.large,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: Insets.medium),
            Text('Grant Hospital Access',
                style: AppTextStyle.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: Insets.medium),
            TextField(
              controller: widget.hospitalController,
              decoration: InputDecoration(
                labelText: 'Hospital ID',
                hintText: 'e.g. AIIMS_DELHI',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.local_hospital_outlined),
              ),
            ),
            const SizedBox(height: Insets.normal),
            TextField(
              controller: widget.doctorController,
              decoration: InputDecoration(
                labelText: 'Doctor ID (optional)',
                hintText: 'e.g. DR_SHARMA',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: Insets.medium),
            Text('Record Access',
                style: AppTextStyle.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: Insets.small),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _availablePermissions.map((p) {
                final selected = _selectedPermissions.contains(p);
                return FilterChip(
                  label: Text(p,
                      style: AppTextStyle.labelSmall.copyWith(
                        color: selected
                            ? (context.isDarkMode
                                ? Colors.white
                                : context.colorScheme.onPrimary)
                            : context.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                      )),
                  selected: selected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedPermissions.add(p);
                      } else {
                        _selectedPermissions.remove(p);
                      }
                    });
                  },
                  selectedColor: context.colorScheme.primary,
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: Insets.medium),
            Row(
              children: [
                Text('Expires: ',
                    style: AppTextStyle.bodySmall
                        .copyWith(fontWeight: FontWeight.w500)),
                Text(
                  '${_expiresAt.day}/${_expiresAt.month}/${_expiresAt.year}',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: context.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: const Text('Change'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _expiresAt,
                      firstDate: DateTime.now().add(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _expiresAt = picked);
                      widget.onExpirChanged(picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: Insets.large),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: Insets.normal),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedPermissions.isEmpty
                        ? null
                        : () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Grant Access'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
