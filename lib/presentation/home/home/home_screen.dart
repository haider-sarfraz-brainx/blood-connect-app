import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_bloc.dart';
import '../../../bloc/authentication_bloc/authentication_states.dart';
import '../../../bloc/blood_request_bloc/blood_request_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_events.dart';
import '../../../bloc/blood_request_bloc/blood_request_states.dart';
import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../bloc/theme_bloc/theme_states.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/local/session_manager.dart';
import '../../../data/managers/remote/supabase_service.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../injection_container.dart';
import '../../../widgets/bottom_sheets/blood_group_filter_bottom_sheet.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/skeleton/request_card_skeleton.dart';
import '../donors/widgets/greeting_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  final _searchController = TextEditingController();
  late ThemeBloc themeBloc;
  late BloodRequestBloc bloodRequestBloc;
  late SessionManager sessionManager;
  late SupabaseService supabaseService;

  String? _userBloodGroup;
  String? _selectedBloodGroup;
  String? _currentUserId;
  List<BloodRequestModel> _allRequests = [];
  List<BloodRequestModel> _filteredRequests = [];
  bool _isLoadingHomeRequests = false;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();
    bloodRequestBloc = sl<BloodRequestBloc>();
    sessionManager = sl<SessionManager>();
    supabaseService = sl<SupabaseService>();
    _initializeUserData();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeUserData() {
    final user = sessionManager.getUser();
    if (user != null) {
      _userBloodGroup = user.bloodGroup;
      _selectedBloodGroup = user.bloodGroup;
      _currentUserId = user.id;
    }
    final supabaseUserId = supabaseService.client.auth.currentUser?.id;
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _currentUserId = supabaseUserId;
    }
    _loadRequests();
  }

  void _loadRequests() {
    final userIdToExclude =
        _currentUserId ?? supabaseService.client.auth.currentUser?.id;
    _isLoadingHomeRequests = true;
    bloodRequestBloc.add(GetBloodRequestsForHomeEvent(
      bloodGroup: _selectedBloodGroup,
      excludeUserId: userIdToExclude,
    ));
  }

  Future<void> _showBloodGroupFilter() async {
    final selectedGroup = await BloodGroupFilterBottomSheet.show(
      context: context,
      selectedBloodGroup: _selectedBloodGroup,
    );
    if (selectedGroup != null) {
      setState(() => _selectedBloodGroup = selectedGroup);
      _loadRequests();
    }
  }

  void _onSearchChanged() => _filterRequests();

  void _filterRequests() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredRequests = List.from(_allRequests);
    } else {
      _filteredRequests = _allRequests.where((r) {
        return r.patientName.toLowerCase().contains(query) ||
            r.hospitalName.toLowerCase().contains(query) ||
            (r.hospitalAddress?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    setState(() {});
  }

  Future<void> _handleAcceptRequest(
      BuildContext context,
      BloodRequestModel request,
      BaseTheme baseTheme,
      ) async {
    showDialog(
      context: context,
      builder: (_) => GreetingDialog(
        recipientName: request.patientName,
        onSend: (message) {
          
          context.read<BloodRequestBloc>().add(UpdateBloodRequestStatusEvent(
                requestId: request.id,
                status: BloodRequestStatus.offered,
              ));

          sl<MessagingBloc>().add(CreateConversationEvent(
            recipientId: request.userId,
            requestId: request.id,
            initialMessage: message,
          ));
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your help request with greeting has been sent!')),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BloodRequestBloc, BloodRequestState>(
      bloc: bloodRequestBloc,
      listener: (context, state) {
        if (state is BloodRequestUpdated) {
          final updatedRequest = state.request;
          final index =
              _allRequests.indexWhere((r) => r.id == updatedRequest.id);
          if (index != -1) {
            setState(() {
              _allRequests[index] = updatedRequest;
              _filterRequests();
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: ViewConstants.requestAccepted,
                textColor: Colors.white,
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radius12Px),
              ),
            ),
          );
          _loadRequests();
        } else if (state is BloodRequestError) {
          if (_isLoadingHomeRequests) _isLoadingHomeRequests = false;
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
        } else if (state is BloodRequestsLoaded && _isLoadingHomeRequests) {
          final userIdToExclude =
              _currentUserId ?? supabaseService.client.auth.currentUser?.id;
          _allRequests = state.requests.where((r) {
            if (userIdToExclude != null && userIdToExclude.isNotEmpty) {
              return r.userId != userIdToExclude;
            }
            return true;
          }).toList();
          _isLoadingHomeRequests = false;
          _filterRequests();
        }
      },
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          final baseTheme = themeState.baseTheme;

          return Scaffold(
            backgroundColor: baseTheme.background,
            appBar: AppBar(
              backgroundColor: baseTheme.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              title: CustomText(
                text: ViewConstants.home,
                size: AppConstants.font20Px,
                weight: FontWeight.w700,
              ),
              centerTitle: false,
            ),
            body: BlocBuilder<BloodRequestBloc, BloodRequestState>(
              bloc: bloodRequestBloc,
              builder: (context, state) {
                final isLoading = _isLoadingHomeRequests &&
                    state is BloodRequestLoading;
                final isInitialLoad =
                    isLoading && _allRequests.isEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: CustomTextField(
                        hintText: ViewConstants.searchRequests,
                        controller: _searchController,
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: baseTheme.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color:
                                      baseTheme.textColor.fixedOpacity(0.5),
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          _FilterChip(
                            label: (_selectedBloodGroup != null &&
                                    _selectedBloodGroup!.isNotEmpty)
                                ? _selectedBloodGroup!
                                : ViewConstants.filterByBloodGroup.tr(),
                            isActive: _selectedBloodGroup != null &&
                                _selectedBloodGroup!.isNotEmpty,
                            onTap: _showBloodGroupFilter,
                            baseTheme: baseTheme,
                          ),
                          const Spacer(),
                          if (!isInitialLoad && _allRequests.isNotEmpty)
                            Text(
                              '${_filteredRequests.length} '
                              '${ViewConstants.noRequestsFound.tr()}',
                              style: TextStyle(
                                fontFamily: AppConstants.fontFamilyLato,
                                fontSize: AppConstants.font12Px,
                                fontWeight: FontWeight.w500,
                                color:
                                    baseTheme.textColor.fixedOpacity(0.4),
                              ),
                            ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: isInitialLoad
                          ? _buildSkeletonList(baseTheme)
                          : _filteredRequests.isEmpty
                              ? _buildEmptyState(baseTheme)
                              : _buildList(
                                  baseTheme, isLoading, isInitialLoad),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonList(BaseTheme baseTheme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: 5,
      itemBuilder: (_, __) => RequestCardSkeleton(baseTheme: baseTheme),
    );
  }

  Widget _buildEmptyState(BaseTheme baseTheme) {
    final isSearching = _searchController.text.isNotEmpty;
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
              isSearching
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

  Widget _buildList(
      BaseTheme baseTheme, bool isLoading, bool isInitialLoad) {
    return RefreshIndicator(
      color: baseTheme.primary,
      onRefresh: () async => _loadRequests(),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: _filteredRequests.length,
            itemBuilder: (context, index) {
              final request = _filteredRequests[index];
              return _AnimatedListItem(
                index: index,
                child: _HomeRequestCard(
                  request: request,
                  baseTheme: baseTheme,
                  onAccept: () => _handleAcceptRequest(context,request, themeBloc.state.baseTheme),
                  canAccept: request.status == BloodRequestStatus.pending,
                ),
              );
            },
          ),
          if (isLoading && !isInitialLoad)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 3,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor:
                      AlwaysStoppedAnimation(baseTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final BaseTheme baseTheme;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.baseTheme,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = baseTheme.primary;
    final inactiveColor = baseTheme.textColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withOpacity(0.08)
              : inactiveColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? activeColor.withOpacity(0.22)
                : inactiveColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.water_drop_rounded,
              size: 13,
              color: isActive
                  ? activeColor
                  : inactiveColor.withOpacity(0.45),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font13Px,
                fontWeight: FontWeight.w600,
                color: isActive
                    ? activeColor
                    : inactiveColor.withOpacity(0.55),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isActive
                  ? activeColor
                  : inactiveColor.withOpacity(0.45),
            ),
          ],
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
      duration:
          Duration(milliseconds: 250 + (index * 40).clamp(0, 300)),
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

class _StatusStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusStyle(this.background, this.foreground, this.icon);
}

class _HomeRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final BaseTheme baseTheme;
  final VoidCallback onAccept;
  final bool canAccept;

  const _HomeRequestCard({
    required this.request,
    required this.baseTheme,
    required this.onAccept,
    required this.canAccept,
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
      case BloodRequestStatus.offered:
        return const _StatusStyle(
          Color(0xFFFFF7E6),
          Color(0xFFFAAD14),
          Icons.local_offer_rounded,
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
      case BloodRequestStatus.offered:
        return 'Offered';
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
          onTap: canAccept ? onAccept : null,
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
                              color:
                                  baseTheme.textColor.fixedOpacity(0.5),
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
                        iconColor:
                            baseTheme.textColor.fixedOpacity(0.45),
                        baseTheme: baseTheme,
                        maxWidth: 160,
                      ),
                    _MetaInfo(
                      icon: Icons.phone_rounded,
                      text: (request.status == BloodRequestStatus.pending || request.status == BloodRequestStatus.offered)
                          ? 'Contact hidden'
                          : request.contactNumber,
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

                if (canAccept) ...[
                  const SizedBox(height: AppConstants.gap14Px),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: baseTheme.textColor.fixedOpacity(0.06),
                  ),
                  const SizedBox(height: AppConstants.gap14Px),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onAccept,
                      icon: Icon(
                        Icons.volunteer_activism_rounded,
                        size: 16,
                        color: baseTheme.white,
                      ),
                      label: Text(
                        ViewConstants.accept.tr(),
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: AppConstants.font14Px,
                          fontWeight: FontWeight.w700,
                          color: baseTheme.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: baseTheme.primary,
                        foregroundColor: baseTheme.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radius16Px,
                          ),
                        ),
                        elevation: 0,
                        shadowColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
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
