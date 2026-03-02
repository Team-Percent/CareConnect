import 'package:health_wallet/features/records/domain/entity/i_fhir_resource.dart';
import 'package:health_wallet/features/records/domain/repository/records_repository.dart';
import 'package:injectable/injectable.dart';

/// Builds a concise medical context string from FHIR records for the AI prompt.
@LazySingleton()
class MedicalContextBuilder {
  final RecordsRepository _recordsRepository;

  MedicalContextBuilder(this._recordsRepository);

  /// Fetches key FHIR resources and builds a plain-text summary for the LLM.
  Future<String> buildContext() async {
    final buffer = StringBuffer();
    buffer.writeln('=== PATIENT MEDICAL RECORDS SUMMARY ===');

    // Conditions / Diagnoses
    final conditions = await _recordsRepository.getResources(
      resourceTypes: [FhirType.Condition],
      limit: 20,
    );
    if (conditions.isNotEmpty) {
      buffer.writeln('\n--- Active Conditions ---');
      for (final c in conditions) {
        buffer.writeln('• ${c.displayTitle} (${c.statusDisplay})');
      }
    }

    // Medications
    final medications = await _recordsRepository.getResources(
      resourceTypes: [
        FhirType.MedicationRequest,
        FhirType.MedicationStatement,
        FhirType.Medication,
      ],
      limit: 20,
    );
    if (medications.isNotEmpty) {
      buffer.writeln('\n--- Medications ---');
      for (final m in medications) {
        buffer.writeln('• ${m.displayTitle} (${m.statusDisplay})');
      }
    }

    // Allergies
    final allergies = await _recordsRepository.getResources(
      resourceTypes: [FhirType.AllergyIntolerance],
      limit: 10,
    );
    if (allergies.isNotEmpty) {
      buffer.writeln('\n--- Allergies ---');
      for (final a in allergies) {
        buffer.writeln('• ${a.displayTitle}');
      }
    }

    // Recent Observations (vitals, labs)
    final observations = await _recordsRepository.getResources(
      resourceTypes: [FhirType.Observation],
      limit: 15,
    );
    if (observations.isNotEmpty) {
      buffer.writeln('\n--- Recent Observations ---');
      for (final o in observations) {
        final dateStr = o.date != null
            ? '${o.date!.year}-${o.date!.month.toString().padLeft(2, '0')}-${o.date!.day.toString().padLeft(2, '0')}'
            : '';
        buffer.writeln('• ${o.displayTitle} $dateStr');
      }
    }

    // Procedures
    final procedures = await _recordsRepository.getResources(
      resourceTypes: [FhirType.Procedure],
      limit: 10,
    );
    if (procedures.isNotEmpty) {
      buffer.writeln('\n--- Procedures ---');
      for (final p in procedures) {
        buffer.writeln('• ${p.displayTitle} (${p.statusDisplay})');
      }
    }

    // Encounters
    final encounters = await _recordsRepository.getResources(
      resourceTypes: [FhirType.Encounter],
      limit: 10,
    );
    if (encounters.isNotEmpty) {
      buffer.writeln('\n--- Recent Encounters ---');
      for (final e in encounters) {
        final dateStr = e.date != null
            ? '${e.date!.year}-${e.date!.month.toString().padLeft(2, '0')}-${e.date!.day.toString().padLeft(2, '0')}'
            : '';
        buffer.writeln('• ${e.displayTitle} $dateStr');
      }
    }

    // Immunizations
    final immunizations = await _recordsRepository.getResources(
      resourceTypes: [FhirType.Immunization],
      limit: 10,
    );
    if (immunizations.isNotEmpty) {
      buffer.writeln('\n--- Immunizations ---');
      for (final i in immunizations) {
        buffer.writeln('• ${i.displayTitle}');
      }
    }

    // Diagnostic Reports
    final diagnosticReports = await _recordsRepository.getResources(
      resourceTypes: [FhirType.DiagnosticReport],
      limit: 10,
    );
    if (diagnosticReports.isNotEmpty) {
      buffer.writeln('\n--- Diagnostic Reports ---');
      for (final d in diagnosticReports) {
        buffer.writeln('• ${d.displayTitle} (${d.statusDisplay})');
      }
    }

    buffer.writeln('\n=== END OF MEDICAL RECORDS ===');

    final context = buffer.toString();
    // If no records at all, return a minimal context
    if (conditions.isEmpty &&
        medications.isEmpty &&
        allergies.isEmpty &&
        observations.isEmpty) {
      return 'No medical records are currently available for this patient.';
    }

    return context;
  }
}
