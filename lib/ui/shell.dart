import 'package:flutter/material.dart';

import '../core/icons.dart';
import '../core/strings.dart';
import '../core/tokens.dart';
import 'guide_page.dart';
import 'records_page.dart';
import 'scan_page.dart';
import 'settings_page.dart';
import 'widgets/brand_mark.dart';

/// Three tabs — the three things a farmer comes here to do — plus the one
/// header that carries the app's standing claim.
///
/// Settings is not a tab. It is visited once or twice in the life of the
/// install, and a permanent slot in the bar cost every other tab a quarter of
/// its width. It sits behind the gear in the header, where people look for it.
///
/// The header no longer repeats the section name: each page prints its own
/// title directly beneath it, and saying it twice was noise.
///
/// The Scan tab is deliberately bare of chrome: a header above a viewfinder
/// costs the viewfinder its height, and aiming a camera is not a moment that
/// needs branding.
class AppShell extends StatefulWidget {
  final bool modelFailed;

  const AppShell({super.key, this.modelFailed = false});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final bool onCamera = _tab == 0;

    final List<Widget> pages = <Widget>[
      ScanPage(modelFailed: widget.modelFailed),
      RecordsPage(onScan: () => _go(0)),
      const GuidePage(),
    ];

    return Scaffold(
      backgroundColor: onCamera ? AppColor.cameraBody : AppColor.bg,
      body: Column(
        children: <Widget>[
          if (!onCamera) const _Header(),
          Expanded(child: IndexedStack(index: _tab, children: pages)),
        ],
      ),
      bottomNavigationBar: _NavBar(current: _tab, onTap: _go),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    return ColoredBox(
      color: AppColor.bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Insets.screen, 6, 6, 6),
          child: Row(
            children: <Widget>[
              const BrandMark(size: 34, radius: 10),
              const SizedBox(width: 10),
              Text(l.appName, style: AppFont.h3),
              const SizedBox(width: 10),
              const Flexible(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OnDeviceBadge(),
                ),
              ),
              IconButton(
                tooltip: l.openSettings,
                icon: const Icon(AppIcons.settings),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsPage(),
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

class _NavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _NavBar({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final L l = L.of(context);
    final List<_NavSpec> items = <_NavSpec>[
      _NavSpec(AppIcons.scan, AppIcons.scanActive, l.navScan),
      _NavSpec(AppIcons.records, AppIcons.recordsActive, l.navHistory),
      _NavSpec(AppIcons.guide, AppIcons.guideActive, l.navGuide),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: Insets.navBar,
          child: Row(
            children: List<Widget>.generate(items.length, (int i) {
              final bool on = i == current;
              final _NavSpec s = items[i];
              final Color ink = on ? AppColor.green900 : AppColor.ink3;
              return Expanded(
                child: Semantics(
                  selected: on,
                  button: true,
                  label: s.label,
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: on ? AppColor.mint : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(Insets.rFull),
                          ),
                          // Filled when selected, outline otherwise: the state
                          // is carried by shape as well as by colour, so it
                          // survives glare and colour blindness.
                          child: Icon(on ? s.active : s.idle,
                              size: 22, color: ink),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFont.labelSm.copyWith(
                            color: ink,
                            fontWeight:
                                on ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavSpec {
  final IconData idle;
  final IconData active;
  final String label;

  const _NavSpec(this.idle, this.active, this.label);
}
