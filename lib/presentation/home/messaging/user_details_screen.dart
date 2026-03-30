import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/view_constants.dart';
import '../../../data/models/user_model.dart';
import '../../../config/theme/base.dart';
import '../../../bloc/theme_bloc/theme_bloc.dart';
import '../../../injection_container.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final baseTheme = sl<ThemeBloc>().state.baseTheme;

    return Scaffold(
      backgroundColor: baseTheme.background,
      appBar: AppBar(
        title: Text(
          ViewConstants.userDetails.tr(),
          style: TextStyle(
            fontFamily: AppConstants.fontFamilyLato,
            fontSize: AppConstants.font18Px,
            fontWeight: FontWeight.w700,
            color: baseTheme.textColor,
          ),
        ),
        backgroundColor: baseTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: baseTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: baseTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontFamily: AppConstants.fontFamilyLato,
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: baseTheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: TextStyle(
                fontFamily: AppConstants.fontFamilyLato,
                fontSize: AppConstants.font24Px,
                fontWeight: FontWeight.w700,
                color: baseTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            if (user.bloodGroup != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.bloodGroup!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 32),
            _buildInfoTile(
              Icons.email_outlined,
              ViewConstants.email.tr(),
              user.email,
              baseTheme,
            ),
            if (user.phone != null)
              _buildInfoTile(
                Icons.phone_outlined,
                ViewConstants.phoneNumber.tr(),
                user.phone!,
                baseTheme,
              ),
            if (user.gender != null)
              _buildInfoTile(
                Icons.person_outline_rounded,
                ViewConstants.gender.tr(),
                user.gender!.tr(),
                baseTheme,
              ),
            if (user.address != null)
              _buildInfoTile(
                Icons.location_on_outlined,
                ViewConstants.address.tr(),
                user.address!,
                baseTheme,
              ),
            if (user.age != null)
              _buildInfoTile(
                Icons.calendar_today_outlined,
                'Age',
                '${user.age} ${ViewConstants.yearsOld.tr()}',
                baseTheme,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, BaseTheme baseTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: baseTheme.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: baseTheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: 12,
                  color: baseTheme.textColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontFamily: AppConstants.fontFamilyLato,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: baseTheme.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
