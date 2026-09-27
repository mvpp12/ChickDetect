import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import '../data/conditions.dart';
import '../data/scan_record.dart';
import '../data/scan_store.dart';
import '../ml/classifier.dart';
import '../ml/decision.dart';
import '../ml/image_check.dart';
import 'detail_page.dart';
import 'guide_intro_page.dart';
import 'widgets/common.dart';
import 'widgets/labels_form.dart';
import 'widgets/report.dart';

/// Where the farmer is in the capture flow.
enum _Stage { aiming, confirming, working }

/// The camera.
///
/// Three controls in the thumb's reach — gallery, shutter, light — and one
/// help button up top. Nothing that looks like a control is a label: the old
/// "70% FRAME" chip looked tappable and did nothing.
///
/// This screen carries no advice. The capture rules are taught in the guide
/// and kept in the Guide tab; three cards of reminders under a viewfinder is
/// how the previous version ended up with a camera occupying half the screen.
class ScanPage extends StatefulWidget {
  final bool modelFailed;

  const ScanPage({super.key, required this.modelFailed});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  CameraController? _camera;
  final ImagePicker _picker = ImagePicker();

  bool _cameraReady = false;
  bool _cameraFailed = false;
  bool _flashOn = false;
  _Stage _stage = _Stage.aiming;
  File? _shot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The browser preview cannot scan, so it does not ask for the camera.
    if (!(kIsWeb && widget.modelFailed)) _openCamera();
  }

  /// Android reclaims the camera when the app goes to the background. Without
  /// this the preview comes back black and the shutter silently fails — the
  /// single most common "it broke on my phone" report for a Flutter camera.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? c = _camera;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      c.dispose();
      _camera = null;
      if (mounted) setState(() => _cameraReady = false);
    } else if (state == AppLifecycleState.resumed) {
      _openCamera();
    }
  }

  Future<void> _openCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraFailed = true;
            _cameraReady = false;
          });
        }
        return;
      }
      final CameraController c = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _camera = c;
        _cameraReady = true;
        _cameraFailed = false;
        _flashOn = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraFailed = true;
          _cameraReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    final CameraController? c = _camera;
    if (c == null || !c.value.isInitialized) return;
    try {
      final bool next = !_flashOn;
      await c.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (_) {
      // Some devices have no torch. Leaving the chip as it was is the honest
      // response; a snackbar here would fire every time someone taps it.
    }
  }

  Future<void> _capture() async {
    final CameraController? c = _camera;
    if (c == null || !_cameraReady || _stage != _Stage.aiming) return;
    try {
      final XFile file = await c.takePicture();
      if (!mounted) return;
      setState(() {
        _shot = File(file.path);
        _stage = _Stage.confirming;
      });
    } catch (_) {
      if (mounted) showToast(context, L.of(context).captureFailed);
    }
  }

  Future<void> _fromGallery() async {
    if (_stage != _Stage.aiming) return;
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;
      setState(() {
        _shot = File(file.path);
        _stage = _Stage.confirming;
      });
    } catch (_) {
      if (mounted) showToast(context, L.of(context).captureFailed);
    }
  }

  void _retake() => setState(() {
    _shot = null;
    _stage = _Stage.aiming;
  });

  Future<void> _analyse() async {
    final File? shot = _shot;
    if (shot == null) return;
    final L l = L.of(context);

    // Read before the first await, so no context is used across the gap.
    final Classifier classifier = context.read<Classifier>();
    setState(() => _stage = _Stage.working);

    try {
      final Uint8List bytes = await shot.readAsBytes();

      // The photo is checked before the model ever runs. See PhotoChecker for
      // why that matters more here than in most apps.
      final PhotoQuality? quality = PhotoChecker.inspectBytes(bytes);

      Prediction? prediction;
      if (quality != null && quality.usable) {
        if (classifier.isReady) {
          prediction = classifier.run(bytes);
        }
      }

      final Verdict verdict = Decision.evaluate(
        quality: quality,
        prediction: prediction,
      );

      if (!mounted) return;
      await _showResult(verdict, shot.path);
    } catch (_) {
      if (!mounted) return;
      showToast(context, l.analysisFailed);
      setState(() => _stage = _Stage.confirming);
    }
  }

  Future<void> _showResult(Verdict verdict, String imagePath) async {
    if (verdict.kind == VerdictKind.photoRejected) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext ctx) =>
            _RejectedSheet(fault: verdict.quality!.fault!),
      );
      if (mounted) _retake();
      return;
    }

    final ScanStore store = context.read<ScanStore>();
    final ScanRecord record = ScanRecord.fromVerdict(
      verdict: verdict,
      imagePath: imagePath,
      coop: '',
      note: '',
    );
    // Saved before the sheet opens, not from a button inside it: dismissing a
    // sheet with a stray tap used to throw the scan away.
    await store.add(record);

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => _ResultSheet(
        record: record,
        verdict: verdict,
        onScanAgain: () => Navigator.of(ctx).pop(),
        onOpenFull: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailPage(recordId: record.id),
            ),
          );
        },
      ),
    );
    if (mounted) _retake();
  }

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);

    return ColoredBox(
      color: AppColor.cameraBody,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  _preview(l),
                  if (_stage != _Stage.working) const _Reticle(),
                  if (_stage == _Stage.working) _Working(l: l),
                  if (_stage == _Stage.aiming)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _RoundButton(
                              icon: AppIcons.help,
                              tooltip: l.howToScan,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const GuideIntroPage(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_stage != _Stage.working)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _Hint(
                        text: _stage == _Stage.aiming
                            ? l.aimHere
                            : l.checkPhoto,
                      ),
                    ),
                ],
              ),
            ),
            _Dock(
              stage: _stage,
              canShoot: _cameraReady && !widget.modelFailed,
              flashOn: _flashOn,
              onFlash: _cameraReady ? _toggleFlash : null,
              onShoot: _capture,
              // Without a model a picked photo can only produce a bogus
              // "no answer" record, so the gallery is off along with the
              // shutter.
              onGallery: widget.modelFailed ? null : _fromGallery,
              onRetake: _retake,
              onUse: _analyse,
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(L l) {
    final File? shot = _shot;
    if (shot != null) {
      return Image.file(shot, fit: BoxFit.cover);
    }
    if (widget.modelFailed) {
      return _Blocked(
        icon: kIsWeb ? AppIcons.onDevice : AppIcons.model,
        // In the browser preview the AI is never there, so say where scanning
        // does work instead of reporting a failure.
        title: kIsWeb ? l.phoneOnly : l.modelUnavailable,
        action: null,
        actionLabel: null,
      );
    }
    if (_cameraFailed) {
      return _Blocked(
        icon: AppIcons.cameraOff,
        title: l.cameraUnavailable,
        action: _openCamera,
        actionLabel: l.tryAgain,
      );
    }
    final CameraController? c = _camera;
    if (c != null && _cameraReady) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: c.value.previewSize?.height ?? 1080,
          height: c.value.previewSize?.width ?? 1920,
          child: CameraPreview(c),
        ),
      );
    }
    return const ColoredBox(
      color: AppColor.cameraBody,
      child: Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColor.mint),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Camera furniture
