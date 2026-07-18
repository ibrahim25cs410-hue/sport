import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/payment_policy.dart';
import '../../../core/booking/booking_result.dart';
import '../../../core/providers/booking_actions_provider.dart';
import '../../../core/utils/session_key_helper.dart';
import '../../../domain/booking/booking_policy.dart';
import '../../../models/booking_checkout_args.dart';
import '../../../models/field.dart';
import '../../../models/schedule.dart';
import '../../../providers/session_key.dart';
import '../../../router/app_router.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/booking_messages.dart';
import '../../../utils/format.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/common.dart';
import '../../../widgets/price_text.dart';
import '../../../widgets/fintech/fintech_card.dart';
import '../../shell/shell_state.dart';

/// حجز جديد — 3 خطوات فقط: التاريخ → الوقت → التأكيد.
class NewBookingTab extends ConsumerStatefulWidget {
  const NewBookingTab({super.key});

  @override
  ConsumerState<NewBookingTab> createState() => _NewBookingTabState();
}

class _NewBookingTabState extends ConsumerState<NewBookingTab> with AutomaticKeepAliveClientMixin {
  int _step = 0;
  DateTime _date = DateTime.now();
  TimeSlot? _slot;
  bool _submitting = false;

  @override
  bool get wantKeepAlive => true;

  List<TimeSlot> _slotsForDate(FieldSchedule? schedule, DateTime day) {
    if (schedule == null) return const [];
    final d = DateTime(day.year, day.month, day.day);
    for (final daySchedule in schedule.schedule) {
      final sd = DateTime(daySchedule.date.year, daySchedule.date.month, daySchedule.date.day);
      if (sd == d) {
        return daySchedule.slots.where((s) => BookingPolicy.isSlotBookable(s)).toList();
      }
    }
    return const [];
  }

