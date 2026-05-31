import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/update_service.dart';

/// A dismissible banner shown at the top of the home screen when a new
/// APK version is available on GitHub Releases.
class UpdateBanner extends StatefulWidget {
  const UpdateBanner({super.key});

  @override
  State<UpdateBanner> createState() => _UpdateBannerState();
}

class _UpdateBannerState extends State<UpdateBanner>
    with SingleTickerProviderStateMixin {
  UpdateInfo? _info;
  bool _dismissed = false;
  bool _updating = false;
  late final AnimationController _anim;
  late final Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeSlide = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _check();
  }

  Future<void> _check() async {
    final info = await UpdateService.checkForUpdate();
    if (info != null && mounted) {
      setState(() => _info = info);
      _anim.forward();
    }
  }

  Future<void> _download() async {
    if (_info == null) return;

    if (!kIsWeb && Platform.isMacOS) {
      setState(() => _updating = true);
      try {
        final downloadUrl = _info!.downloadUrl;

        // 1. Get temporary directory
        final tempDir = await getTemporaryDirectory();
        await tempDir.create(recursive: true);
        final zipPath = '${tempDir.path}/athens-update.zip';

        // 2. Download the zip
        final response = await http.get(Uri.parse(downloadUrl));
        if (response.statusCode != 200) {
          throw Exception('Failed to download update: ${response.statusCode}');
        }
        await File(zipPath).writeAsBytes(response.bodyBytes);

        // 3. Unzip the file
        final extractedDir = '${tempDir.path}/extracted';
        final extDirObj = Directory(extractedDir);
        if (await extDirObj.exists()) {
          await extDirObj.delete(recursive: true);
        }
        await extDirObj.create(recursive: true);

        final unzipResult = await Process.run('unzip', ['-o', zipPath, '-d', extractedDir]);
        if (unzipResult.exitCode != 0) {
          throw Exception('Unzip failed: ${unzipResult.stderr}');
        }

        // Find Athens.app in the extracted folder
        final newAppPath = '$extractedDir/Athens.app';
        if (!await Directory(newAppPath).exists()) {
          throw Exception('Could not find Athens.app in the update package.');
        }

        // 4. Swap apps and restart
        final currentAppPath = Directory(Platform.resolvedExecutable).parent.parent.parent.path;
        final oldAppPath = '$currentAppPath.old';

        final script = '''
        mv "$currentAppPath" "$oldAppPath"
        mv "$newAppPath" "$currentAppPath"
        xattr -cr "$currentAppPath"
        open -n "$currentAppPath"
        sleep 2
        rm -rf "$oldAppPath"
        ''';

        await Process.start('bash', ['-c', script]);
        exit(0);
      } catch (e) {
        if (mounted) {
          setState(() => _updating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('업데이트 설치 실패: $e')),
          );
        }
      }
      return;
    }

    final uri = Uri.parse(_info!.downloadUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _dismiss() {
    _anim.reverse().then((_) {
      if (mounted) setState(() => _dismissed = true);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || _info == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return FadeTransition(
      opacity: _fadeSlide,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -1),
          end: Offset.zero,
        ).animate(_fadeSlide),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                cs.primaryContainer,
                cs.secondaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.system_update_alt_rounded,
                  color: cs.onPrimaryContainer, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '새 버전 ${_info!.latestVersion} 출시!',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: cs.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _updating ? '업데이트 설치 중...' : '현재 ${_info!.currentVersion} → 업데이트 다운로드',
                      style: TextStyle(
                        color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _updating
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimaryContainer,
                      ),
                    )
                  : FilledButton(
                      onPressed: _download,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('업데이트'),
                    ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: _dismiss,
                icon: Icon(Icons.close_rounded,
                    size: 18, color: cs.onPrimaryContainer),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