// ─────────────────────────────────────────────────────────────────────────

/// The framing guide: a clear square with mint corners.
///
/// Mint rather than white because white blows out against pale litter under
/// flash, which is exactly when the guide is needed most.
class _Reticle extends StatelessWidget {
  const _Reticle();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints c) {
      final double side = c.maxWidth * 0.72;
      return Center(
        child: SizedBox(
          width: side,
          height: side,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Insets.rLg),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(color: Color(0x5C000000), spreadRadius: 2000),
                    ],
                  ),
                ),
              ),
              for (final Alignment a in <Alignment>[
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight,
              ])
                Align(alignment: a, child: _Corner(align: a)),
            ],
          ),
        ),
      );
    },
  );
}

class _Corner extends StatelessWidget {
  final Alignment align;

  const _Corner({required this.align});

  @override
  Widget build(BuildContext context) {
    const BorderSide side = BorderSide(color: AppColor.mint, width: 3);
    final bool top = align.y < 0;
    final bool left = align.x < 0;
    // A non-uniform Border cannot carry a borderRadius — Flutter asserts on
    // that pairing — so these are plain right-angle corners.
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint({required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: AppColor.green900.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(Insets.rFull),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppFont.labelSm.copyWith(color: Colors.white),
      ),
    ),
  );
}

class _Working extends StatelessWidget {
  final L l;

