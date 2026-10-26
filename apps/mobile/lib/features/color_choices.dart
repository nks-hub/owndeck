import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';

enum DeckPaletteColor { teal, blue, green, purple, orange, red, pink, gray }

const deckPalette = <DeckPaletteColor, String>{
  DeckPaletteColor.teal: '008080',
  DeckPaletteColor.blue: '2563eb',
  DeckPaletteColor.green: '15803d',
  DeckPaletteColor.purple: '7c3aed',
  DeckPaletteColor.orange: 'c2410c',
  DeckPaletteColor.red: 'dc2626',
  DeckPaletteColor.pink: 'be185d',
  DeckPaletteColor.gray: '64748b',
};

String _paletteName(DeckPaletteColor color, AppLocalizations text) =>
    switch (color) {
      DeckPaletteColor.teal => text.colorTeal,
      DeckPaletteColor.blue => text.colorBlue,
      DeckPaletteColor.green => text.colorGreen,
      DeckPaletteColor.purple => text.colorPurple,
      DeckPaletteColor.orange => text.colorOrange,
      DeckPaletteColor.red => text.colorRed,
      DeckPaletteColor.pink => text.colorPink,
      DeckPaletteColor.gray => text.colorGray,
    };

final _hexPattern = RegExp(r'^[0-9a-f]{6}$');

/// Strips an optional leading `#` and lowercases a stored color value.
String normalizeColorHex(Object? value) =>
    (value?.toString() ?? '').replaceFirst('#', '').toLowerCase();

/// Parses a 6-digit hex color, or returns null when [hex] is not valid.
Color? colorFromHex(String hex) {
  final normalized = normalizeColorHex(hex);
  if (!_hexPattern.hasMatch(normalized)) return null;
  return Color(0xff000000 | int.parse(normalized, radix: 16));
}

String colorToHex(Color color) =>
    (color.toARGB32() & 0xffffff).toRadixString(16).padLeft(6, '0');

/// WCAG contrast ratio between two colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Black or white, whichever is more readable on [background].
Color readableForeground(Color background) =>
    contrastRatio(background, Colors.white) >=
        contrastRatio(background, Colors.black)
    ? Colors.white
    : Colors.black;

/// Human description of a color, such as "dark blue", never a hex code.
String describeColor(Color color, AppLocalizations text) {
  final hsl = HSLColor.fromColor(color);
  final lightness = hsl.lightness;
  if (lightness < 0.1) return text.colorBlack.toLowerCase();
  if (lightness > 0.93) return text.colorWhite.toLowerCase();
  final hue = hsl.hue;
  final name =
      (hsl.saturation < 0.1
              ? text.colorGray
              : hue < 15 || hue >= 345
              ? text.colorRed
              : hue < 45
              ? text.colorOrange
              : hue < 70
              ? text.colorYellow
              : hue < 165
              ? text.colorGreen
              : hue < 200
              ? text.colorTeal
              : hue < 255
              ? text.colorBlue
              : hue < 290
              ? text.colorPurple
              : text.colorPink)
          .toLowerCase();
  if (lightness < 0.35) return text.colorDark(name);
  if (lightness > 0.7) return text.colorLight(name);
  return name;
}

String colorName(Object? value, AppLocalizations text) {
  if (value == null || value == '') return text.colorDefault;
  final normalized = normalizeColorHex(value);
  for (final entry in deckPalette.entries) {
    if (entry.value == normalized) return _paletteName(entry.key, text);
  }
  final color = colorFromHex(normalized);
  return color == null
      ? text.colorCustom
      : text.colorCustomNamed(describeColor(color, text));
}

/// Opens the custom color picker and returns the chosen 6-digit hex.
Future<String?> showColorPicker(BuildContext context, {String? initial}) =>
    showDialog<String>(
      context: context,
      builder: (_) => ColorPickerDialog(initial: initial),
    );

/// Round preset swatches as quick picks, a rainbow swatch that opens the custom
/// picker, and a caption naming the current choice.
class ColorChoices extends StatelessWidget {
  const ColorChoices({
    super.key,
    required this.value,
    required this.onChanged,
    this.allowNone = true,
  });
  final String? value;
  final ValueChanged<String?>? onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final normalized = normalizeColorHex(value);
    final isPreset = deckPalette.values.contains(normalized);
    final isCustom = normalized.isNotEmpty && !isPreset;
    final customColor = isCustom ? colorFromHex(normalized) : null;

