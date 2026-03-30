import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../bloc/donor_bloc/donor_bloc.dart';
import '../../../bloc/donor_bloc/donor_events.dart';
import '../../../bloc/donor_bloc/donor_states.dart';
import '../../../bloc/messaging_bloc/messaging_bloc.dart';
import '../../../bloc/messaging_bloc/messaging_events.dart';
import '../../../bloc/messaging_bloc/messaging_states.dart';
import '../../../injection_container.dart';
import '../messaging/chat_screen.dart';
import './widgets/greeting_dialog.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../bloc/theme_bloc/theme_states.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/remote/supabase_service.dart';
import '../../../data/models/user_model.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/skeleton/donor_card_skeleton.dart';

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({super.key});

  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  late final DonorBloc _bloc;
  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allDonors = [];
  List<UserModel> _filteredDonors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bloc = DonorBloc(sl<SupabaseService>());
    _searchController.addListener(_onSearchChanged);
    _bloc.add(const GetDonorsEvent());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onSearchChanged() => _applySearch();

  void _applySearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredDonors = List.from(_allDonors);
      } else {
        _filteredDonors = _allDonors.where((donor) {
          return donor.name.toLowerCase().contains(query) ||
              (donor.bloodGroup?.toLowerCase().contains(query) ?? false) ||
              (donor.phone?.toLowerCase().contains(query) ?? false) ||
              (donor.address?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchSms(String phone) async {
    final uri = Uri(scheme: 'sms', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DonorBloc, DonorState>(
          bloc: _bloc,
          listener: (context, state) {
            if (state is DonorLoading) {
              setState(() => _isLoading = true);
            } else if (state is DonorsLoaded) {
              setState(() {
                _isLoading = false;
                _allDonors = state.donors;
                _filteredDonors = List.from(state.donors);
                if (_searchController.text.isNotEmpty) _applySearch();
              });
            } else if (state is DonorError) {
              setState(() => _isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
                    style: const TextStyle(color: Colors.white),
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
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
            final baseTheme = themeState.baseTheme;
            final isInitialLoad = _isLoading && _allDonors.isEmpty;

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
                    Text(
                      ViewConstants.donors.tr(),
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font20Px,
                        fontWeight: FontWeight.w700,
                        color: baseTheme.textColor,
                      ),
                    ),
                    if (!isInitialLoad && _allDonors.isNotEmpty)
                      Text(
                        '${_filteredDonors.length} '
                        '${ViewConstants.availableDonors.tr()}',
                        style: TextStyle(
                          fontFamily: AppConstants.fontFamilyLato,
                          fontSize: AppConstants.font12Px,
                          fontWeight: FontWeight.w400,
                          color: baseTheme.textColor.fixedOpacity(0.4),
                        ),
                      ),
                  ],
                ),
              ),
              body: Column(
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: CustomTextField(
                      hintText: ViewConstants.searchDonors,
                      controller: _searchController,
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: baseTheme.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: baseTheme.textColor.fixedOpacity(0.5),
                              ),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                    ),
                  ),

                  Expanded(
                    child: isInitialLoad
                        ? _buildSkeletonList(baseTheme)
                        : _filteredDonors.isEmpty
                            ? _buildEmptyState(baseTheme)
                            : _buildList(baseTheme),
                  ),
                ],
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
      itemBuilder: (_, __) => DonorCardSkeleton(baseTheme: baseTheme),
    );
  }

  Widget _buildList(BaseTheme baseTheme) {
    return RefreshIndicator(
      color: baseTheme.primary,
      onRefresh: () async => _bloc.add(const GetDonorsEvent()),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: _filteredDonors.length,
            itemBuilder: (context, index) {
              final donor = _filteredDonors[index];
              return _AnimatedListItem(
                index: index,
                child: _DonorCard(
                  donor: donor,
                  baseTheme: baseTheme,
                  onCall: donor.phone != null ? () => _launchCall(donor.phone!) : null,
                  onMessage: donor.phone != null ? () => _launchSms(donor.phone!) : null,
                ),
              );
            },
          ),
          if (_isLoading && _allDonors.isNotEmpty)
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
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.people_outline_rounded,
                size: 44,
                color: baseTheme.disable.fixedOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching
                  ? ViewConstants.noDonorsFound.tr()
                  : ViewConstants.noDonorsAvailable.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font18Px,
                fontWeight: FontWeight.w700,
                color: baseTheme.disable,
              ),
            ),
            const SizedBox(height: AppConstants.gap8Px),
            Text(
              isSearching
                  ? 'Try a different name, blood group or phone'
                  : 'Donors who complete their profile will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font14Px,
                fontWeight: FontWeight.w400,
                color: baseTheme.textColor.fixedOpacity(0.5),
              ),
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

class _DonorCard extends StatelessWidget {
  final UserModel donor;
  final BaseTheme baseTheme;
  final VoidCallback? onCall;
  final VoidCallback? onMessage;

  const _DonorCard({
    required this.donor,
    required this.baseTheme,
    this.onCall,
    this.onMessage,
  });

  Color get _bloodColor {
    switch (donor.bloodGroup?.toUpperCase()) {
      case 'A+':
      case 'A-':
        return const Color(0xFFFF6B35);
      case 'B+':
      case 'B-':
        return const Color(0xFF2196F3);
      case 'O+':
      case 'O-':
        return const Color(0xFFE53935);
      case 'AB+':
      case 'AB-':
        return const Color(0xFF8E24AA);
      default:
        return const Color(0xFFE53935);
    }
  }

  String? get _subtitle {
    final parts = <String>[];
    if (donor.gender != null && donor.gender!.isNotEmpty) {
      parts.add(donor.gender!);
    }
    if (donor.age != null) {
      parts.add('${donor.age} ${ViewConstants.yearsOld.tr()}');
    }
    return parts.isEmpty ? null : parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    final bloodColor = _bloodColor;
    final initial =
        donor.name.isNotEmpty ? donor.name[0].toUpperCase() : '?';

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
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        bloodColor.withOpacity(0.18),
                        bloodColor.withOpacity(0.07),
                      ],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: bloodColor.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontFamily: AppConstants.fontFamilyLato,
                      fontSize: AppConstants.font20Px,
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
                        donor.name,
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
                        ViewConstants.verifiedDonor.tr(),
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

                if (donor.bloodGroup != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: bloodColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      donor.bloodGroup!,
                      style: TextStyle(
                        fontFamily: AppConstants.fontFamilyLato,
                        fontSize: AppConstants.font12Px,
                        fontWeight: FontWeight.w700,
                        color: bloodColor,
                      ),
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
              runSpacing: AppConstants.gap8Px,
              children: [
                _MetaInfo(
                  icon: Icons.person_outline_rounded,
                  text: 'Gender hidden',
                  iconColor: baseTheme.textColor.fixedOpacity(0.45),
                  baseTheme: baseTheme,
                ),
                _MetaInfo(
                  icon: Icons.event_rounded,
                  text: 'Age hidden',
                  iconColor: baseTheme.textColor.fixedOpacity(0.45),
                  baseTheme: baseTheme,
                ),
                _MetaInfo(
                  icon: Icons.location_on_outlined,
                  text: 'Address hidden',
                  iconColor: baseTheme.textColor.fixedOpacity(0.45),
                  baseTheme: baseTheme,
                  maxWidth: 140,
                ),
              ],
            ),

            const SizedBox(height: AppConstants.gap16Px),

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Request Contribution',
                    color: baseTheme.primary,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => GreetingDialog(
                          recipientName: donor.name,
                          onSend: (message) {
                            sl<MessagingBloc>().add(CreateConversationEvent(
                              recipientId: donor.id,
                              initialMessage: message,
                            ));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ViewConstants.helpRequestSent.tr(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.radius12Px),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.fixedOpacity(0.08),
      borderRadius: BorderRadius.circular(AppConstants.radius12Px),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius12Px),
        splashColor: color.fixedOpacity(0.16),
        highlightColor: color.fixedOpacity(0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: AppConstants.gap6Px),
              Text(
                label.tr(),
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: AppConstants.font13Px,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
