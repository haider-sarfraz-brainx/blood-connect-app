import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_events.dart';
import '../../../bloc/blood_request_bloc/blood_request_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../bloc/theme_bloc/theme_states.dart';
import '../../../config/app_router.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/remote/supabase_service.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/skeleton/request_card_skeleton.dart';
import 'create_blood_screen.dart';

class BloodRequestScreen extends StatefulWidget {
  const BloodRequestScreen({super.key});

  @override
  State<BloodRequestScreen> createState() => _BloodRequestScreenState();
}

class _BloodRequestScreenState extends State<BloodRequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late BloodRequestBloc _bloc;

  List<BloodRequestModel> _requests = [];
  bool _isLoading = false;

  static const List<String> _tabKeys = [
    ViewConstants.all,
    ViewConstants.pending,
    ViewConstants.inProgress,
    ViewConstants.fulfilled,
    ViewConstants.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _bloc = BloodRequestBloc(sl<SupabaseService>());
    _tabController = TabController(length: _tabKeys.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadRequests();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) setState(() {});
  }

  void _loadRequests() => _bloc.add(const GetBloodRequestsEvent());

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<BloodRequestModel> _filterByStatus(
      List<BloodRequestModel> requests, int tab) {
    switch (tab) {
      case 1:
        return requests
            .where((r) => r.status == BloodRequestStatus.pending)
            .toList();
      case 2:
        return requests
            .where((r) => r.status == BloodRequestStatus.inProgress)
            .toList();
      case 3:
        return requests
            .where((r) => r.status == BloodRequestStatus.fulfilled)
            .toList();
      case 4:
        return requests
            .where((r) => r.status == BloodRequestStatus.cancelled)
            .toList();
      default:
        return requests;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BloodRequestBloc, BloodRequestState>(
      bloc: _bloc,
      listener: (context, state) {
        if (state is BloodRequestsLoaded) {
          setState(() {
            _requests = state.requests;
            _isLoading = false;
          });
        } else if (state is BloodRequestLoading) {
          setState(() => _isLoading = true);
        } else if (state is BloodRequestCreated) {
          _loadRequests();
        } else if (state is BloodRequestError) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: state.message,
                textColor: Colors.white,
                translate: false,
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              ),
            ),
          );
        }
      },
      builder: (context, _) {
        return BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, themeState) {
            final baseTheme = themeState.baseTheme;
            final filtered = _filterByStatus(_requests, _tabController.index);
            final isInitialLoad = _isLoading && _requests.isEmpty;

            return Scaffold(
              backgroundColor: baseTheme.background,
              appBar: AppBar(
                backgroundColor: baseTheme.background,
                elevation: 0,
                scrolledUnderElevation: 0,
                centerTitle: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: ViewConstants.requestBlood,
                      size: AppConstants.font20Px,
                      weight: FontWeight.w700,
                    ),
                    if (!isInitialLoad && _requests.isNotEmpty)
                      CustomText(
                        text:
                            '${filtered.length} ${ViewConstants.noRequestsFound.tr()}',
                        size: AppConstants.font12Px,
                        weight: FontWeight.w400,
                        textColor: baseTheme.primary,
                        translate: false,
                      ),
                  ],
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _SegmentedTabBar(
                      tabKeys: _tabKeys,
                      controller: _tabController,
                      baseTheme: baseTheme,
                    ),
                  ),
                  const SizedBox(height: AppConstants.gap8Px),
                  Expanded(
                    child: isInitialLoad
                        ? _buildSkeletonList(baseTheme)
                        : filtered.isEmpty
                            ? _buildEmptyState(context, baseTheme)
                            : _buildList(context, baseTheme, filtered),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () async {
                  final result = await AppRouter.push<BloodRequestModel>(
                    context,
                    const CreateBloodScreen(),
                  );
                  if (result != null) _loadRequests();
                },
                backgroundColor: baseTheme.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radius16Px),
                ),
                child: Icon(Icons.add_rounded, color: baseTheme.white, size: 28),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonList(BaseTheme baseTheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: 5,
      itemBuilder: (_, __) => RequestCardSkeleton(baseTheme: baseTheme),
    );
  }

  Widget _buildEmptyState(BuildContext context, BaseTheme baseTheme) {
    return _EmptyState(
      baseTheme: baseTheme,
      isFiltered: _tabController.index != 0,
      onCreateTap: () async {
        final result = await AppRouter.push<BloodRequestModel>(
          context,
          const CreateBloodScreen(),
        );
        if (result != null) _loadRequests();
      },
    );
  }


  Widget _buildList(
    BuildContext context,
    BaseTheme baseTheme,
    List<BloodRequestModel> requests,
  ) {
    return RefreshIndicator(
      color: baseTheme.primary,
      onRefresh: () async => _loadRequests(),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: requests.length,
            itemBuilder: (context, index) => _AnimatedListItem(
              index: index,
              child: _BloodRequestCard(
                request: requests[index],
                baseTheme: baseTheme,
                onTap: (){},
              ),
            ),
          ),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(baseTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  final List<String> tabKeys;
  final TabController controller;
  final BaseTheme baseTheme;

  const _SegmentedTabBar({
    required this.tabKeys,
    required this.controller,
    required this.baseTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: baseTheme.textColor.fixedOpacity(0.06),
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(
            tabKeys.length,
            (i) => _SegmentedTabItem(
              label: tabKeys[i].tr(),
              isSelected: controller.index == i,
              baseTheme: baseTheme,
              onTap: () => controller.animateTo(i),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final BaseTheme baseTheme;
  final VoidCallback onTap;

  const _SegmentedTabItem({
    required this.label,
    required this.isSelected,
    required this.baseTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? baseTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radius8Px),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: baseTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppConstants.fontFamilyLato,
            fontSize: AppConstants.font13Px,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? baseTheme.white
                : baseTheme.textColor.fixedOpacity(0.55),
          ),
        ),
      ),
    );
  }
}

class _AnimatedListItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 250 + (index * 40).clamp(0, 300)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final BaseTheme baseTheme;
  final bool isFiltered;
  final VoidCallback onCreateTap;

  const _EmptyState({
    required this.baseTheme,
    required this.isFiltered,
    required this.onCreateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: baseTheme.disable.fixedOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bloodtype_outlined,
                size: 44,
                color: baseTheme.disable.fixedOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFiltered
                  ? ViewConstants.noRequestsFound.tr()
                  : ViewConstants.noRequestsAvailable.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font18Px,
                fontWeight: FontWeight.w700,
                color: baseTheme.disable,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusStyle(this.background, this.foreground, this.icon);
}

class _BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final BaseTheme baseTheme;
  final VoidCallback onTap;

  const _BloodRequestCard({
    required this.request,
    required this.baseTheme,
    required this.onTap,
  });

  Color get _bloodGroupColor {
    final bg = request.bloodGroup.toUpperCase();
    if (bg.startsWith('AB')) return const Color(0xFF8E24AA);
    if (bg.startsWith('A')) return const Color(0xFFFF6B35);
    if (bg.startsWith('B')) return const Color(0xFF2196F3);
    return const Color(0xFFE53935); 
  }

  _StatusStyle get _statusStyle {
    switch (request.status) {
      case BloodRequestStatus.pending:
        return const _StatusStyle(
          Color(0xFFFFF3E0),
          Color(0xFFE65100),
          Icons.schedule_rounded,
        );
      case BloodRequestStatus.inProgress:
        return const _StatusStyle(
          Color(0xFFE3F2FD),
          Color(0xFF1565C0),
          Icons.sync_rounded,
        );
      case BloodRequestStatus.fulfilled:
        return const _StatusStyle(
          Color(0xFFE8F5E9),
          Color(0xFF2E7D32),
          Icons.check_circle_rounded,
        );
      case BloodRequestStatus.cancelled:
        return const _StatusStyle(
          Color(0xFFFFEBEE),
          Color(0xFFC62828),
          Icons.cancel_rounded,
        );
    }
  }

  String get _statusKey {
    switch (request.status) {
      case BloodRequestStatus.pending:
        return ViewConstants.pending;
      case BloodRequestStatus.inProgress:
        return ViewConstants.inProgress;
      case BloodRequestStatus.fulfilled:
        return ViewConstants.fulfilled;
      case BloodRequestStatus.cancelled:
        return ViewConstants.cancelled;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return DateFormat('MMM d, yyyy').format(dt);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle;
    final bloodColor = _bloodGroupColor;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.gap12Px),
      decoration: BoxDecoration(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radius16Px),
          splashColor: baseTheme.primary.withOpacity(0.05),
          highlightColor: baseTheme.primary.withOpacity(0.02),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.gap16Px),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bloodColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: bloodColor.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        request.bloodGroup,
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: request.bloodGroup.length > 2
                              ? AppConstants.font13Px
                              : AppConstants.font16Px,
                          fontWeight: FontWeight.w800,
                          color: bloodColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.gap12Px),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 2),
                          Text(
                            request.patientName,
                            style: TextStyle(
                              fontFamily: AppConstants.fontFamilyLato,
                              fontSize: AppConstants.font16Px,
                              fontWeight: FontWeight.w700,
                              color: baseTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            request.hospitalName,
                            style: TextStyle(
                              fontFamily: AppConstants.fontFamilyLato,
                              fontSize: AppConstants.font13Px,
                              fontWeight: FontWeight.w500,
                              color: baseTheme.textColor.fixedOpacity(0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppConstants.gap8Px),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusStyle.icon,
                            size: 11,
                            color: statusStyle.foreground,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _statusKey.tr(),
                            style: TextStyle(
                              fontFamily: AppConstants.fontFamilyLato,
                              fontSize: AppConstants.font12Px,
                              fontWeight: FontWeight.w600,
                              color: statusStyle.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.gap14Px),

                Divider(
                  height: 1,
                  thickness: 1,
                  color: baseTheme.textColor.fixedOpacity(0.06),
                ),

                const SizedBox(height: AppConstants.gap12Px),

                Wrap(
                  spacing: AppConstants.gap16Px,
                  runSpacing: AppConstants.gap6Px,
                  children: [
                    _MetaInfo(
                      icon: Icons.water_drop_rounded,
                      text:
                          '${request.unitsRequired} ${ViewConstants.units.tr()}',
                      iconColor: bloodColor,
                      baseTheme: baseTheme,
                    ),
                    if (request.hospitalAddress != null &&
                        request.hospitalAddress!.isNotEmpty)
                      _MetaInfo(
                        icon: Icons.location_on_rounded,
                        text: request.hospitalAddress!,
                        iconColor: baseTheme.textColor.fixedOpacity(0.45),
                        baseTheme: baseTheme,
                        maxWidth: 160,
                      ),
                    _MetaInfo(
                      icon: Icons.phone_rounded,
                      text: request.contactNumber,
                      iconColor: baseTheme.textColor.fixedOpacity(0.45),
                      baseTheme: baseTheme,
                    ),
                  ],
                ),

                const SizedBox(height: AppConstants.gap10Px),

                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: baseTheme.textColor.fixedOpacity(0.35),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(request.createdAt),
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font12Px,
                        fontWeight: FontWeight.w400,
                        color: baseTheme.textColor.fixedOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final BaseTheme baseTheme;
  final double? maxWidth;

  const _MetaInfo({
    required this.icon,
    required this.text,
    required this.iconColor,
    required this.baseTheme,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 200),
          child: Text(
            text,
            style: TextStyle(
              fontFamily: AppConstants.fontFamilyLato,
              fontSize: AppConstants.font12Px,
              fontWeight: FontWeight.w500,
              color: baseTheme.textColor.fixedOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
