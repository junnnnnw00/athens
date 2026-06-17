import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import 'profile_service.dart';
import '../../i18n.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _handle = TextEditingController();
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
  final _lastfmUsername = TextEditingController();
  bool _isPublic = false;
  bool _loaded = false;
  bool _saving = false;
  String? _error;
  String? _avatarUrl;
  bool _uploadingImage = false;

  @override
  void dispose() {
    _handle.dispose();
    _displayName.dispose();
    _bio.dispose();
    _lastfmUsername.dispose();
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    if (_loaded) return;
    _loaded = true;
    _handle.text = p.handle;
    _displayName.text = p.displayName ?? '';
    _bio.text = p.bio ?? '';
    _lastfmUsername.text = p.lastfmUsername ?? '';
    _isPublic = p.isPublic;
    _avatarUrl = p.avatarUrl;
  }

  Future<void> _pickAndUploadImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final chooseMsg = context.t('edit_choose_gallery', ref: ref);
    final deleteMsg = context.t('edit_delete_photo', ref: ref);
    final uploadSuccessMsg = context.t('edit_uploaded_toast', ref: ref);
    final uploadFailedPrefix = context.t('edit_upload_failed', ref: ref);
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(chooseMsg),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: Text(deleteMsg, style: const TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(context, 'delete'),
              ),
          ],
        ),
      ),
    );

    if (action == 'delete') {
      setState(() {
        _avatarUrl = null;
      });
      return;
    }

    if (action != 'pick') return;

    setState(() {
      _uploadingImage = true;
      _error = null;
    });

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (image == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      final service = ref.read(profileServiceProvider);
      final ext = image.name.split('.').lastOrNull ?? 'jpg';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final url = await service.uploadAvatar(image.path, fileName);

      setState(() {
        _avatarUrl = url;
        _uploadingImage = false;
      });
      messenger.showSnackBar(SnackBar(content: Text(uploadSuccessMsg)));
    } catch (e) {
      setState(() {
        _uploadingImage = false;
        _error = '$uploadFailedPrefix$e';
      });
    }
  }

  Future<void> _save() async {
    final lang = ref.read(localeProvider);
    final handleErr = ProfileService.validateHandle(_handle.text, lang);
    if (handleErr != null) {
      setState(() => _error = handleErr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    // Capture before the await so we never touch context/ref after pop/dispose.
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final service = ref.read(profileServiceProvider);
    final container = ProviderScope.containerOf(context);
    final savedMsg = context.t('edit_saved_toast', ref: ref);
    final handleTakenMsg = context.t('edit_handle_taken', ref: ref);
    final saveFailedPattern = context.t('edit_save_failed', ref: ref);
    try {
      await service.updateProfile(
        handle: _handle.text,
        displayName: _displayName.text,
        bio: _bio.text,
        avatarUrl: _avatarUrl,
        isPublic: _isPublic,
        lastfmUsername: _lastfmUsername.text,
      );
      container.invalidate(myProfileProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(savedMsg)),
      );
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/profile');
      }
    } on HandleTakenException {
      if (mounted) setState(() => _error = handleTakenMsg);
    } catch (e) {
      if (mounted) setState(() => _error = saveFailedPattern.replaceAll('{0}', '$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final async = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.t('edit_title', ref: ref))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.t('edit_load_failed', args: ['$e'], ref: ref))),
        data: (profile) {
          if (profile == null) {
            return Center(child: Text(context.t('edit_login_required', ref: ref)));
          }
          _hydrate(profile);
          return ListView(
            padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg,
                AppSpacing.xl, AppLayout.scrollBottomInset(context)),
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: p.surface2,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.line, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(48),
                                  child: Image.network(
                                    _avatarUrl!,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        color: p.muted,
                                        size: 40),
                                  ),
                                )
                              : Icon(Icons.person_rounded,
                                  color: p.muted, size: 40),
                        ),
                        if (_uploadingImage)
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton.icon(
                      onPressed: _uploadingImage ? null : _pickAndUploadImage,
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: Text(context.t('edit_change_photo', ref: ref)),
                      style: TextButton.styleFrom(
                        foregroundColor: p.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label(context.t('edit_handle_label', ref: ref)),
              TextField(
                controller: _handle,
                decoration: InputDecoration(
                  prefixText: '@',
                  hintText: 'lowercase_handle',
                  helperText: context.t('edit_public_url_hint', ref: ref),
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label(context.t('edit_display_name', ref: ref)),
              TextField(
                controller: _displayName,
                decoration: InputDecoration(hintText: context.t('edit_display_name_hint', ref: ref)),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label(context.t('edit_bio', ref: ref)),
              TextField(
                controller: _bio,
                maxLines: 3,
                maxLength: 160,
                decoration: InputDecoration(hintText: context.t('edit_bio_hint', ref: ref)),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label(context.t('edit_lastfm_label', ref: ref)),
              TextField(
                controller: _lastfmUsername,
                decoration: InputDecoration(
                  hintText: context.t('edit_lastfm_hint', ref: ref),
                  helperText: context.t('edit_lastfm_helper', ref: ref),
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: p.line),
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: SwitchListTile(
                  value: _isPublic,
                  activeThumbColor: p.accent,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg),
                  title: Text(context.t('edit_public_profile_title', ref: ref)),
                  subtitle: Text(
                    _isPublic
                        ? context.t('edit_public_desc_on', ref: ref)
                        : context.t('edit_public_desc_off', ref: ref),
                    style: TextStyle(color: p.muted, fontSize: 12.5),
                  ),
                  onChanged: (v) => setState(() => _isPublic = v),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(context.t('lib_save', ref: ref)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
