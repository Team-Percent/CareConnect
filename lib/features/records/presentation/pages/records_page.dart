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

/// Records page — browse medical records from local FHIR data.
@RoutePage()
class RecordsPage extends StatefulWidget {
  final List<FhirType>? initFilters;
  final PageController? pageController;

  const RecordsPage({super.key, this.initFilters, this.pageController});

  @override
  State<RecordsPage> createState() => _RecordsPageState();
}

class _RecordsPageState extends State<RecordsPage> {
  @override
  void initState() {
    super.initState();
    if (widget.initFilters != null) {
      context
          .read<RecordsBloc>()
          .add(RecordsFiltersApplied(widget.initFilters!));
    } else {
      context.read<RecordsBloc>().add(const RecordsInitialised());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Medical Records',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined,
                color: context.colorScheme.onSurface),
            onPressed: () =>
                context.read<RecordsBloc>().add(const RecordsInitialised()),
          ),
        ],
      ),
      body: BlocBuilder<RecordsBloc, RecordsState>(
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
                Insets.normal, Insets.medium, Insets.normal, 80),
            itemCount: state.resources.length,
            itemBuilder: (context, index) {
              final record = state.resources[index];
              return _buildRecordCard(context, record);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: context.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: Insets.normal),
          Text(
            'No records found',
            style: AppTextStyle.titleMedium.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: Insets.small),
          Text(
            'Sync or scan documents to see your records here.',
            style: AppTextStyle.bodySmall.copyWith(
              color: context.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, IFhirResource record) {
    return Card(
      margin: const EdgeInsets.only(bottom: Insets.small),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.isDarkMode
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.white,
      elevation: context.isDarkMode ? 0 : 1,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Insets.normal,
          vertical: Insets.small,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getIconForType(record.fhirType),
            color: context.colorScheme.primary,
            size: 20,
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
        subtitle: Text(
          record.fhirType.display,
          style: AppTextStyle.bodySmall.copyWith(
            color: context.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
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
      default:
        return Icons.description_outlined;
    }
  }
}
