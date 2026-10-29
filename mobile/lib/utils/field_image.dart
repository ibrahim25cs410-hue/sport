import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/field.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';

const _maxCachedFieldImages = 32;
final _fieldImageCache = <(int, int, int), ImageProvider>{};

ImageProvider? fieldImageProvider(Field field, {int cacheWidth = 1280}) {
  if (field.image == null || !field.image!.startsWith('data:')) return null;

  final key = (field.id, field.image.hashCode, cacheWidth);
  final cached = _fieldImageCache[key];
  if (cached != null) return cached;

  try {
    final bytes = base64Decode(field.image!.split(',').last);
    final image = ResizeImage.resizeIfNeeded(
      cacheWidth,
      null,
      MemoryImage(bytes),
    );
    _fieldImageCache[key] = image;
    while (_fieldImageCache.length > _maxCachedFieldImages) {
      _fieldImageCache.remove(_fieldImageCache.keys.first);
    }
    return image;
  } catch (_) {
    return null;
  }
}

Widget fieldHeroImage(
  BuildContext context,
  Field field, {
  double height = 220,
}) {
  final c = context.colors;
  final gradient = DesignTokens.gradientFor(field.id);
  final media = MediaQuery.of(context);
  final cacheWidth =
      (media.size.width * media.devicePixelRatio).ceil().clamp(1, 2048).toInt();
  final provider = fieldImageProvider(field, cacheWidth: cacheWidth);
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
            child: Center(
              child: Icon(
                Icons.stadium_rounded,
                size: 80,
                color: c.onInverse.withValues(alpha: 0.85),
              ),
            ),
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
