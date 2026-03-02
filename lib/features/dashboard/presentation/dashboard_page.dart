import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:health_wallet/core/di/injection.dart';
import 'package:health_wallet/core/theme/app_text_style.dart';
import 'package:health_wallet/features/auth/presentation/care_x_session_provider.dart';
import 'package:health_wallet/features/notifications/bloc/notification_bloc.dart';
import 'package:health_wallet/features/notifications/utils/notification_utils.dart';
import 'package:health_wallet/features/scan/presentation/bloc/scan_bloc.dart';
import 'package:health_wallet/features/chat/presentation/chat_page.dart';
import 'package:health_wallet/features/consent/presentation/consent_page.dart';
import 'package:health_wallet/features/home/presentation/home_page.dart';
import 'package:health_wallet/features/files/presentation/files_page.dart';
import 'package:health_wallet/core/theme/app_insets.dart';
import 'package:health_wallet/core/utils/build_context_extension.dart';
import 'package:health_wallet/features/dashboard/presentation/helpers/page_view_navigation_controller.dart';

@RoutePage()
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final PageViewNavigationController _navigationController;
  bool _isKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    _navigationController = getIt<PageViewNavigationController>();
    _navigationController.currentPageNotifier.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _navigationController.currentPageNotifier.removeListener(_onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    if (_isKeyboardVisible != isKeyboardVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isKeyboardVisible = isKeyboardVisible;
        });
      });
    }

    return BlocListener<ScanBloc, ScanState>(
      listenWhen: (previous, current) =>
          current.notification != null &&
          previous.notification != current.notification,
      listener: (context, state) {
        final notification = state.notification;
        if (notification == null) return;

        final isMapperRoute =
            context.router.current.name == notification.route.routeName;

        context.read<NotificationBloc>().add(
              NotificationAdded(
                  notification: notification.copyWith(read: isMapperRoute)),
            );

        if (!isMapperRoute) {
          showProcessingDoneNotification(context, notification);
        }

        context.read<ScanBloc>().add(const ScanNotificationAcknowledged());
      },
      child: Scaffold(
        body: CareXSessionProvider(
          child: Stack(
            children: [
              PageView.builder(
                controller: _navigationController.pageController,
                onPageChanged: (index) {
                  FocusScope.of(context).unfocus();
                },
                itemCount: 4,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return HomePage(
                        pageController: _navigationController.pageController,
                      );
                    case 1:
                      return const ConsentPage();
                    case 2:
                      return const FilesPage();
                    case 3:
                      return const ChatPage();
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
              if (!_isKeyboardVisible)
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 24,
                  child: SizedBox(
                    height: 60,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.isDarkMode
                                    ? Colors.white.withValues(alpha: 0.03)
                                    : Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: context.isDarkMode
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: 1.0,
                                ),
                                boxShadow: context.isDarkMode
                                    ? [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(Insets.extraSmall),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: _buildNavItem(
                                  context: context,
                                  icon: Icon(
                                    Icons.person_outlined,
                                    size: 24,
                                    color:
                                        _navigationController.currentPage == 0
                                            ? (context.isDarkMode
                                                ? Colors.white
                                                : context.colorScheme.surface)
                                            : context.colorScheme.onSurface,
                                  ),
                                  label: 'Profile',
                                  isSelected:
                                      _navigationController.currentPage == 0,
                                  pageIndex: 0,
                                ),
                              ),
                              Expanded(
                                child: _buildNavItem(
                                  context: context,
                                  icon: Icon(
                                    Icons.verified_user_outlined,
                                    size: 24,
                                    color:
                                        _navigationController.currentPage == 1
                                            ? (context.isDarkMode
                                                ? Colors.white
                                                : context.colorScheme.surface)
                                            : context.colorScheme.onSurface,
                                  ),
                                  label: 'Consent',
                                  isSelected:
                                      _navigationController.currentPage == 1,
                                  pageIndex: 1,
                                ),
                              ),
                              Expanded(
                                child: _buildNavItem(
                                  context: context,
                                  icon: Icon(
                                    Icons.folder_outlined,
                                    size: 24,
                                    color:
                                        _navigationController.currentPage == 2
                                            ? (context.isDarkMode
                                                ? Colors.white
                                                : context.colorScheme.surface)
                                            : context.colorScheme.onSurface,
                                  ),
                                  label: 'Files',
                                  isSelected:
                                      _navigationController.currentPage == 2,
                                  pageIndex: 2,
                                ),
                              ),
                              Expanded(
                                child: _buildNavItem(
                                  context: context,
                                  icon: Icon(
                                    Icons.smart_toy_outlined,
                                    size: 24,
                                    color:
                                        _navigationController.currentPage == 3
                                            ? (context.isDarkMode
                                                ? Colors.white
                                                : context.colorScheme.surface)
                                            : context.colorScheme.onSurface,
                                  ),
                                  label: 'AI Chat',
                                  isSelected:
                                      _navigationController.currentPage == 3,
                                  pageIndex: 3,
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
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required Widget icon,
    required String label,
    required bool isSelected,
    required int pageIndex,
  }) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        _navigationController.jumpToPage(pageIndex);
      },
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? context.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: Insets.extraSmall),
              Text(
                label,
                style: AppTextStyle.labelSmall.copyWith(
                  color: isSelected
                      ? (context.isDarkMode
                          ? Colors.white
                          : context.colorScheme.surface)
                      : context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
