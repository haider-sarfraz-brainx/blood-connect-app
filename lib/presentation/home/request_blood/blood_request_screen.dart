import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_bloc.dart';
import '../../../bloc/blood_request_bloc/blood_request_events.dart';
import '../../../bloc/blood_request_bloc/blood_request_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
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
  late ThemeBloc themeBloc;

  // Dedicated bloc instance — isolated from the shared singleton used by HomeScreen
  late BloodRequestBloc _bloc;

  List<BloodRequestModel> _requests = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    themeBloc = sl<ThemeBloc>();

    // Create a dedicated bloc instance so Home screen events never interfere
    _bloc = BloodRequestBloc(sl<SupabaseService>());

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Safe to call immediately — event is queued and processed after the
    // widget tree (including BlocConsumer) is built in the same frame
    _loadRequests();
  }

  void _onTabChanged() {
    // Rebuild to re-filter the already-loaded list when switching tabs
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  void _loadRequests() {
    _bloc.add(const GetBloodRequestsEvent());
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _bloc.close(); // Dispose the dedicated bloc
    super.dispose();
  }

  List<BloodRequestModel> _filterRequestsByStatus(
      List<BloodRequestModel> requests, int tabIndex) {
    switch (tabIndex) {
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
        return requests; // All
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = themeBloc.state.baseTheme;

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
          // Refresh after creating a new request
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
            ),
          );
        }
      },
      builder: (context, state) {
        final filteredRequests =
            _filterRequestsByStatus(_requests, _tabController.index);
        final isInitialLoad = _isLoading && _requests.isEmpty;

        return Scaffold(
          appBar: AppBar(
            title: CustomText(
              text: ViewConstants.requestBlood,
              size: AppConstants.font20Px,
              weight: FontWeight.w600,
            ),
            backgroundColor: baseTheme.background,
            elevation: 0,
          ),
          body: Column(
            children: [
              MediaQuery.removePadding(
                context: context,
                removeLeft: true,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: baseTheme.primary,
                  labelColor: baseTheme.primary,
                  unselectedLabelColor: baseTheme.textColor.fixedOpacity(0.6),
                  padding: EdgeInsets.zero,
                  indicatorPadding: EdgeInsets.zero,
                  tabs: [
                    Tab(text: ViewConstants.all.tr()),
                    Tab(text: ViewConstants.pending.tr()),
                    Tab(text: ViewConstants.inProgress.tr()),
                    Tab(text: ViewConstants.fulfilled.tr()),
                    Tab(text: ViewConstants.cancelled.tr()),
                  ],
                ),
              ),
              Expanded(
                child: isInitialLoad
                    ? ListView.builder(
                        padding: EdgeInsets.all(AppConstants.gap16Px),
                        itemCount: 5,
                        itemBuilder: (context, index) =>
                            const RequestCardSkeleton(),
                      )
                    : filteredRequests.isEmpty
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
                                  text: ViewConstants.noRequestsFound,
                                  size: AppConstants.font18Px,
                                  weight: FontWeight.w600,
                                  textColor:
                                      baseTheme.textColor.fixedOpacity(0.6),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadRequests(),
                            child: Stack(
                              children: [
                                ListView.builder(
                                  padding:
                                      EdgeInsets.all(AppConstants.gap16Px),
                                  itemCount: filteredRequests.length,
                                  itemBuilder: (context, index) {
                                    final request = filteredRequests[index];
                                    return _BloodRequestCard(
                                      request: request,
                                      onTap: () {},
                                    );
                                  },
                                ),
                                if (_isLoading && !isInitialLoad)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: SizedBox(
                                      height: 4,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
              final result = await AppRouter.push<BloodRequestModel>(
                context,
                const CreateBloodScreen(),
              );
              if (result != null) {
                _loadRequests();
              }
            },
            backgroundColor: baseTheme.primary,
            child: Icon(
              Icons.add,
              color: baseTheme.white,
            ),
          ),
        );
      },
    );
  }
}

class _BloodRequestCard extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback onTap;

  const _BloodRequestCard({
    required this.request,
    required this.onTap,
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
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Card(
      margin: EdgeInsets.only(bottom: AppConstants.gap12Px),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
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
                      borderRadius:
                          BorderRadius.circular(AppConstants.radius8Px),
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
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: baseTheme.textColor.fixedOpacity(0.6),
                  ),
                  const SizedBox(width: AppConstants.gap4Px),
                  CustomText(
                    text: dateFormat.format(request.createdAt),
                    size: AppConstants.font12Px,
                    weight: FontWeight.w400,
                    textColor: baseTheme.textColor.fixedOpacity(0.6),
                    translate: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
