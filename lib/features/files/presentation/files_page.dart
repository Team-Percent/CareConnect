import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/theme/app_insets.dart';
import 'package:health_wallet/core/theme/app_text_style.dart';
import 'package:health_wallet/core/utils/build_context_extension.dart';
import 'package:health_wallet/core/widgets/custom_app_bar.dart';
import 'package:health_wallet/features/records/domain/entity/entity.dart';
import 'package:health_wallet/features/records/presentation/bloc/records_bloc.dart';
import 'package:health_wallet/core/navigation/app_router.dart';

/// Tab 2 — Patient Files & Records Management
@RoutePage()
class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  FhirType? _selectedFilter;

  static const _filterTypes = [
    null, // "All"
    FhirType.Condition,
    FhirType.Observation,
    FhirType.MedicationRequest,
    FhirType.AllergyIntolerance,
    FhirType.DiagnosticReport,
    FhirType.Procedure,
    FhirType.Immunization,
    FhirType.Encounter,
  ];

  static const _filterLabels = {
    null: 'All',
    FhirType.Condition: 'Conditions',
    FhirType.Observation: 'Vitals & Labs',
    FhirType.MedicationRequest: 'Medications',
    FhirType.AllergyIntolerance: 'Allergies',
    FhirType.DiagnosticReport: 'Reports',
    FhirType.Procedure: 'Procedures',
    FhirType.Immunization: 'Immunization',
    FhirType.Encounter: 'Visits',
  };

  @override
  void initState() {
    super.initState();
    context.read<RecordsBloc>().add(const RecordsInitialised());
  }

  void _applyFilter(FhirType? type) {
    setState(() => _selectedFilter = type);
    if (type == null) {
      context.read<RecordsBloc>().add(const RecordsInitialised());
    } else {
      context.read<RecordsBloc>().add(RecordsFiltersApplied([type]));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Patient Files',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined,
                color: context.colorScheme.onSurface),
            onPressed: () {
              _selectedFilter = null;
              context.read<RecordsBloc>().add(const RecordsInitialised());
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterRow(context),

          // Records list
          Expanded(
            child: BlocBuilder<RecordsBloc, RecordsState>(
              builder: (context, state) {
                if (state.status == const RecordsStatus.loading()) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: context.colorScheme.primary,
                    ),
                  );
                }

                if (state.resources.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      Insets.normal, Insets.small, Insets.normal, 100),
                  itemCount: state.resources.length,
                  itemBuilder: (context, index) {
                    final record = state.resources[index];
                    return _buildRecordCard(context, record);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: Insets.normal),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _filterTypes.map((type) {
          final isSelected = _selectedFilter == type;
          final label = _filterLabels[type] ?? 'All';
          return Padding(
            padding: const EdgeInsets.only(right: 8, top: 6, bottom: 6),
            child: FilterChip(
              label: Text(
                label,
                style: AppTextStyle.labelSmall.copyWith(
                  color: isSelected
                      ? (context.isDarkMode
                          ? Colors.white
                          : context.colorScheme.onPrimary)
                      : context.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => _applyFilter(type),
              selectedColor: context.colorScheme.primary,
              backgroundColor: context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.04),
              checkmarkColor: context.isDarkMode
                  ? Colors.white
                  : context.colorScheme.onPrimary,
              side: BorderSide(
                color: isSelected
                    ? context.colorScheme.primary
                    : context.colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 56,
                color: context.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: Insets.large),
            Text(
              'No files found',
              style: AppTextStyle.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Insets.small),
            Text(
              'Scan documents or upload files to manage your patient records here.',
              textAlign: TextAlign.center,
              style: AppTextStyle.bodySmall.copyWith(
                color: context.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, IFhirResource record) {
    final dateStr = record.date != null
        ? '${record.date!.day.toString().padLeft(2, '0')}/'
            '${record.date!.month.toString().padLeft(2, '0')}/'
            '${record.date!.year}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: Insets.small),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.normal,
          vertical: Insets.small,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconForType(record.fhirType),
            color: context.colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          record.displayTitle,
          style: AppTextStyle.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: context.colorScheme.onSurface,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                record.fhirType.display,
                style: AppTextStyle.labelSmall.copyWith(
                  color: context.colorScheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (dateStr.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: AppTextStyle.labelSmall.copyWith(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: context.colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        onTap: () {
          context.router.push(RecordDetailsRoute(resource: record));
        },
      ),
    );
  }

  IconData _getIconForType(FhirType type) {
    switch (type) {
      case FhirType.Observation:
        return Icons.monitor_heart_outlined;
      case FhirType.MedicationRequest:
        return Icons.medication_outlined;
      case FhirType.MedicationStatement:
        return Icons.medication_liquid_outlined;
      case FhirType.Condition:
        return Icons.medical_information_outlined;
      case FhirType.AllergyIntolerance:
        return Icons.warning_amber_outlined;
      case FhirType.Immunization:
        return Icons.vaccines_outlined;
      case FhirType.Procedure:
        return Icons.healing_outlined;
      case FhirType.DiagnosticReport:
        return Icons.assignment_outlined;
      case FhirType.Encounter:
        return Icons.local_hospital_outlined;
      default:
        return Icons.description_outlined;
    }
  }
}
