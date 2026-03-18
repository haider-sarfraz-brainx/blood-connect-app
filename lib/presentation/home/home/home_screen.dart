import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_events.dart';
import '../../../bloc/blood_request_bloc/blood_request_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
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
import '../../../widgets/loading_overlay.dart';
import '../../../widgets/skeleton/request_card_skeleton.dart';

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
  bool _isLoadingHomeRequests = false; // Track if we're loading home requests

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
    // Also get current user ID from Supabase as fallback
    final supabaseUserId = supabaseService.client.auth.currentUser?.id;
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      _currentUserId = supabaseUserId;
    }
    _loadRequests();
  }

  void _loadRequests() {
    // Ensure we always have a user ID to exclude
    final userIdToExclude = _currentUserId ?? 
        supabaseService.client.auth.currentUser?.id;
    
    _isLoadingHomeRequests = true; // Mark that we're loading home requests
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
      setState(() {
        _selectedBloodGroup = selectedGroup;
      });
      _loadRequests();
    }
  }

  void _onSearchChanged() {
    _filterRequests();
  }

  void _filterRequests() {
    final searchQuery = _searchController.text.toLowerCase().trim();
    
    if (searchQuery.isEmpty) {
      _filteredRequests = List.from(_allRequests);
    } else {
      _filteredRequests = _allRequests.where((request) {
        return request.patientName.toLowerCase().contains(searchQuery) ||
            request.hospitalName.toLowerCase().contains(searchQuery) ||
            (request.hospitalAddress?.toLowerCase().contains(searchQuery) ?? false);
      }).toList();
    }
    setState(() {});
  }


  Future<void> _handleAcceptRequest(BloodRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeBloc.state.baseTheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        ),
        title: CustomText(
          text: ViewConstants.acceptRequest,
          weight: FontWeight.w700,
          size: AppConstants.font20Px,
        ),
        content: CustomText(
          text: 'Are you sure you want to accept this blood request?',
          size: AppConstants.font16Px,
          translate: false,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: CustomText(
              text: ViewConstants.cancel,
              textColor: themeBloc.state.baseTheme.textColor,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: CustomText(
              text: ViewConstants.accept,
              textColor: themeBloc.state.baseTheme.primary,
              weight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      bloodRequestBloc.add(AcceptBloodRequestEvent(requestId: request.id));
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

    return BlocListener<BloodRequestBloc, BloodRequestState>(
      bloc: bloodRequestBloc,
      listener: (context, state) {
        if (state is BloodRequestUpdated) {
          // Update the local list immediately for better UX
          final updatedRequest = state.request;
          final index = _allRequests.indexWhere((r) => r.id == updatedRequest.id);
          if (index != -1) {
            setState(() {
              _allRequests[index] = updatedRequest;
              _filterRequests(); // Re-filter to update UI
            });
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: ViewConstants.requestAccepted,
                textColor: Colors.white,
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Reload to ensure we have the latest data
          _loadRequests();
        } else if (state is BloodRequestError) {
          // Handle errors from both loading and accepting requests
          if (_isLoadingHomeRequests) {
            _isLoadingHomeRequests = false;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(
                text: state.message,
                textColor: Colors.white,
                translate: false,
              ),
              backgroundColor: Colors.red,
            ),
          );
        } else if (state is BloodRequestsLoaded && _isLoadingHomeRequests) {
          // Only update cache if we were loading home requests
          // Double-check: Filter out user's own requests as a safety measure
          final userIdToExclude = _currentUserId ?? 
              supabaseService.client.auth.currentUser?.id;
          
          _allRequests = state.requests.where((request) {
            if (userIdToExclude != null && userIdToExclude.isNotEmpty) {
              return request.userId != userIdToExclude;
            }
            return true;
          }).toList();
          
          _isLoadingHomeRequests = false;
          _filterRequests();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: CustomText(
            text: ViewConstants.home,
            size: AppConstants.font20Px,
            weight: FontWeight.w600,
          ),
          backgroundColor: baseTheme.background,
          elevation: 0,
        ),
        body: BlocBuilder<BloodRequestBloc, BloodRequestState>(
          bloc: bloodRequestBloc,
          builder: (context, state) {
            // Only show loading if we're actually loading home requests
            final isLoading = _isLoadingHomeRequests && state is BloodRequestLoading;
            final isInitialLoad = isLoading && _allRequests.isEmpty;

            return Column(
              children: [
                // Search Bar
                Padding(
                  padding: EdgeInsets.all(AppConstants.gap16Px),
                  child: CustomTextField(
                    hintText: ViewConstants.searchRequests,
                    controller: _searchController,
                    prefixIcon: Icon(
                      Icons.search,
                      color: baseTheme.primary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: baseTheme.textColor.fixedOpacity(0.5),
                            ),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                ),
                // Blood Group Filter Info
                if (_selectedBloodGroup != null && _selectedBloodGroup!.isNotEmpty)
                  GestureDetector(
                    onTap: _showBloodGroupFilter,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: AppConstants.gap16Px),
                      padding: EdgeInsets.all(AppConstants.gap12Px),
                      decoration: BoxDecoration(
                        color: baseTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                        border: Border.all(
                          color: baseTheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 20,
                            color: baseTheme.primary,
                          ),
                          const SizedBox(width: AppConstants.gap8Px),
                          Expanded(
                            child: Row(
                              children: [
                                CustomText(
                                  text: '${ViewConstants.filterByBloodGroup.tr()}: ',
                                  size: AppConstants.font14Px,
                                  weight: FontWeight.w600,
                                ),
                                CustomText(
                                  text: _selectedBloodGroup!,
                                  size: AppConstants.font14Px,
                                  weight: FontWeight.w700,
                                  textColor: baseTheme.primary,
                                  translate: false,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: baseTheme.primary,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppConstants.gap8Px),
                // Requests List
                Expanded(
                  child: isInitialLoad
                      ? ListView.builder(
                          padding: EdgeInsets.all(AppConstants.gap16Px),
                          itemCount: 5, // Show 5 skeleton loaders
                          itemBuilder: (context, index) {
                            return const RequestCardSkeleton();
                          },
                        )
                      : _filteredRequests.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bloodtype_outlined,
                                    size: 80,
                                    color: baseTheme.textColor.fixedOpacity(0.3),
                                  ),
                                  const SizedBox(height: AppConstants.gap16Px),
                                  CustomText(
                                    text: _searchController.text.isNotEmpty
                                        ? ViewConstants.noRequestsFound
                                        : ViewConstants.noRequestsAvailable,
                                    size: AppConstants.font18Px,
                                    weight: FontWeight.w600,
                                    textColor: baseTheme.textColor.fixedOpacity(0.6),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                _loadRequests();
                              },
                              child: Stack(
                                children: [
                                  ListView.builder(
                                    padding: EdgeInsets.all(AppConstants.gap16Px),
                                    itemCount: _filteredRequests.length,
                                    itemBuilder: (context, index) {
                                      final request = _filteredRequests[index];
                                      return _BloodRequestCard(
                                        request: request,
                                        onAccept: () => _handleAcceptRequest(request),
                                        canAccept: request.status == BloodRequestStatus.pending,
                                      );
                                    },
                                  ),
                                  // Show loading indicator at top when refreshing
                                  if (isLoading && !isInitialLoad)
                                    Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      child: SizedBox(
                                        height: 4,
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.transparent,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            baseTheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback onAccept;
  final bool canAccept;

  const _BloodRequestCard({
    required this.request,
    required this.onAccept,
    required this.canAccept,
  });

  Color _getStatusColor(BloodRequestStatus status, BaseTheme theme) {
    switch (status) {
      case BloodRequestStatus.pending:
        return Colors.orange;
      case BloodRequestStatus.inProgress:
        return Colors.blue;
      case BloodRequestStatus.fulfilled:
        return Colors.green;
      case BloodRequestStatus.cancelled:
        return Colors.red;
    }
  }

  String _getStatusLabel(BloodRequestStatus status) {
    switch (status) {
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

  @override
  Widget build(BuildContext context) {
    final themeBloc = sl<ThemeBloc>();
    final baseTheme = themeBloc.state.baseTheme;
    final statusColor = _getStatusColor(request.status, baseTheme);

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.gap12Px),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.gap16Px),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: request.patientName,
                        size: AppConstants.font18Px,
                        weight: FontWeight.w700,
                        textColor: baseTheme.textColor,
                        translate: false,
                      ),
                      const SizedBox(height: AppConstants.gap4Px),
                      CustomText(
                        text: request.hospitalName,
                        size: AppConstants.font14Px,
                        weight: FontWeight.w400,
                        textColor: baseTheme.textColor.fixedOpacity(0.7),
                        translate: false,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.gap12Px,
                    vertical: AppConstants.gap6Px,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radius8Px),
                    border: Border.all(
                      color: statusColor,
                      width: 1,
                    ),
                  ),
                  child: CustomText(
                    text: _getStatusLabel(request.status),
                    size: AppConstants.font12Px,
                    weight: FontWeight.w600,
                    textColor: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.gap12Px),
            Row(
              children: [
                Icon(
                  Icons.bloodtype,
                  size: 20,
                  color: baseTheme.primary,
                ),
                const SizedBox(width: AppConstants.gap8Px),
                CustomText(
                  text: request.bloodGroup,
                  size: AppConstants.font16Px,
                  weight: FontWeight.w600,
                  textColor: baseTheme.primary,
                  translate: false,
                ),
                const SizedBox(width: AppConstants.gap16Px),
                Icon(
                  Icons.bloodtype_outlined,
                  size: 20,
                  color: baseTheme.textColor.fixedOpacity(0.6),
                ),
                const SizedBox(width: AppConstants.gap8Px),
                CustomText(
                  text: '${request.unitsRequired} ${ViewConstants.units.tr()}',
                  size: AppConstants.font14Px,
                  weight: FontWeight.w400,
                  textColor: baseTheme.textColor.fixedOpacity(0.7),
                ),
              ],
            ),
            if (request.hospitalAddress != null &&
                request.hospitalAddress!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.gap8Px),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: baseTheme.textColor.fixedOpacity(0.6),
                  ),
                  const SizedBox(width: AppConstants.gap8Px),
                  Expanded(
                    child: CustomText(
                      text: request.hospitalAddress!,
                      size: AppConstants.font12Px,
                      weight: FontWeight.w400,
                      textColor: baseTheme.textColor.fixedOpacity(0.6),
                      maxLines: 2,
                      translate: false,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppConstants.gap8Px),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 16,
                  color: baseTheme.textColor.fixedOpacity(0.6),
                ),
                const SizedBox(width: AppConstants.gap8Px),
                CustomText(
                  text: request.contactNumber,
                  size: AppConstants.font12Px,
                  weight: FontWeight.w400,
                  textColor: baseTheme.textColor.fixedOpacity(0.6),
                  translate: false,
                ),
              ],
            ),
            if (canAccept) ...[
              const SizedBox(height: AppConstants.gap16Px),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: baseTheme.primary,
                    padding: EdgeInsets.symmetric(vertical: AppConstants.gap12Px),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                    ),
                  ),
                  child: CustomText(
                    text: ViewConstants.accept,
                    size: AppConstants.font16Px,
                    weight: FontWeight.w700,
                    textColor: baseTheme.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
