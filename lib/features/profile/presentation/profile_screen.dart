import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_translations.dart';
import '../../../core/localization/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/avatar_image_helper.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/fb_appearance_selector.dart';
import '../../../core/widgets/app_update_dialog.dart';
import '../../../core/widgets/fb_button.dart';
import '../../authentication/presentation/auth_provider.dart';
import '../../authentication/presentation/widgets/terms_and_conditions_modal.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.profile),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: tr.language,
            onPressed: () => showLanguageBottomSheet(context),
          ),
          IconButton(
            icon: Icon(themeProvider.appearanceIcon),
            tooltip: tr.appearance,
            onPressed: () => showAppearanceBottomSheet(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          // User Card with Modern Glass/Shadow styling
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primaryGreen.withOpacity(0.15),
                      backgroundImage: _resolveAvatar(user?.avatarUrl),
                      child: (user?.avatarUrl == null || user!.avatarUrl!.isEmpty)
                          ? const Icon(Icons.person, color: AppColors.primaryGreen, size: 36)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'FoodBridge Member',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${user?.role.displayName ?? "Donor"} ${user?.organizationName != null ? "• ${user!.organizationName}" : ""}',
                            style: const TextStyle(fontSize: 13, color: AppColors.mutedGrey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phone ?? user?.email ?? 'contact@foodbridge.org',
                            style: const TextStyle(fontSize: 12, color: AppColors.mutedGrey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryGreen),
                    label: const Text(
                      'Edit Profile (प्रोफाइल संपादित करा)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGreen, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance: Light / Dark / System (User requirement)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${tr.appearance.toUpperCase()} (LIGHT / DARK / SYSTEM)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.mutedGrey,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : AppColors.primaryGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  themeProvider.appearanceName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const FBAppearanceSelector(compact: false),
          const SizedBox(height: 24),

          // Language: English / Hindi / Marathi (User requirement)
          Text(
            tr.get('language').toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedGrey,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                _languageRadioTile(
                  context: context,
                  code: 'en',
                  title: 'English',
                  subtitle: 'Primary Language',
                  isSelected: localeProvider.locale.languageCode == 'en',
                ),
                const Divider(height: 1),
                _languageRadioTile(
                  context: context,
                  code: 'hi',
                  title: 'हिंदी (Hindi)',
                  subtitle: 'राष्ट्रभाषा • Hindi Translation',
                  isSelected: localeProvider.locale.languageCode == 'hi',
                ),
                const Divider(height: 1),
                _languageRadioTile(
                  context: context,
                  code: 'mr',
                  title: 'मराठी (Marathi)',
                  subtitle: 'महाराष्ट्र राज्य • Marathi Translation',
                  isSelected: localeProvider.locale.languageCode == 'mr',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Legal & Terms of Service
          Text(
            'LEGAL & COMMUNITY STANDARDS',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.mutedGrey,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.system_update_rounded, color: AppColors.primaryGreen),
              title: const Text(
                'Check for Updates (अ‍ॅप अपडेट तपासा)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'नवीन व्हर्जन व सुधारणा थेट 1-टॅपमध्ये अपडेट करा',
                style: TextStyle(fontSize: 12, color: AppColors.mutedGrey),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.mutedGrey),
              onTap: () {
                AppUpdateDialog.showIfAvailable(context, showToastIfUpToDate: true);
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.gavel_rounded, color: AppColors.deepGreen),
              title: Text(
                tr.get('terms_and_conditions'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'FSSAI food safety charter & privacy guidelines',
                style: TextStyle(fontSize: 12, color: AppColors.mutedGrey),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.mutedGrey),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const Dialog(
                    insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                    child: TermsAndConditionsModal(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // Sign Out Button
          FBButton(
            label: tr.signOut,
            variant: FBButtonVariant.danger,
            icon: Icons.logout,
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _languageRadioTile({
    required BuildContext context,
    required String code,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.mutedGrey.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          code.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.charcoal,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? AppColors.deepGreen : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: AppColors.mutedGrey),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 22)
          : const Icon(Icons.radio_button_unchecked, color: AppColors.mutedGrey, size: 20),
      onTap: () {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        localeProvider.setLanguageCode(code, userEmail: auth.user?.email);
      },
    );
  }

  static ImageProvider? _resolveAvatar(String? url) {
    return AvatarImageHelper.resolve(url);
  }
}
