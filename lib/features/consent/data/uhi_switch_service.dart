import 'dart:convert';
import 'package:http/http.dart' as http;

/// Data model matching the UHI-switch server consent artifact.
class UhiConsentArtifact {
  final String consentId;
  final String patientAbhaId;
  final String doctorId;
  final String hospitalId;
  final String status;
  final List<String> permissions;
  final DateTime grantedAt;
  final DateTime expiresAt;

  UhiConsentArtifact({
    required this.consentId,
    required this.patientAbhaId,
    required this.doctorId,
    required this.hospitalId,
    required this.status,
    required this.permissions,
    required this.grantedAt,
    required this.expiresAt,
  });

  factory UhiConsentArtifact.fromJson(Map<String, dynamic> json) {
    return UhiConsentArtifact(
      consentId: json['consent_id'] as String,
      patientAbhaId: json['patient_abha_id'] as String,
      doctorId: json['doctor_id'] as String,
      hospitalId: json['hospital_id'] as String,
      status: json['status'] as String,
      permissions: List<String>.from(json['permissions'] as List),
      grantedAt: DateTime.parse(json['granted_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  bool get isActive {
    return status == 'GRANTED' && expiresAt.isAfter(DateTime.now());
  }

  bool get isExpired {
    return status == 'GRANTED' && expiresAt.isBefore(DateTime.now());
  }
}

class UhiConsentGrantRequest {
  final String patientAbhaId;
  final String doctorId;
  final String hospitalId;
  final List<String> permissions;
  final DateTime expiresAt;

  const UhiConsentGrantRequest({
    required this.patientAbhaId,
    required this.doctorId,
    required this.hospitalId,
    required this.permissions,
    required this.expiresAt,
  });

  Map<String, dynamic> toJson() => {
        'patient_abha_id': patientAbhaId,
        'doctor_id': doctorId,
        'hospital_id': hospitalId,
        'permissions': permissions,
        'expires_at': expiresAt.toUtc().toIso8601String(),
      };
}

/// HTTP client for the UHI-Switch key store manager server.
///
/// Communicates with the FastAPI server at [baseUrl] to grant and list
/// consent artifacts for inter-hospital health data sharing.
class UhiSwitchService {
  /// Base URL of the UHI-switch FastAPI server.
  /// For Android emulator use http://10.0.2.2:8000
  /// For physical devices use your server's LAN IP or public URL.
  static const String baseUrl = 'http://10.0.2.2:8000';

  static final _client = http.Client();

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

  /// Fetch all consent artifacts for [patientAbhaId].
  static Future<List<UhiConsentArtifact>> listConsents(
      String patientAbhaId) async {
    final uri = Uri.parse('$baseUrl/consent/list')
        .replace(queryParameters: {'patient_abha_id': patientAbhaId});

    final response = await _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => UhiConsentArtifact.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(
          'Failed to fetch consents: ${response.statusCode} ${response.body}');
    }
  }

  /// Grant a new consent artifact via the UHI-switch server.
  static Future<UhiConsentArtifact> grantConsent(
      UhiConsentGrantRequest request) async {
    final uri = Uri.parse('$baseUrl/consent/grant');

    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(request.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return UhiConsentArtifact.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception(
          'Failed to grant consent: ${response.statusCode} ${response.body}');
    }
  }
}
