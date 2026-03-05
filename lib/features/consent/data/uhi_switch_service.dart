import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── Data Models ─────────────────────────────

/// Consent artifact from UHI-switch.
class UhiConsentArtifact {
  final String consentId;
  final String patientAbhaId;
  final String? doctorId;
  final String hospitalId;
  final String status;
  final String? purpose;
  final List<String> permissions;
  final DateTime? grantedAt;
  final DateTime? expiresAt;
  final bool isEmergency;

  UhiConsentArtifact({
    required this.consentId,
    required this.patientAbhaId,
    this.doctorId,
    required this.hospitalId,
    required this.status,
    this.purpose,
    required this.permissions,
    this.grantedAt,
    this.expiresAt,
    this.isEmergency = false,
  });

  factory UhiConsentArtifact.fromJson(Map<String, dynamic> json) {
    return UhiConsentArtifact(
      consentId: json['consent_id'] as String,
      patientAbhaId: json['patient_abha_id'] ?? '',
      doctorId: json['doctor_id'] as String?,
      hospitalId: json['hospital_id'] as String,
      status: json['status'] as String,
      purpose: json['purpose'] as String?,
      permissions: json['permissions'] != null
          ? List<String>.from(json['permissions'] as List)
          : [],
      grantedAt: json['granted_at'] != null
          ? DateTime.tryParse(json['granted_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      isEmergency: json['is_emergency'] as bool? ?? false,
    );
  }

  bool get isActive =>
      status == 'GRANTED' && (expiresAt?.isAfter(DateTime.now()) ?? false);
  bool get isExpired =>
      status == 'GRANTED' && (expiresAt?.isBefore(DateTime.now()) ?? true);
  bool get isRevoked => status == 'REVOKED';
}

/// Bundle reference from UHI-switch S3 storage.
class UhiBundleRef {
  final String bundleRefId;
  final String sourceHospitalId;
  final int resourceCount;
  final List<String> resourceTypes;
  final DateTime createdAt;
  final DateTime expiresAt;

  UhiBundleRef({
    required this.bundleRefId,
    required this.sourceHospitalId,
    required this.resourceCount,
    required this.resourceTypes,
    required this.createdAt,
    required this.expiresAt,
  });

  factory UhiBundleRef.fromJson(Map<String, dynamic> json) {
    return UhiBundleRef(
      bundleRefId: json['bundle_ref_id'] as String,
      sourceHospitalId: json['source_hospital_id'] as String,
      resourceCount: json['resource_count'] as int? ?? 0,
      resourceTypes: json['resource_types'] != null
          ? List<String>.from(json['resource_types'] as List)
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }
}

/// Patient health summary from UHI-switch.
class UhiPatientSummary {
  final String patientAbhaId;
  final List<String> hospitalsWithData;
  final int totalBundles;
  final int totalResources;
  final List<String> resourceTypes;
  final int activeConsents;
  final int revokedConsents;
  final int totalConsents;

  UhiPatientSummary({
    required this.patientAbhaId,
    required this.hospitalsWithData,
    required this.totalBundles,
    required this.totalResources,
    required this.resourceTypes,
    required this.activeConsents,
    required this.revokedConsents,
    required this.totalConsents,
  });

  factory UhiPatientSummary.fromJson(Map<String, dynamic> json) {
    final ds = json['data_summary'] as Map<String, dynamic>? ?? {};
    final cs = json['consent_summary'] as Map<String, dynamic>? ?? {};
    return UhiPatientSummary(
      patientAbhaId: json['patient_abha_id'] as String? ?? '',
      hospitalsWithData: ds['hospitals_with_data'] != null
          ? List<String>.from(ds['hospitals_with_data'] as List)
          : [],
      totalBundles: ds['total_bundles'] as int? ?? 0,
      totalResources: ds['total_resources'] as int? ?? 0,
      resourceTypes: ds['resource_types'] != null
          ? List<String>.from(ds['resource_types'] as List)
          : [],
      activeConsents: cs['active'] as int? ?? 0,
      revokedConsents: cs['revoked'] as int? ?? 0,
      totalConsents: cs['total'] as int? ?? 0,
    );
  }
}

/// Hospital registered with UHI-switch.
class UhiHospital {
  final String hospitalId;
  final String name;
  final String? city;
  final String? state;
  final bool isActive;

  UhiHospital({
    required this.hospitalId,
    required this.name,
    this.city,
    this.state,
    this.isActive = true,
  });

  factory UhiHospital.fromJson(Map<String, dynamic> json) {
    return UhiHospital(
      hospitalId: json['hospital_id'] as String,
      name: json['name'] as String,
      city: json['city'] as String?,
      state: json['state'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

// ─── Service ─────────────────────────────

/// HTTP client for the UHI-Switch server.
///
/// Communicates with the FastAPI server deployed on Railway.
/// Uses the /app/ endpoints designed for the mobile app.
class UhiSwitchService {
  /// Live Railway deployment
  static const String baseUrl =
      'https://uhi-switch-production.up.railway.app';

  static final _client = http.Client();

  // ─── Health ─────────────────────────────

  static Future<bool> isServerReachable() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Hospitals ─────────────────────────────

  /// List all registered hospitals.
  static Future<List<UhiHospital>> listHospitals() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/hospital/list'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => UhiHospital.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to list hospitals: ${response.statusCode}');
    }
  }

  // ─── Patient Bundles ─────────────────────────────

  /// Get all available bundles for a patient across hospitals.
  static Future<List<UhiBundleRef>> getPatientBundles(String abhaId) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/app/patient/$abhaId/bundles'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final bundles = json['bundles'] as List<dynamic>? ?? [];
      return bundles
          .map((e) => UhiBundleRef.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to get bundles: ${response.statusCode}');
    }
  }

  // ─── Patient Summary ─────────────────────────────

  /// Get cross-hospital health data summary for a patient.
  static Future<UhiPatientSummary> getPatientSummary(String abhaId) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/app/patient/$abhaId/summary'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return UhiPatientSummary.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Failed to get summary: ${response.statusCode}');
    }
  }