  const _Working({required this.l});

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColor.cameraBody.withValues(alpha: 0.72),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColor.mint),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.analysing,
            style: AppFont.label.copyWith(color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

class _Blocked extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? action;
  final String? actionLabel;

  const _Blocked({
    required this.icon,
    required this.title,
    required this.action,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColor.cameraBody,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(Insets.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: AppColor.mintLine),
            const SizedBox(height: Insets.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFont.h3.copyWith(color: Colors.white),
            ),
            if (action != null && actionLabel != null) ...<Widget>[
              const SizedBox(height: Insets.lg),
              OutlinedButton(
                onPressed: action,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColor.green900,
                  backgroundColor: AppColor.mint,
                  side: BorderSide.none,
                  minimumSize: const Size(190, Insets.tap),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Dock extends StatelessWidget {
  final _Stage stage;
  final bool canShoot;
  final bool flashOn;
  final VoidCallback? onFlash;
  final VoidCallback onShoot;
  final VoidCallback? onGallery;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  const _Dock({
    required this.stage,
    required this.canShoot,
    required this.flashOn,
    required this.onFlash,
    required this.onShoot,
    required this.onGallery,
    required this.onRetake,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);

    if (stage == _Stage.confirming) {
      return Container(
        color: AppColor.cameraBody,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(AppIcons.retake,
                    size: 18),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0x4DFFFFFF)),
                ),
                label: Text(l.retake),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.mint,
                  foregroundColor: AppColor.green900,
                ),
                onPressed: onUse,
                icon: const Icon(AppIcons.check, size: 18),
                label: Text(l.usePhoto),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColor.cameraBody,
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _RoundButton(
            icon: AppIcons.gallery,
            tooltip: l.gallery,
            onTap: stage == _Stage.aiming ? onGallery : null,
          ),
          _Shutter(enabled: canShoot && stage == _Stage.aiming, onTap: onShoot),
          // A torch toggle, stated as what tapping it will do. The old chip
          // said "FLASH: AUTO" even after it had been switched off.
          _RoundButton(
            icon: flashOn ? AppIcons.flashOn : AppIcons.flashOff,
            tooltip: flashOn ? l.lightOn : l.lightOff,
            active: flashOn,
            onTap: stage == _Stage.aiming ? onFlash : null,
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool active;

  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        toggled: active ? true : null,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: active ? AppColor.mint : const Color(0x33FFFFFF),
          shape: const CircleBorder(
            side: BorderSide(color: Color(0x33FFFFFF)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                icon,
                size: 24,
                color: active
                    ? AppColor.green900
                    : enabled
                    ? Colors.white
                    : Colors.white38,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A shutter that looks like a shutter: a white ring around a solid disc,
/// which every camera app has taught people to press. The disc shrinks a
/// little under the finger, so the press is felt as well as heard.
class _Shutter extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _Shutter({required this.enabled, required this.onTap});

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool on = widget.enabled;
    return Semantics(
      button: true,
      enabled: on,
      label: L.of(context).takePhoto,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _set(true),
        onTapCancel: () => _set(false),
        onTapUp: (_) => _set(false),
        onTap: on ? widget.onTap : null,
        child: Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: on ? Colors.white : Colors.white38,
              width: 4,
            ),
          ),
          child: AnimatedScale(
            scale: _down ? 0.86 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? AppColor.mint : const Color(0x33FFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sheets
// ─────────────────────────────────────────────────────────────────────────

/// Shown when the photo never reached the model.
class _RejectedSheet extends StatelessWidget {
  final PhotoFault fault;

  const _RejectedSheet({required this.fault});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final (String title, String fix, IconData icon) = switch (fault) {
      PhotoFault.blurred => (l.qualityBlur, l.qualityBlurFix, AppIcons.blurred),
      PhotoFault.tooDark => (l.qualityDark, l.qualityDarkFix, AppIcons.tooDark),
      PhotoFault.tooBright =>
        (l.qualityBright, l.qualityBrightFix, AppIcons.tooBright),
      PhotoFault.flat => (l.qualityFlat, l.qualityFlatFix, AppIcons.noSubject),
    };

    return SheetFrame(
      children: <Widget>[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Insets.card + 2),
          decoration: BoxDecoration(
            color: AppColor.cautionSoft,
            borderRadius: BorderRadius.circular(Insets.rXl),
            border: Border.all(color: AppColor.caution.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(AppIcons.rejected,
                      color: AppColor.caution, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.photoRejected,
                      style: AppFont.h2.copyWith(color: AppColor.caution),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(l.photoRejectedWhy, style: AppFont.bodySm),
            ],
          ),
        ),
        const SizedBox(height: Insets.md),
        AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColor.cautionSoft,
                  borderRadius: BorderRadius.circular(Insets.rSm),
                ),
                child: Icon(icon, size: 21, color: AppColor.caution),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: AppFont.h3),
                    const SizedBox(height: 6),
                    Text(
                      fix,
                      style: AppFont.body.copyWith(color: AppColor.ink2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Insets.lg),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(AppIcons.scan, size: 20),
          label: Text(l.retake),
        ),
      ],
    );
  }
}

/// Shown after a reading. Brief by design: the verdict, the first things to
/// do, a place to say which coop it was, and the way to the full report.
class _ResultSheet extends StatelessWidget {
  final ScanRecord record;
  final Verdict verdict;
  final VoidCallback onOpenFull;
  final VoidCallback onScanAgain;

  const _ResultSheet({
    required this.record,
    required this.verdict,
    required this.onOpenFull,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final Condition condition = conditionFor(record.conditionKey);

    return SheetFrame(
      children: <Widget>[
        Text(
          l.scanResult,
          style: AppFont.micro.copyWith(color: AppColor.ink3),
        ),
        const SizedBox(height: 10),
        ConditionReport(
          condition: condition,
          depth: ReportDepth.brief,
          confidence: verdict.confidence,
          rawLabel: verdict.prediction?.label,
          heldBack: verdict.reasons,
        ),
        const SizedBox(height: Insets.section),
        Text(l.nameThisScan, style: AppFont.h3),
        const SizedBox(height: 12),
        ScanLabelsForm(record: record),
        const SizedBox(height: Insets.lg),
        ElevatedButton.icon(
          onPressed: onOpenFull,
          icon: const Icon(AppIcons.fullReport, size: 20),
          label: Text(l.viewFullReport),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onScanAgain,
          icon: const Icon(AppIcons.scan, size: 20),
          label: Text(l.scanAgain),
        ),
      ],
    );
  }
}
