import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:health_wallet/features/auth/presentation/login_page.dart';
import 'package:health_wallet/features/dashboard/presentation/dashboard_page.dart';
import 'package:health_wallet/features/scan/presentation/pages/processing/processing_page.dart';
import 'package:health_wallet/features/scan/presentation/pages/focus_mode/focus_mode_page.dart';
import 'package:health_wallet/features/chat/presentation/chat_page.dart';
import 'package:health_wallet/features/consent/presentation/consent_page.dart';
import 'package:health_wallet/features/files/presentation/files_page.dart';
import 'package:health_wallet/features/scan/presentation/pages/load_model/load_model_page.dart';
import 'package:health_wallet/features/home/presentation/home_page.dart';
import 'package:health_wallet/features/sync/presentation/sync_page.dart';

import 'package:health_wallet/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:health_wallet/features/onboarding/presentation/pages/splash_page.dart';
import 'package:health_wallet/features/records/domain/entity/entity.dart';
import 'package:health_wallet/features/records/presentation/pages/record_detail_page.dart';
import 'package:health_wallet/features/user/presentation/pages/privacy_policy_page.dart';
import 'package:health_wallet/features/records/presentation/pages/records_page.dart';
import 'package:injectable/injectable.dart';

part 'app_router.gr.dart';

@LazySingleton()
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: SplashRoute.page, initial: true),
        AutoRoute(page: OnboardingRoute.page),
        AutoRoute(page: LoginRoute.page),
        AutoRoute(
          page: DashboardRoute.page,
          children: [
            AutoRoute(page: HomeRoute.page),
            AutoRoute(page: ConsentRoute.page),
            AutoRoute(page: FilesRoute.page),
            AutoRoute(page: ChatRoute.page),
          ],
        ),
        AutoRoute(page: RecordDetailsRoute.page),
        AutoRoute(page: RecordsRoute.page),
        AutoRoute(page: PrivacyPolicyRoute.page),
        AutoRoute(page: LoadModelRoute.page),
        AutoRoute(page: ProcessingRoute.page),
        AutoRoute(page: FocusModeRoute.page),
        // SyncRoute kept for backward compatibility; not exposed in navigation
        AutoRoute(page: SyncRoute.page),
      ];
}
