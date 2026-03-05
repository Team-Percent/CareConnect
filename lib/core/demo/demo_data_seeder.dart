import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:health_wallet/core/data/local/app_database.dart';
import 'package:health_wallet/core/di/injection.dart';
import 'package:health_wallet/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Seeds REAL clinical data from Hospital A (CityCare) and Hospital B (Metro Radiology)
/// for Devaganesh S — extracted from actual clinical reports.
class DemoDataSeeder {
  static const _patientId = 'demo-patient-devaganesh';
  static const _sourceIdA = 'HOSP-CITYCARE-A';
  static const _sourceIdB = 'HOSP-METRO-B';
  static const _abhaId = '91-1234-5678-9012';

  static Future<void> seedIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('demo_data_seeded_v2') == true) {
      if (prefs.getString('selected_patient_id') == null) {
        await prefs.setString('selected_patient_id', _patientId);
      }
      return;
    }

    logger.i('Seeding real hospital data for Devaganesh S...');

    try {
      final db = getIt<AppDatabase>();

      // ── Sources ────────────────────────────────
      await db.into(db.sources).insertOnConflictUpdate(SourcesCompanion.insert(
        id: _sourceIdA,
        platformName: const Value('CityCare Multispeciality Hospital'),
        labelSource: const Value('Hospital A — Primary Care'),
        platformType: const Value('hospital'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      await db.into(db.sources).insertOnConflictUpdate(SourcesCompanion.insert(
        id: _sourceIdB,
        platformName: const Value('Metro Radiology & Diagnostics Center'),
        labelSource: const Value('Hospital B — Radiology'),
        platformType: const Value('hospital'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));

      // ── Patient ────────────────────────────────
      await _insert(db, id: _patientId, sourceId: _sourceIdA,
        resourceType: 'Patient', resourceId: _patientId,
        title: 'Devaganesh S', date: DateTime(2002, 6, 15),
        raw: _patientFhir());

      // ── Conditions ────────────────────────────────
      await _insert(db, id: 'cond-htn', sourceId: _sourceIdA,
        resourceType: 'Condition', resourceId: 'cond-htn',
        title: 'Hypertension with Mild Obesity',
        date: DateTime(2026, 1, 1), subjectId: _patientId,
        raw: _conditionFhir('Hypertension with Mild Obesity', '38341003',
          clinicalStatus: 'resolved',
          note: 'Primary diagnosis. Lifestyle-based management initiated Jan 2026. '
              'Medication (Amlodipine 5mg) discontinued Month 4. '
              'Fully controlled by Month 10 — BP 108/68, BMI 22.0.'));

      // ── Medications ────────────────────────────────
      await _insert(db, id: 'med-amlodipine', sourceId: _sourceIdA,
        resourceType: 'MedicationRequest', resourceId: 'med-amlodipine',
        title: 'Amlodipine 5mg', date: DateTime(2026, 1, 1),
        subjectId: _patientId,
        raw: _medicationFhir('Amlodipine 5mg', '329526',
          'One tablet daily. Started Month 1, reduced Month 3, DISCONTINUED Month 4.',
          status: 'stopped'));

      await _insert(db, id: 'med-dash', sourceId: _sourceIdA,
        resourceType: 'MedicationRequest', resourceId: 'med-dash',
        title: 'DASH Diet Protocol', date: DateTime(2026, 1, 1),
        subjectId: _patientId,
        raw: _medicationFhir('DASH Diet Protocol', 'LIFESTYLE',
          'Dietary Approaches to Stop Hypertension. Ongoing since Month 1.',
          status: 'active'));

      // ── 10-Month Progress (as DiagnosticReports) ────────────
      final progressData = [
        {'m': 1, 'bp': '142/90', 'w': 89, 'bmi': 28.5, 'hr': 88, 'tc': null, 'tg': null, 'hdl': null,
         'med': 'Amlodipine 5mg, DASH diet initiated', 'ex': '30 mins brisk walking',
         'a': 'Initial response to lifestyle modifications. Blood pressure showing downward trend.'},
        {'m': 2, 'bp': '134/85', 'w': 85, 'bmi': 26.8, 'hr': 76, 'tc': null, 'tg': null, 'hdl': null,
         'med': 'Amlodipine 5mg continued', 'ex': '45 mins daily (brisk walking + light gym)',
         'a': 'Continued improvement in BP control and significant weight reduction. Resting HR normalized.'},
        {'m': 3, 'bp': '124/80', 'w': 80, 'bmi': 25.5, 'hr': 72, 'tc': null, 'tg': null, 'hdl': null,
         'med': 'Amlodipine dosage reduced', 'ex': '60 mins daily',
         'a': 'Excellent improvement. BP near-normal. Significant weight reduction. Medication reduced.'},
        {'m': 4, 'bp': '120/78', 'w': 77, 'bmi': 24.5, 'hr': 70, 'tc': null, 'tg': null, 'hdl': null,
         'med': 'Amlodipine DISCONTINUED – monitoring only', 'ex': '60 mins daily (Cardio + Strength)',
         'a': 'Normal BP achieved. Healthy BMI range. Medication discontinued.'},
        {'m': 5, 'bp': '118/76', 'w': 75, 'bmi': 23.8, 'hr': 68, 'tc': 178, 'tg': null, 'hdl': null,
         'med': 'No antihypertensives – monitoring only', 'ex': '90 mins daily (Cardio + Strength)',
         'a': 'Sustained normal BP without medication. Cholesterol improved.'},
        {'m': 6, 'bp': '116/74', 'w': 74, 'bmi': 23.4, 'hr': 66, 'tc': 170, 'tg': 135, 'hdl': null,
         'med': 'No medication – lifestyle management only', 'ex': '90 mins daily',
         'a': 'Stable normal BP. Lipid profile markedly improved. Diagnosis updated: Hypertension (Resolved).'},
        {'m': 7, 'bp': '114/72', 'w': 73, 'bmi': 23.0, 'hr': 64, 'tc': 165, 'tg': 120, 'hdl': 55,
         'med': 'No medication', 'ex': '90 mins daily',
         'a': 'Optimal BP and lipid profile maintained without medication. Diagnosis: Hypertension – Resolved.'},
        {'m': 8, 'bp': '112/70', 'w': 72, 'bmi': 22.7, 'hr': 62, 'tc': 160, 'tg': 110, 'hdl': 58,
         'med': 'No medication', 'ex': '90 mins daily',
         'a': 'Hypertension – Fully Controlled (Lifestyle Based). All parameters optimal.'},
        {'m': 9, 'bp': '110/70', 'w': 71, 'bmi': 22.4, 'hr': 60, 'tc': 155, 'tg': 105, 'hdl': 60,
         'med': 'No medication', 'ex': '90 mins daily',
         'a': 'Hypertension – Resolved (Preventive Phase). Quarterly monitoring recommended.'},
        {'m': 10, 'bp': '108/68', 'w': 70, 'bmi': 22.0, 'hr': 58, 'tc': 150, 'tg': 95, 'hdl': 62,
         'med': 'No medication', 'ex': '90 mins daily',
         'a': 'FINAL: Complete normalization of BP and lipid profile. Cardiovascular risk reduced from high to low.'},
      ];

      for (final p in progressData) {
        final m = p['m'] as int;
        await _insert(db, id: 'progress-month-$m', sourceId: _sourceIdA,
          resourceType: 'DiagnosticReport', resourceId: 'progress-month-$m',
          title: 'Month $m Progress Report',
          date: DateTime(2026, m, 15), subjectId: _patientId,
          raw: _progressReportFhir(p));
      }

      // ── Imaging — Hospital A (months 1-2) ────────────
      final imagingA = [
        {'m': 1, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph in full inspiration',
         'f': 'Lung fields clear bilaterally. No focal consolidation. Cardiac silhouette within normal limits. Costophrenic angles clear.',
         'i': 'Normal chest radiograph. No cardiomegaly or pulmonary pathology.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 1, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen and renal arteries',
         'f': 'Kidneys normal. No renal artery stenosis. Adrenals normal. No secondary structural causes of hypertension.',
         'i': 'Normal CT abdomen. No secondary hypertension. Supports primary (essential) hypertension.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 2, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'Lung fields clear. Cardiac silhouette stable. No pulmonary vascular congestion.',
         'i': 'Stable chest radiograph. No interval changes.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 2, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen follow-up',
         'f': 'Kidneys normal. Renal arteries patent. No new findings.',
         'i': 'Stable CT findings. No progression.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
      ];

      for (var idx = 0; idx < imagingA.length; idx++) {
        final img = imagingA[idx];
        final m = img['m'] as int;
        await _insert(db, id: 'img-a-$m-$idx', sourceId: _sourceIdA,
          resourceType: 'DiagnosticReport', resourceId: 'img-a-$m-$idx',
          title: '${img['t']} — Month $m',
          date: DateTime(2026, m, 10), subjectId: _patientId,
          raw: _imagingReportFhir(img, 'CityCare Multispeciality Hospital'));
      }

      // ── Imaging — Hospital B (months 3-8) ────────────
      final imagingB = [
        {'m': 3, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'Clear lung fields. Slight reduction in cardiac diameter vs baseline. No pathology.',
         'i': 'Interval improvement. Consistent with improved cardiovascular condition.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 3, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen follow-up',
         'f': 'Kidneys normal. Mild reduction in perirenal fat consistent with weight loss.',
         'i': 'Stable findings. Visceral fat reduction consistent with clinical progress.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 4, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'Lungs clear. Continued reduction in cardiothoracic ratio.',
         'i': 'Progressive improvement in cardiac metrics.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 4, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen',
         'f': 'Normal kidneys and renal arteries. Significant visceral fat reduction.',
         'i': 'Stable normal study. Significant visceral fat reduction.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 5, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'Clear lung fields. Cardiothoracic ratio improved to ~48% (from baseline 52%).',
         'i': 'Significant improvement in cardiothoracic ratio.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 5, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen',
         'f': 'Normal anatomy. Continued reduction in visceral adipose tissue.',
         'i': 'Continued improvement in body composition.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 6, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'Normal cardiac silhouette. Clear lungs. CTR within normal limits.',
         'i': 'Normal chest radiograph. Cardiac dimensions stable.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 6, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen',
         'f': 'Normal kidneys and vasculature. Sustained visceral fat reduction.',
         'i': 'Normal study. No secondary hypertension etiology.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 7, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'CTR approximately 46%, optimal range.',
         'i': 'CTR now optimal. No pulmonary pathology.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 7, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen follow-up',
         'f': 'Kidneys and renal arteries normal. Significant improvement in visceral fat.',
         'i': 'Normal CT. Significant body composition improvement over 7 months.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 8, 't': 'Chest X-Ray', 'tech': 'PA view chest radiograph',
         'f': 'Normal cardiac silhouette. Clear lungs bilaterally.',
         'i': 'Normal chest radiograph. Stable excellent findings.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
        {'m': 8, 't': 'CT Abdomen', 'tech': 'Contrast-enhanced CT abdomen — advanced monitoring',
         'f': 'Kidneys normal. Renal arteries patent. No stenosis or calcification. Full structural stability.',
         'i': 'Radiologically normal. Structural and vascular stability confirmed across 8 months.', 'r': 'Dr. R. Mehta, MD (Radiology)'},
      ];

      for (var idx = 0; idx < imagingB.length; idx++) {
        final img = imagingB[idx];
        final m = img['m'] as int;
        await _insert(db, id: 'img-b-$m-$idx', sourceId: _sourceIdB,
          resourceType: 'DiagnosticReport', resourceId: 'img-b-$m-$idx',
          title: '${img['t']} — Month $m',
          date: DateTime(2026, m, 10), subjectId: _patientId,
          raw: _imagingReportFhir(img, 'Metro Radiology & Diagnostics Center'));
      }

      // ── Allergy ────────────────────────────────
      await _insert(db, id: 'allergy-1', sourceId: _sourceIdA,
        resourceType: 'AllergyIntolerance', resourceId: 'allergy-1',
        title: 'No Known Drug Allergies', date: DateTime(2026, 1, 1),
        subjectId: _patientId,
        raw: {
          'resourceType': 'AllergyIntolerance',
          'clinicalStatus': {'coding': [{'code': 'active'}]},
          'verificationStatus': {'coding': [{'code': 'confirmed'}]},
          'code': {'text': 'No Known Drug Allergies (NKDA)'},
          'patient': {'reference': 'Patient/$_patientId'},
        });

      // Set selected patient
      await prefs.setString('selected_patient_id', _patientId);
      await prefs.setBool('demo_data_seeded_v2', true);

      logger.i('Real hospital data seeded successfully ✓');
      logger.i('  Hospital A: 10 progress reports + 4 imaging');
      logger.i('  Hospital B: 12 imaging reports');
    } catch (e) {
      logger.e('Failed to seed demo data: $e');
    }
  }

  static Future<void> _insert(AppDatabase db, {
    required String id, required String sourceId,
    required String resourceType, required String resourceId,
    required String title, required DateTime date,
    required Map<String, dynamic> raw, String? subjectId,
  }) async {
    await db.into(db.fhirResource).insertOnConflictUpdate(
      FhirResourceCompanion.insert(
        id: id, sourceId: Value(sourceId),
        resourceType: Value(resourceType), resourceId: Value(resourceId),
        title: Value(title), date: Value(date),
        resourceRaw: jsonEncode(raw),
        encounterId: const Value(null), subjectId: Value(subjectId),
      ),
    );
  }

  // ─── FHIR Builders ──────────────────────────────────

  static Map<String, dynamic> _patientFhir() => {
    'resourceType': 'Patient', 'id': _patientId, 'active': true,
    'name': [{'use': 'official', 'family': 'S', 'given': ['Devaganesh'], 'text': 'Devaganesh S'}],
    'gender': 'male', 'birthDate': '2002-06-15',
    'identifier': [
      {'system': 'https://healthid.abdm.gov.in', 'value': _abhaId,
       'type': {'coding': [{'code': 'MR'}], 'text': 'ABHA Number'}},
    ],
    'telecom': [
      {'system': 'phone', 'value': '+91-9876543210', 'use': 'mobile'},
      {'system': 'email', 'value': 'devaganesh.s@email.com', 'use': 'home'},
    ],
    'address': [{'city': 'Chennai', 'state': 'Tamil Nadu', 'postalCode': '600001', 'country': 'India'}],
    'communication': [
      {'language': {'coding': [{'code': 'en', 'display': 'English'}], 'text': 'English'}, 'preferred': true},
      {'language': {'coding': [{'code': 'ta', 'display': 'Tamil'}], 'text': 'Tamil'}},
    ],
  };

  static Map<String, dynamic> _conditionFhir(String display, String code,
      {String clinicalStatus = 'active', String? note}) => {
    'resourceType': 'Condition',
    'clinicalStatus': {'coding': [{'code': clinicalStatus, 'display': clinicalStatus[0].toUpperCase() + clinicalStatus.substring(1)}]},
    'verificationStatus': {'coding': [{'code': 'confirmed', 'display': 'Confirmed'}]},
    'code': {'coding': [{'system': 'http://snomed.info/sct', 'code': code, 'display': display}], 'text': display},
    'subject': {'reference': 'Patient/$_patientId'},
    if (note != null) 'note': [{'text': note}],
  };

  static Map<String, dynamic> _medicationFhir(String display, String code, String dosage,
      {String status = 'active'}) => {
    'resourceType': 'MedicationRequest', 'status': status, 'intent': 'order',
    'medicationCodeableConcept': {'coding': [{'code': code, 'display': display}], 'text': display},
    'subject': {'reference': 'Patient/$_patientId'},
    'dosageInstruction': [{'text': dosage}],
  };

  static Map<String, dynamic> _progressReportFhir(Map<String, dynamic> p) {
    final month = p['m'] as int;
    final lipids = <String>[];
    if (p['tc'] != null) lipids.add('Total Cholesterol: ${p['tc']} mg/dL');
    if (p['tg'] != null) lipids.add('Triglycerides: ${p['tg']} mg/dL');
    if (p['hdl'] != null) lipids.add('HDL: ${p['hdl']} mg/dL');

    final conclusion = '''Month $month Progress Report — Dr. S. Kumar (Internal Medicine)
BP: ${p['bp']} mmHg | Weight: ${p['w']} kg | BMI: ${p['bmi']} | HR: ${p['hr']} bpm
${lipids.isNotEmpty ? 'Lipids: ${lipids.join(', ')}\n' : ''}Medication: ${p['med']}
Exercise: ${p['ex']}
Assessment: ${p['a']}''';

    return {
      'resourceType': 'DiagnosticReport', 'status': 'final',
      'code': {'coding': [{'code': 'PROGRESS', 'display': 'Monthly Progress Report'}],
               'text': 'Month $month Progress Report'},
      'subject': {'reference': 'Patient/$_patientId'},
      'effectiveDateTime': DateTime(2026, month, 15).toIso8601String(),
      'conclusion': conclusion,
      'performer': [{'display': 'Dr. S. Kumar (Internal Medicine)'}],
    };
  }

  static Map<String, dynamic> _imagingReportFhir(Map<String, dynamic> img, String hospital) => {
    'resourceType': 'DiagnosticReport', 'status': 'final',
    'category': [{'coding': [{'code': 'RAD', 'display': 'Radiology'}]}],
    'code': {'coding': [{'display': img['t'] as String}], 'text': '${img['t']} — Month ${img['m']}'},
    'subject': {'reference': 'Patient/$_patientId'},
    'effectiveDateTime': DateTime(2026, img['m'] as int, 10).toIso8601String(),
    'conclusion': '''${img['t']} — Month ${img['m']}
Technique: ${img['tech']}
Findings: ${img['f']}
Impression: ${img['i']}
Radiologist: ${img['r']}
Hospital: $hospital''',
    'performer': [{'display': img['r'] as String}],
  };
}