    Future<void> pickCustom() async {
      final picked = await showColorPicker(
        context,
        initial: isCustom ? normalized : null,
      );
      if (picked != null) onChanged!(picked);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (allowNone)
              _Swatch(
                name: text.colorDefault,
                selected: normalized.isEmpty,
                onTap: onChanged == null ? null : () => onChanged!(null),
                child: Icon(
                  Icons.format_color_reset,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final entry in deckPalette.entries)
              _Swatch(
                name: _paletteName(entry.key, text),
                color: colorFromHex(entry.value),
                selected: normalized == entry.value,
                onTap: onChanged == null ? null : () => onChanged!(entry.value),
              ),
            if (customColor != null)
              _Swatch(
                name: text.colorCustomNamed(describeColor(customColor, text)),
                color: customColor,
                selected: true,
                onTap: onChanged == null ? null : pickCustom,
              ),
            _Swatch(
              name: text.colorPickCustom,
              rainbow: true,
              selected: false,
              onTap: onChanged == null ? null : pickCustom,
              child: const Icon(Icons.add, size: 20, color: Colors.white),
            ),
          ],
        ),
        if (normalized.isNotEmpty || allowNone)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2),
            child: ExcludeSemantics(
              child: Text(
                colorName(normalized, text),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.selected,
    required this.onTap,
    this.color,
    this.rainbow = false,
    this.child,
  });
  final String name;
  final bool selected;
  final VoidCallback? onTap;
  final Color? color;
  final bool rainbow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = color;
    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: Tooltip(
        message: name,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox.square(
            dimension: 48,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill ?? scheme.surfaceContainerHigh,
                  gradient: rainbow
                      ? const SweepGradient(
                          colors: [
                            Color(0xffe53935),
                            Color(0xfffdd835),
                            Color(0xff43a047),
                            Color(0xff1e88e5),
                            Color(0xff8e24aa),
                            Color(0xffe53935),
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: selected ? scheme.onSurface : scheme.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: selected && fill != null
                    ? Icon(
                        Icons.check,
                        size: 20,
                        color: readableForeground(fill),
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialog with hue, saturation and lightness sliders, step buttons, a live
/// preview with text contrast, and an optional exact hex field.
class ColorPickerDialog extends StatefulWidget {
  const ColorPickerDialog({super.key, this.initial});
  final String? initial;

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  late HSLColor _hsl;
  // Set while the color is untouched or typed exactly, so it round-trips
  // without HSL rounding.
  String? _exact;
  final _hexController = TextEditingController();
  bool _hexInvalid = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initial == null ? null : colorFromHex(widget.initial!);
    _hsl = HSLColor.fromColor(start ?? const Color(0xff2563eb));
    _exact = start == null ? '2563eb' : normalizeColorHex(widget.initial);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _setHsl(HSLColor value) => setState(() {
    _hsl = value;
    _exact = null;
    _hexInvalid = false;
  });

  void _typeHex(String value) {
    final color = colorFromHex(value);
    setState(() {
      _hexInvalid = value.isNotEmpty && color == null;
      if (color != null) {
        _hsl = HSLColor.fromColor(color);
        _exact = value.toLowerCase();
      }
    });
  }

  Color get _color => _exact == null ? _hsl.toColor() : colorFromHex(_exact!)!;

  Widget _slider({
    required String name,
    required double value,
    required double max,
    required double step,
    required String Function(double) format,
    required List<Color> gradient,
    required ValueChanged<double> onChanged,
  }) {
    final text = AppLocalizations.of(context)!;
    void nudge(double delta) => onChanged((value + delta).clamp(0, max));
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Text('$name: ${format(value)}')),
          Row(
            children: [
              IconButton(
                tooltip: text.colorDecrease(name),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.remove),
                onPressed: value <= 0 ? null : () => nudge(-step),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(colors: gradient),
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Theme.of(context).colorScheme.onSurface,
                      ),
                      child: MergeSemantics(
                        child: Semantics(
                          label: name,
                          child: Slider(
                            value: value.clamp(0, max),
                            max: max,
                            divisions: max.round(),
                            semanticFormatterCallback: format,
                            onChanged: onChanged,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: text.colorIncrease(name),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(Icons.add),
                onPressed: value >= max ? null : () => nudge(step),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context)!;
    final color = _color;
    final foreground = readableForeground(color);
    final ratio = contrastRatio(color, foreground).toStringAsFixed(1);
    final localizedRatio = Localizations.localeOf(context).languageCode == 'cs'
        ? ratio.replaceFirst('.', ',')
        : ratio;
    final hue = _hsl.hue;
    final sat = _hsl.saturation;
    final light = _hsl.lightness;
    HSLColor at(double h, double s, double l) => HSLColor.fromAHSL(1, h, s, l);
    return AlertDialog(
      scrollable: true,
      title: Text(text.colorCustom),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text.colorPickerHint),
          const SizedBox(height: 12),
          Semantics(
            container: true,
            liveRegion: true,
            label: text.colorCustomNamed(describeColor(color, text)),
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minHeight: 72),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  text.colorSample,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: foreground),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(text.colorContrast(localizedRatio)),
          _slider(
            name: text.colorHue,
            value: hue,
            max: 360,
            step: 5,
            format: (v) => '${v.round()}°',
            gradient: [
              for (var h = 0; h <= 360; h += 60)
                at(h.toDouble(), sat, light).toColor(),
            ],
            onChanged: (v) => _setHsl(_hsl.withHue(v)),
          ),
          _slider(
            name: text.colorSaturation,
            value: sat * 100,
            max: 100,
            step: 5,
            format: (v) => '${v.round()} %',
            gradient: [
              at(hue, 0, light).toColor(),
              at(hue, 1, light).toColor(),
            ],
            onChanged: (v) => _setHsl(_hsl.withSaturation(v / 100)),
          ),
          _slider(
            name: text.colorLightness,
            value: light * 100,
            max: 100,
            step: 5,
            format: (v) => '${v.round()} %',
            gradient: [Colors.black, at(hue, sat, 0.5).toColor(), Colors.white],
            onChanged: (v) => _setHsl(_hsl.withLightness(v / 100)),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(text.colorHexToggle),
            children: [
              TextField(
                controller: _hexController,
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: text.colorHexLabel,
                  errorText: _hexInvalid ? text.colorHexInvalid : null,
                ),
                onChanged: _typeHex,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.cancel),
        ),
        FilledButton(
          onPressed: _hexInvalid
              ? null
              : () => Navigator.pop(context, _exact ?? colorToHex(color)),
          child: Text(text.colorApply),
        ),
      ],
    );
  }
}