  // ─── Consents ─────────────────────────────

  /// List all consents for a patient (active, revoked, expired).
  static Future<List<UhiConsentArtifact>> listConsents(
      String patientAbhaId) async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/app/patient/$patientAbhaId/consents'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final consents = json['consents'] as List<dynamic>? ?? [];
      return consents
          .map(
              (e) => UhiConsentArtifact.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to list consents: ${response.statusCode}');
    }
  }

  /// Grant consent from the mobile app (patient-initiated).
  static Future<Map<String, dynamic>> grantConsent({
    required String patientAbhaId,
    required String requestingHospitalId,
    String purpose = 'diagnosis',
    List<String> permissions = const [
      'Patient',
      'Observation',
      'DiagnosticReport',
      'Condition',
      'MedicationRequest',
      'AllergyIntolerance'
    ],
    int validHours = 24,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/app/consent/grant'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'patient_abha_id': patientAbhaId,
            'requesting_hospital_id': requestingHospitalId,
            'purpose': purpose,
            'permissions': permissions,
            'valid_hours': validHours,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to grant consent: ${response.statusCode}');
    }
  }

  /// Revoke a consent from the mobile app.
  static Future<Map<String, dynamic>> revokeConsent(String consentId) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl/app/consent/$consentId/revoke'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to revoke consent: ${response.statusCode}');
    }
  }

  // ─── Audit ─────────────────────────────

  /// Verify audit chain integrity.
  static Future<Map<String, dynamic>> verifyAuditChain() async {
    final response = await _client
        .get(
          Uri.parse('$baseUrl/audit/verify'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to verify audit: ${response.statusCode}');
    }
  }
}
