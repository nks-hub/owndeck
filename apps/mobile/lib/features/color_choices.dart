import 'package:flutter/material.dart';

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

String colorName(Object? value, AppLocalizations text) {
  if (value == null || value == '') return text.colorDefault;
  final normalized = value.toString().replaceFirst('#', '').toLowerCase();
  for (final entry in deckPalette.entries) {
    if (entry.value == normalized) return _paletteName(entry.key, text);
  }
  return text.colorCustom;
}

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
    final normalized = value?.replaceFirst('#', '').toLowerCase();
    Widget choice(String? hex, String name) {
      final selected = hex == null
          ? normalized == null || normalized.isEmpty
          : normalized == hex;
      final rgb = hex == null ? null : int.tryParse(hex, radix: 16);
      return ChoiceChip(
        selected: selected,
        label: Text(name),
        avatar: rgb == null
            ? const Icon(Icons.format_color_reset, size: 20)
            : Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xff000000 | rgb),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
        onSelected: onChanged == null ? null : (_) => onChanged!(hex),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        if (allowNone) choice(null, text.colorDefault),
        if (normalized != null &&
            normalized.isNotEmpty &&
            !deckPalette.values.contains(normalized))
          choice(normalized, text.colorCustom),
        for (final entry in deckPalette.entries)
          choice(entry.value, _paletteName(entry.key, text)),
      ],
    );
  }
}
