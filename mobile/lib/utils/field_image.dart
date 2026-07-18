import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/field.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';

const _maxCachedFieldImages = 32;
final _fieldImageCache = <int, ImageProvider>{};

ImageProvider? fieldImageProvider(Field field) {
  if (field.image == null || !field.image!.startsWith('data:')) return null;

  final cached = _fieldImageCache[field.id];
  if (cached != null) return cached;

  try {
    final bytes = base64Decode(field.image!.split(',').last);
    final image = ResizeImage.resizeIfNeeded(1280, null, MemoryImage(bytes));
    _fieldImageCache[field.id] = image;
    while (_fieldImageCache.length > _maxCachedFieldImages) {
      _fieldImageCache.remove(_fieldImageCache.keys.first);
    }
    return image;
  } catch (_) {
    return null;
  }
}

Widget fieldHeroImage(BuildContext context, Field field, {double height = 220}) {
  final c = context.colors;
  final gradient = DesignTokens.gradientFor(field.id);
  final provider = fieldImageProvider(field);
  return SizedBox(
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        if (provider != null)
          Image(image: provider, fit: BoxFit.cover, gaplessPlayback: true)
        else
          DecoratedBox(
            decoration: BoxDecoration(gradient: gradient),
            child: Center(child: Icon(Icons.stadium_rounded, size: 80, color: c.onInverse.withValues(alpha: 0.85))),
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.scrimLight, Colors.transparent, c.surface],
            ),
          ),
        ),
      ],
    ),
  );
}