  Future<void> _confirm(Field field, UserSessionKey key) async {
    final slot = _slot;
    if (slot == null) return;
    final l10n = context.l10n;
    setState(() => _submitting = true);
    try {
      final scheduleKey = FieldScheduleKey(session: key, fieldId: field.id);
      final schedule = ref.read(fieldScheduleProvider(scheduleKey)).valueOrNull;
      final result = await ref.read(bookingActionsProvider(key)).createBooking(
            fieldId: field.id,
            startTime: slot.startTime,
            hours: slot.hours,
            fieldPricePerHour: field.pricePerHour,
            fieldName: field.name,
            fieldAddress: field.address,
            fieldPhone: field.phone,
            paymentMethod: 'cash',
            slot: slot,
            schedule: schedule,
          );
      if (!mounted) return;
      switch (result) {
        case BookingOk(:final value):
          if (PaymentPolicy.electronicPaymentsEnabled && value.needsPayment) {
            await context.goBookingCheckout(BookingCheckoutArgs(
              bookingId: value.id,
              totalPrice: value.totalPrice,
              fieldName: field.name,
              referenceCode: value.referenceCode,
            ));
          } else {
            final msg = value.referenceCode != null ? l10n.bookingSentRef(value.referenceCode!) : l10n.bookingSent;
            showAppSnackBar(context, msg);
          }
          setState(() {
            _step = 0;
            _slot = null;
          });
          ref.read(shellTabProvider.notifier).select(1); // حجوزاتي
        case BookingErr(:final failure):
          showAppWarningSnackBar(context, bookingFailureMessage(l10n, failure));
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<Widget> _stepSlivers(
    BuildContext context, {
    required Field field,
    required List<TimeSlot> slots,
    required bool loadingSlots,
    required AppLocalizations l10n,
    required RiyadaColors c,
  }) {
    return switch (_step) {
      0 => [
          SliverToBoxAdapter(
            child: CalendarDatePicker(
              initialDate: _date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              onDateChanged: (d) => setState(() {
                _date = d;
                _slot = null;
              }),
            ),
          ),
        ],
      1 when loadingSlots => [
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      1 when slots.isEmpty => [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.schedule_rounded, title: l10n.noSlots, subtitle: l10n.noSlotsHint),
          ),
        ],
      1 => [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  final slot = slots[i];
                  final selected = _slot?.startTime == slot.startTime;
                  return RepaintBoundary(
                    child: FintechCard(
                      margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 12),
                      onTap: () => setState(() => _slot = slot),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_rounded, color: selected ? c.primary : c.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formatTimeRange12Ar(slot.startTime, slot.hours),
                              style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
                            ),
                          ),
                          if (selected) Icon(Icons.check_circle_rounded, color: c.primary),
                        ],
                      ),
                    ),
                  );
                },
                childCount: slots.length,
              ),
            ),
          ),
        ],
      _ => [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
            sliver: SliverToBoxAdapter(
              child: FintechCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.bookingSummary, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _summaryRow(context, l10n.labelField, field.name),
                    _summaryRow(context, l10n.labelDateTime, formatTimeRange12Ar(_slot!.startTime, _slot!.hours)),
                    _summaryRow(context, l10n.labelDuration, l10n.hours(_slot!.hours)),
                    _summaryRow(context, l10n.subtotal, formatMoney(BookingPolicy.calculateTotal(_slot!.hours)), bold: true),
                  ],
                ),
              ),
            ),
          ),
        ],
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final c = context.colors;
    final key = watchSessionKey(ref);
    final field = ref.watch(selectedFieldProvider);

    if (key == null) return const SizedBox.shrink();

    if (field == null) {
      return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(l10n.newBookingTab)),
        body: EmptyState(
          icon: Icons.stadium_outlined,
          title: l10n.pickFieldFirst,
          subtitle: l10n.pickFieldFirstHint,
          actionLabel: l10n.homeTab,
          onAction: () => ref.read(shellTabProvider.notifier).select(0),
        ),
      );
    }

    final scheduleKey = FieldScheduleKey(session: key, fieldId: field.id);
    final scheduleAsync = ref.watch(fieldScheduleProvider(scheduleKey));
    final schedule = scheduleAsync.valueOrNull;
    final slots = _slotsForDate(schedule, _date);
    final loadingSlots = scheduleAsync.isLoading && schedule == null;

    final steps = [l10n.chooseDate, l10n.chooseTime, l10n.confirmBooking];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(l10n.newBookingTab),
        actions: [
          TextButton(
            onPressed: () => ref.read(selectedFieldProvider.notifier).clear(),
            child: Text(l10n.changeField),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                        DesignTokens.spaceLg,
                        0,
                      ),
                      child: FintechCard(
                        margin: EdgeInsets.zero,
                        padding: const EdgeInsets.all(DesignTokens.spaceMd),
                        child: Row(
                          children: [
                            Icon(Icons.stadium_rounded, color: c.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    field.name,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    field.address,
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _StepHeader(labels: steps, current: _step)),
                  ..._stepSlivers(
                    context,
                    field: field,
                    slots: slots,
                    loadingSlots: loadingSlots,
                    l10n: l10n,
                    c: c,
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spaceSm)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceSm,
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => setState(() => _step--),
                        child: Text(l10n.back),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_step < 2) {
                                if (_step == 1 && _slot == null) {
                                  showAppSnackBar(context, l10n.selectTime);
                                  return;
                                }
                                setState(() => _step++);
                                return;
                              }
                              _confirm(field, key);
                            },
                      child: _submitting
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: c.onPrimary),
                            )
                          : Text(_step < 2 ? l10n.next : l10n.confirmBooking),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: 8),
          Flexible(
            child: bold
                ? PriceText(
                    value,
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.labels, required this.current});

  final List<String> labels;
  final int current;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(labels.length, (i) {
          final active = i <= current;
          final done = i < current;
          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: active ? c.primary : c.surfaceVariant,
                        child: done
                            ? Icon(Icons.check, size: 16, color: c.onPrimary)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(fontSize: 12, color: active ? c.onPrimary : c.onSurfaceVariant),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                              color: i == current ? c.primary : c.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (i < labels.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Container(
                        height: 2,
                        color: i < current ? c.primary : c.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
