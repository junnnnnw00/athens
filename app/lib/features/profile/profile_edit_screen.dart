import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/tokens.dart';
import '../../theme/app_theme.dart';
import 'profile_service.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _handle = TextEditingController();
  final _displayName = TextEditingController();
  final _bio = TextEditingController();
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
    super.dispose();
  }

  void _hydrate(UserProfile p) {
    if (_loaded) return;
    _loaded = true;
    _handle.text = p.handle;
    _displayName.text = p.displayName ?? '';
    _bio.text = p.bio ?? '';
    _isPublic = p.isPublic;
    _avatarUrl = p.avatarUrl;
  }

  Future<void> _pickAndUploadImage() async {
    final messenger = ScaffoldMessenger.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(context, 'pick'),
            ),
            if (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('사진 삭제', style: TextStyle(color: Colors.red)),
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
      messenger.showSnackBar(const SnackBar(content: Text('프로필 사진 업로드됨')));
    } catch (e) {
      setState(() {
        _uploadingImage = false;
        _error = '이미지 업로드 실패: $e';
      });
    }
  }

  Future<void> _save() async {
    final handleErr = ProfileService.validateHandle(_handle.text);
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
    try {
      await service.updateProfile(
        handle: _handle.text,
        displayName: _displayName.text,
        bio: _bio.text,
        avatarUrl: _avatarUrl,
        isPublic: _isPublic,
      );
      container.invalidate(myProfileProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('프로필 저장됨')),
      );
      router.go('/profile');
    } on HandleTakenException {
      if (mounted) setState(() => _error = '이미 사용 중인 핸들이에요');
    } catch (e) {
      if (mounted) setState(() => _error = '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final async = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 편집')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('불러오기 실패: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('로그인이 필요해요.'));
          }
          _hydrate(profile);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 110),
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
                      label: const Text('프로필 사진 변경'),
                      style: TextButton.styleFrom(
                        foregroundColor: p.accentText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label('핸들'),
              TextField(
                controller: _handle,
                decoration: InputDecoration(
                  prefixText: '@',
                  hintText: 'lowercase_handle',
                  helperText: '공개 프로필 주소: /u/<핸들>',
                ),
                autocorrect: false,
                enableSuggestions: false,
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label('표시 이름'),
              TextField(
                controller: _displayName,
                decoration: const InputDecoration(hintText: '예: 준우'),
              ),
              const SizedBox(height: AppSpacing.lg),
              _Label('소개'),
              TextField(
                controller: _bio,
                maxLines: 3,
                maxLength: 160,
                decoration: const InputDecoration(hintText: '한 줄 소개'),
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
                  title: const Text('공개 프로필'),
                  subtitle: Text(
                    _isPublic
                        ? '누구나 웹에서 내 순위를 볼 수 있어요'
                        : '나만 볼 수 있어요',
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
                      : const Text('저장'),
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
