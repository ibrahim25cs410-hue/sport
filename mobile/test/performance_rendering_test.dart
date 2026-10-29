import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riyada/models/field.dart';
import 'package:riyada/utils/field_image.dart';
import 'package:riyada/widgets/ambient_green_background.dart';
import 'package:riyada/widgets/skeleton_loaders.dart';

void main() {
  const field = Field(
    id: 1,
    name: 'Field',
    address: 'Address',
    phone: '07700000000',
    image:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
    pricePerHour: 1000,
    ownerId: 1,
  );

  test('field images are cached at the requested decode width', () {
    final first = fieldImageProvider(field, cacheWidth: 320);
    final second = fieldImageProvider(field, cacheWidth: 320);
    final larger = fieldImageProvider(field, cacheWidth: 640);

    expect(first, isA<ResizeImage>());
    expect((first! as ResizeImage).width, 320);
    expect(identical(first, second), isTrue);
    expect(identical(first, larger), isFalse);
  });

  testWidgets('ambient background does not use an image filter', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AmbientGreenBackground(child: SizedBox.expand())),
    );

    expect(find.byType(ImageFiltered), findsNothing);
  });

  testWidgets('skeleton boxes share one animation', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: FieldsListSkeleton(count: 2))),
    );

    final shimmerBuilders = find.descendant(
      of: find.byType(ShimmerBox),
      matching: find.byType(AnimatedBuilder),
    );
    final animations =
        tester
            .widgetList<AnimatedBuilder>(shimmerBuilders)
            .map((builder) => builder.animation)
            .toSet();

    expect(find.byType(ShimmerBox), findsNWidgets(6));
    expect(animations, hasLength(1));
  });
}
