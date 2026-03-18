import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../bloc/donor_bloc/donor_bloc.dart';
import '../../../bloc/donor_bloc/donor_events.dart';
import '../../../bloc/donor_bloc/donor_states.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../config/theme/base.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../core/extensions/color.dart';
import '../../../data/managers/remote/supabase_service.dart';
import '../../../data/models/user_model.dart';
import '../../../injection_container.dart';
import '../../../widgets/custom_text.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/skeleton/donor_card_skeleton.dart';

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({super.key});

  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  late final DonorBloc _bloc;
  late final ThemeBloc _themeBloc;

  final TextEditingController _searchController = TextEditingController();

  List<UserModel> _allDonors = [];
  List<UserModel> _filteredDonors = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _themeBloc = sl<ThemeBloc>();
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
              donor.phone.toLowerCase().contains(query) ||
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
    final baseTheme = _themeBloc.state.baseTheme;

    return BlocConsumer<DonorBloc, DonorState>(
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
        final isInitialLoad = _isLoading && _allDonors.isEmpty;

    return Scaffold(
          backgroundColor: baseTheme.background,
      appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
          text: ViewConstants.donors,
          size: AppConstants.font20Px,
                  weight: FontWeight.w700,
                ),
                if (!isInitialLoad && _allDonors.isNotEmpty)
                  CustomText(
                    text:
                        '${_filteredDonors.length} ${ViewConstants.availableDonors.tr()}',
                    size: AppConstants.font12Px,
                    weight: FontWeight.w400,
                    textColor: baseTheme.primary,
                    translate: false,
                  ),
              ],
        ),
        backgroundColor: baseTheme.background,
        elevation: 0,
      ),
          body: Column(
            children: [
              // ── Search Bar ──────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppConstants.gap16Px,
                  AppConstants.gap8Px,
                  AppConstants.gap16Px,
                  AppConstants.gap12Px,
                ),
                child: CustomTextField(
                  hintText: ViewConstants.searchDonors,
                  controller: _searchController,
                  prefixIcon: Icon(Icons.search, color: baseTheme.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: baseTheme.textColor.fixedOpacity(0.5),
                          ),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),

              // ── List ────────────────────────────────────────────────────
              Expanded(
                child: isInitialLoad
                    ? ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppConstants.gap16Px,
                        ),
                        itemCount: 5,
                        itemBuilder: (_, __) => const DonorCardSkeleton(),
                      )
                    : _filteredDonors.isEmpty
                        ? _buildEmptyState(baseTheme)
                        : RefreshIndicator(
                            onRefresh: () async =>
                                _bloc.add(const GetDonorsEvent()),
                            child: Stack(
                              children: [
                                ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppConstants.gap16Px,
                                    vertical: AppConstants.gap4Px,
                                  ),
                                  itemCount: _filteredDonors.length,
                                  itemBuilder: (context, index) => _DonorCard(
                                    donor: _filteredDonors[index],
                                    onCall: () => _launchCall(
                                        _filteredDonors[index].phone),
                                    onMessage: () => _launchSms(
                                        _filteredDonors[index].phone),
                                  ),
                                ),
                                if (_isLoading && !isInitialLoad)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: SizedBox(
                                      height: 3,
                                      child: LinearProgressIndicator(
                                        backgroundColor: Colors.transparent,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                baseTheme.primary),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BaseTheme baseTheme) {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: baseTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off_rounded : Icons.people_outline,
              size: 48,
              color: baseTheme.primary.fixedOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppConstants.gap20Px),
          CustomText(
            text: isSearching
                ? ViewConstants.noDonorsFound
                : ViewConstants.noDonorsAvailable,
            size: AppConstants.font18Px,
            weight: FontWeight.w700,
            textColor: baseTheme.textColor,
          ),
          const SizedBox(height: AppConstants.gap8Px),
          CustomText(
            text: isSearching
                ? 'Try a different name, blood group or phone'
                : 'Donors who complete their profile will appear here',
            size: AppConstants.font14Px,
            weight: FontWeight.w400,
            textColor: baseTheme.textColor.fixedOpacity(0.5),
            align: TextAlign.center,
            translate: false,
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final UserModel donor;
  final VoidCallback onCall;
  final VoidCallback onMessage;

  const _DonorCard({
    required this.donor,
    required this.onCall,
    required this.onMessage,
  });

  Color _bloodGroupColor(String? bg) {
    switch (bg) {
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

  String _formatLastDonation(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  String? _buildSubtitle(UserModel donor) {
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
    final baseTheme = sl<ThemeBloc>().state.baseTheme;
    final bloodColor = _bloodGroupColor(donor.bloodGroup);
    final initial = donor.name.isNotEmpty ? donor.name[0].toUpperCase() : '?';
    final subtitle = _buildSubtitle(donor);

    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.gap14Px),
      decoration: BoxDecoration(
        color: baseTheme.white,
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radius16Px),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Colored left accent bar ──────────────────────────────
              Container(
                width: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bloodColor, bloodColor.withOpacity(0.5)],
                  ),
                ),
              ),

              // ── Card content ─────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(AppConstants.gap16Px),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top: avatar + info ───────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar with blood group badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      bloodColor.withOpacity(0.2),
                                      bloodColor.withOpacity(0.08),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: bloodColor, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    fontSize: AppConstants.font22Px,
                                    fontWeight: FontWeight.w800,
                                    color: bloodColor,
                                    fontFamily: AppConstants.fontFamilyLato,
                                  ),
                                ),
                              ),
                              // Blood group badge
                              if (donor.bloodGroup != null)
                                Positioned(
                                  bottom: -4,
                                  right: -6,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppConstants.gap6Px,
                                      vertical: AppConstants.gap2Px,
                                    ),
                                    decoration: BoxDecoration(
                                      color: bloodColor,
                                      borderRadius: BorderRadius.circular(
                                          AppConstants.radius8Px),
                                      boxShadow: [
                                        BoxShadow(
                                          color: bloodColor.withOpacity(0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      donor.bloodGroup!,
                                      style: TextStyle(
                                        fontSize: AppConstants.font10Px,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        fontFamily: AppConstants.fontFamilyLato,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: AppConstants.gap14Px),

                          // Name, gender/age, location
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: donor.name,
                                  size: AppConstants.font18Px,
                                  weight: FontWeight.w700,
                                  textColor: baseTheme.textColor,
                                  translate: false,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppConstants.gap4Px),
                                if (subtitle != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 13,
                                        color: baseTheme.textColor
                                            .fixedOpacity(0.5),
                                      ),
                                      const SizedBox(
                                          width: AppConstants.gap4Px),
                                      Expanded(
                                        child: CustomText(
                                          text: subtitle,
                                          size: AppConstants.font13Px,
                                          weight: FontWeight.w500,
                                          textColor: baseTheme.textColor
                                              .fixedOpacity(0.6),
                                          translate: false,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppConstants.gap4Px),
                                ],
                                if (donor.address != null &&
                                    donor.address!.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 13,
                                        color: baseTheme.textColor
                                            .fixedOpacity(0.5),
                                      ),
                                      const SizedBox(
                                          width: AppConstants.gap4Px),
                                      Expanded(
                                        child: CustomText(
                                          text: donor.address!,
                                          size: AppConstants.font12Px,
                                          weight: FontWeight.w400,
                                          textColor: baseTheme.textColor
                                              .fixedOpacity(0.55),
                                          translate: false,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10,),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.call_rounded,
                              label: ViewConstants.call,
                              color: Colors.green,
                              onTap: onCall,
                            ),
                          ),
                          const SizedBox(width: AppConstants.gap10Px),
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.message_rounded,
                              label: ViewConstants.message,
                              color: const Color(0xFF2196F3),
                              onTap: onMessage,
                            ),
                          ),
                        ],
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final double textOpacity;
  final BaseTheme baseTheme;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.baseTheme,
    this.textOpacity = 0.8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radius8Px),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: AppConstants.gap10Px),
        Expanded(
          child: CustomText(
            text: text,
            size: AppConstants.font13Px,
            weight: FontWeight.w500,
            textColor: baseTheme.textColor.fixedOpacity(textOpacity),
            translate: false,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Button (Call / Message)
// ─────────────────────────────────────────────────────────────────────────────

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
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppConstants.radius10Px),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radius10Px),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: AppConstants.gap10Px),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(AppConstants.radius10Px),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: AppConstants.gap6Px),
              CustomText(
                text: label,
                size: AppConstants.font13Px,
                weight: FontWeight.w700,
                textColor: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
