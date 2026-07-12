import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/booking/booking_result.dart';
import '../core/providers/booking_actions_provider.dart';
import '../core/providers/review_provider.dart';
import '../core/providers/slot_actions_provider.dart';
import '../core/providers/repository_providers.dart';
import '../domain/booking/booking_policy.dart';
import '../exceptions/booking_conflict_exception.dart';
import '../models/booking_checkout_args.dart';
import '../models/field.dart';
import '../models/schedule.dart';
import '../models/slot_hold.dart';
import '../providers/auth_provider.dart';
import '../providers/session_key.dart';
import '../providers/socket_provider.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/riyada_theme_extension.dart';
import '../utils/booking_messages.dart';
import '../utils/error_messages.dart';
import '../utils/field_image.dart';
import '../utils/format.dart';
import '../utils/l10n_extension.dart';
import '../widgets/price_text.dart';
import '../utils/phone_launcher.dart';
import '../utils/realtime_l10n.dart';
import '../widgets/booking_confirm_sheet.dart';
import '../widgets/common.dart';
import '../widgets/payment_method_selector.dart';
import '../widgets/skeleton_loaders.dart';
import '../widgets/star_rating.dart';
import '../router/app_router.dart';
import '../features/shell/shell_state.dart';

class FieldDetailScreen extends ConsumerStatefulWidget {
  const FieldDetailScreen({super.key, required this.field});
  final Field field;

  @override
  ConsumerState<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends ConsumerState<FieldDetailScreen> {
  TimeSlot? _selected;
  bool _booking = false;
  bool _selectingSlot = false;
  bool _submittingReview = false;
  int _selectedRating = 0;
  UserSessionKey? _sessionKey;

  final Map<String, int> _heldByUserId = {};
  final Map<String, DateTime> _heldExpiresAt = {};
  Timer? _holdExpiryTimer;
  ProviderSubscription<AsyncValue<FieldSchedule>>? _scheduleSub;
  ProviderSubscription<int>? _slotSub;
  ProviderSubscription<int>? _bookingSub;

  FieldScheduleKey? get _scheduleKey {
    final session = _sessionKey;
    if (session == null) return null;
    return FieldScheduleKey(session: session, fieldId: widget.field.id);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      if (!mounted) return;
      showAppWarningSnackBar(context, context.l10n.loginSubtitle);
      context.goLogin();
      return;
    }

    final client = ref.read(apiClientProvider);
    _sessionKey = UserSessionKey(client: client, userId: user.id);
    setState(() {});

    try {
      await ref.read(socketProvider.notifier).ensureConnected();
      ref.read(socketProvider.notifier).joinField(widget.field.id);
    } catch (_) {
      // Booking still works via REST without a live socket.
    }

    _holdExpiryTimer = Timer.periodic(const Duration(seconds: 5), (_) => _purgeExpiredHolds());
    _wireRealtimeListeners();
  }

  void _wireRealtimeListeners() {
    final scheduleKey = _scheduleKey;
    if (scheduleKey != null) {
      _scheduleSub = ref.listenManual<AsyncValue<FieldSchedule>>(
        fieldScheduleProvider(scheduleKey),
        (prev, next) {
          next.whenData((s) {
            if (!mounted) return;
            setState(() => _applyScheduleHolds(s));
          });
        },
      );
    }

    _slotSub = ref.listenManual<int>(
      socketProvider.select((s) => s.slotGeneration),
      (prev, next) {
        if (prev == null || next == prev) return;
        final state = ref.read(socketProvider);
        if (state.lastSlotSelection != null) _applySlotSelection(state.lastSlotSelection!);
        if (state.lastSlotRelease != null) _applySlotRelease(state.lastSlotRelease!);
      },
    );

    _bookingSub = ref.listenManual<int>(
      socketProvider.select((s) => s.generation),
      (prev, next) {
        if (prev == null || next == prev || _scheduleKey == null) return;
        unawaited(_reloadSchedule());
      },
    );
  }

  void _purgeExpiredHolds() {
    if (!mounted) return;
    final now = DateTime.now().toUtc();
    final expired = _heldExpiresAt.entries.where((e) => e.value.isBefore(now)).map((e) => e.key).toList();
    if (expired.isEmpty) return;

    TimeSlot? clearedSelection;
    for (final k in expired) {
      if (_selected != null && slotKey(_selected!.startTime, _selected!.hours) == k) {
        clearedSelection = _selected;
      }
    }

    setState(() {
      for (final k in expired) {
        _heldByUserId.remove(k);
        _heldExpiresAt.remove(k);
      }
      if (clearedSelection != null) _selected = null;
    });

    if (clearedSelection != null && mounted) {
      showAppWarningSnackBar(context, context.l10n.slotLockExpired);
    }
  }

  @override
  void dispose() {
    _holdExpiryTimer?.cancel();
    _scheduleSub?.close();
    _slotSub?.close();
    _bookingSub?.close();
    _releaseCurrentSlot(silent: true);
    ref.read(socketProvider.notifier).leaveField(widget.field.id);
    super.dispose();
  }

  int get _userId => ref.read(authProvider).user?.id ?? 0;

  Future<void> _reloadSchedule() async {
    final key = _scheduleKey;
    if (key == null) return;
    ref.invalidate(fieldScheduleProvider(key));
  }

  void _applyScheduleHolds(FieldSchedule schedule) {
    for (final day in schedule.schedule) {
      for (final slot in day.slots) {
        if (!slot.isHeld) continue;
        final k = slotKey(slot.startTime, slot.hours);
        if (_heldByUserId[k] == _userId) continue;
        _heldByUserId[k] = -1;
        if (slot.heldUntil != null) _heldExpiresAt[k] = slot.heldUntil!.toUtc();
      }
    }
  }

  bool _hasAvailableSlots(FieldSchedule? schedule) =>
      schedule?.schedule.any((d) => d.slots.any((s) => BookingPolicy.isSlotBookable(s, schedule: schedule))) ?? false;

  bool _isHeldByOther(TimeSlot slot) {
    final isMine = _selected?.startTime == slot.startTime && _selected?.hours == slot.hours;
    if (isMine) return false;
    if (slot.isHeld) return true;
    final holder = _heldByUserId[slotKey(slot.startTime, slot.hours)];
    return holder != null && holder != _userId;
  }

  void _applySlotSelection(SlotSelectionEvent event) {
    if (event.fieldId != widget.field.id) return;
    if (event.expiresAt.isBefore(DateTime.now().toUtc())) return;
    setState(() {
      _heldByUserId[slotKey(event.startTime, event.hours)] = event.userId;
      _heldExpiresAt[slotKey(event.startTime, event.hours)] = event.expiresAt;
      if (event.userId != _userId &&
          _selected != null &&
          _selected!.startTime == event.startTime &&
          _selected!.hours == event.hours) {
        _selected = null;
      }
    });
  }

  void _applySlotRelease(SlotReleaseEvent event) {
    if (event.fieldId != widget.field.id) return;
    setState(() {
      final k = slotKey(event.startTime, event.hours);
      _heldByUserId.remove(k);
      _heldExpiresAt.remove(k);
    });
  }

  Future<void> _releaseCurrentSlot({bool silent = false}) async {
    final sel = _selected;
    final session = _sessionKey;
    if (sel == null || session == null) return;
    try {
      await ref.read(slotActionsProvider(session)).release(
            fieldId: widget.field.id,
            startTime: sel.startTime,
            hours: sel.hours,
          );
    } catch (_) {
      if (!silent && mounted) showAppWarningSnackBar(context, context.l10n.retry);
    }
    if (mounted) {
      setState(() {
        final k = slotKey(sel.startTime, sel.hours);
        _heldByUserId.remove(k);
        _heldExpiresAt.remove(k);
        _selected = null;
      });
    }
  }

  Future<void> _onSlotTap(TimeSlot slot, FieldSchedule schedule) async {
    final session = _sessionKey;
    if (session == null || _selectingSlot || _isHeldByOther(slot)) return;
    if (!BookingPolicy.isSlotBookable(slot, schedule: schedule)) return;
    final l10n = context.l10n;
    final slots = ref.read(slotActionsProvider(session));

    if (_selected != null &&
        _selected!.startTime == slot.startTime &&
        _selected!.hours == slot.hours) {
      await _releaseCurrentSlot();
      return;
    }

    if (_selected != null) {
      await slots.release(
        fieldId: widget.field.id,
        startTime: _selected!.startTime,
        hours: _selected!.hours,
      );
      if (mounted) {
        setState(() {
          _heldByUserId.remove(slotKey(_selected!.startTime, _selected!.hours));
          _selected = null;
        });
      }
    }

    setState(() => _selectingSlot = true);
    try {
      final expiresAt = await slots.select(
        fieldId: widget.field.id,
        startTime: slot.startTime,
        hours: slot.hours,
      );
      if (!mounted || expiresAt == null) return;
      setState(() {
        _selected = slot;
        final k = slotKey(slot.startTime, slot.hours);
        _heldByUserId[k] = _userId;
        _heldExpiresAt[k] = expiresAt.toUtc();
      });
    } on BookingConflictException catch (e) {
      if (mounted) showAppWarningSnackBar(context, slotConflictMessage(l10n, e.messageKey));
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _selectingSlot = false);
    }
  }

  Future<void> _book() async {
    final session = _sessionKey;
    if (_selected == null || session == null) return;
    final l10n = context.l10n;

    final paymentMethod = await showPaymentMethodSelector(context);
    if (paymentMethod == null || !mounted) return;

    final confirmed = await showBookingConfirmSheet(
      context: context,
      field: widget.field,
      startTime: _selected!.startTime,
      hours: _selected!.hours,
    );
    if (confirmed != true || !mounted) return;
    final scheduleKey = _scheduleKey;
    final schedule = scheduleKey != null ? ref.read(fieldScheduleProvider(scheduleKey)).valueOrNull : null;
    setState(() => _booking = true);
    try {
      final result = await ref.read(bookingActionsProvider(session)).createBooking(
            fieldId: widget.field.id,
            startTime: _selected!.startTime,
            hours: _selected!.hours,
            fieldPricePerHour: widget.field.pricePerHour,
            fieldName: widget.field.name,
            fieldAddress: widget.field.address,
            fieldPhone: widget.field.phone,
            paymentMethod: paymentMethod.apiValue,
            slot: _selected,
            schedule: schedule,
          );
      if (!mounted) return;
      switch (result) {
        case BookingOk(:final value):
          if (value.needsPayment) {
            final paid = await context.goBookingCheckout(BookingCheckoutArgs(
              bookingId: value.id,
              totalPrice: value.totalPrice,
              fieldName: widget.field.name,
              referenceCode: value.referenceCode,
            ));
            if (!mounted) return;
            if (paid == true) {
              context.popResult();
            }
          } else {
            final msg = value.referenceCode != null ? l10n.bookingSentRef(value.referenceCode!) : l10n.bookingSent;
            showAppSnackBar(context, msg);
            ref.read(shellTabProvider.notifier).select(1); // حجوزاتي
            context.popResult();
          }
        case BookingErr(:final failure):
          showAppWarningSnackBar(context, bookingFailureMessage(l10n, failure));
          if (failure.code == BookingFailureCode.conflict ||
              failure.code == BookingFailureCode.slotUnavailable) {
            await _releaseCurrentSlot(silent: true);
            await _reloadSchedule();
          }
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  Future<void> _submitReview(FieldReviewKey reviewKey) async {
    if (_selectedRating < 1) return;
    setState(() => _submittingReview = true);
    final l10n = context.l10n;
    try {
      await ref.read(reviewRepositoryProvider(reviewKey.session.client)).submitReview(
            fieldId: reviewKey.fieldId,
            rating: _selectedRating,
          );
      ref.invalidate(fieldReviewEligibilityProvider(reviewKey));
      ref.invalidate(fieldsListProvider(reviewKey.session));
      if (mounted) showAppSnackBar(context, l10n.reviewSubmitted);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _submittingReview = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = context.l10n;
    final scheduleKey = _scheduleKey;
    final reviewKey = _sessionKey == null ? null : FieldReviewKey(session: _sessionKey!, fieldId: widget.field.id);
    final reviewAsync = reviewKey == null ? null : ref.watch(fieldReviewEligibilityProvider(reviewKey));
    final reviewInfo = reviewAsync?.valueOrNull;
    final scheduleAsync = scheduleKey == null ? null : ref.watch(fieldScheduleProvider(scheduleKey));
    final schedule = scheduleAsync?.valueOrNull;
    final loading = scheduleKey == null || (scheduleAsync?.isLoading == true && schedule == null);

    return RtlScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.transparent,
              ],
            ),
          ),
        ),
        title: Text(widget.field.name),
      ),
      body: loading
          ? const ScheduleSkeleton()
          : scheduleAsync?.hasError == true && schedule == null
              ? EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: l10n.retry,
                  subtitle: friendlyErrorMessage(scheduleAsync?.error),
                  actionLabel: l10n.retry,
                  onAction: _reloadSchedule,
                )
              : RefreshIndicator(
                  onRefresh: _reloadSchedule,
                  color: DesignTokens.primaryTeal,
                  child: Stack(
                    children: [
                      CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // UI polish: صورة البطل + تدرج — يمكن إضافة Hero(tag) للانتقال من StadiumCard.
                          SliverToBoxAdapter(child: fieldHeroImage(context, widget.field)),
                          SliverToBoxAdapter(
                            child: Transform.translate(
                              // تداخل البطاقة فوق الصورة (overlap) — نمط premium شائع.
                              offset: const Offset(0, -DesignTokens.spaceLg),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                                child: Card(
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                                    side: BorderSide(color: c.outline.withValues(alpha: 0.2)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                widget.field.name,
                                                style: Theme.of(context).textTheme.headlineMedium,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: DesignTokens.spaceSm,
                                                vertical: DesignTokens.spaceSm,
                                              ),
                                              decoration: BoxDecoration(
                                                color: c.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                              ),
                                              child: PriceText(
                                                '${formatMoney(widget.field.pricePerHour)}${l10n.perHour}',
                                                style: Theme.of(context).textTheme.titleMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (reviewInfo != null && reviewInfo.reviewCount > 0) ...[
                                          const SizedBox(height: DesignTokens.spaceSm),
                                          StarRatingDisplay(
                                            rating: reviewInfo.averageRating,
                                            reviewCount: reviewInfo.reviewCount,
                                          ),
                                        ],
                                        const SizedBox(height: DesignTokens.spaceMd),
                                        InfoTile(icon: Icons.location_on_outlined, text: widget.field.address),
                                        InkWell(
                                          onTap: () => launchPhoneCall(widget.field.phone),
                                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                          child: InfoTile(
                                            icon: Icons.phone_outlined,
                                            text: '${widget.field.phone} — ${l10n.tapToCall}',
                                            color: c.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (reviewKey != null && reviewInfo != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  DesignTokens.spaceMd,
                                  0,
                                  DesignTokens.spaceMd,
                                  DesignTokens.spaceMd,
                                ),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(l10n.rateField, style: Theme.of(context).textTheme.titleMedium),
                                        const SizedBox(height: DesignTokens.spaceSm),
                                        if (reviewInfo.userRating != null)
                                          Column(
                                            children: [
                                              Text(l10n.yourRating, style: Theme.of(context).textTheme.bodyMedium),
                                              StarRatingDisplay(rating: reviewInfo.userRating!.toDouble()),
                                            ],
                                          )
                                        else if (reviewInfo.canReview) ...[
                                          StarRatingInput(
                                            value: _selectedRating,
                                            onChanged: (v) => setState(() => _selectedRating = v),
                                          ),
                                          FilledButton(
                                            onPressed: _submittingReview || _selectedRating < 1
                                                ? null
                                                : () => _submitReview(reviewKey),
                                            child: _submittingReview
                                                ? const SizedBox(
                                                    height: 22,
                                                    width: 22,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : Text(l10n.submitReview),
                                          ),
                                        ]
                                        else if (reviewInfo.hasBooked)
                                          Text(l10n.alreadyReviewed, style: Theme.of(context).textTheme.bodyMedium)
                                        else
                                          Text(
                                            l10n.reviewOnlyAfterBooking,
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SectionHeader(
                              title: l10n.selectTime,
                              trailing: Text(l10n.week, style: Theme.of(context).textTheme.bodyMedium),
                            ),
                          ),
                          if (!_hasAvailableSlots(schedule))
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(
                                icon: Icons.event_busy_rounded,
                                title: l10n.noSlots,
                                subtitle: l10n.noSlotsHint,
                              ),
                            )
                          else
                            ..._scheduleDaySlivers(context, schedule!, l10n),
                          SliverToBoxAdapter(child: SizedBox(height: _selected != null ? 120 : DesignTokens.spaceLg)),
                        ],
                      ),
                      if (_selected != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(
                              DesignTokens.spaceLg,
                              DesignTokens.spaceMd,
                              DesignTokens.spaceLg,
                              DesignTokens.spaceLg,
                            ),
                            decoration: BoxDecoration(
                              color: c.card,
                              boxShadow: [
                                BoxShadow(color: c.shadow, blurRadius: 20, offset: const Offset(0, -4)),
                              ],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
                            ),
                            child: SafeArea(
                              top: false,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    formatTimeRange12Ar(_selected!.startTime, _selected!.hours),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    l10n.hours(_selected!.hours),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: DesignTokens.spaceSm),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(l10n.total, style: Theme.of(context).textTheme.bodyMedium),
                                            PriceText(
                                              formatMoney(
                                                BookingPolicy.quoteBookingPrice(
                                                  basePricePerHour: widget.field.pricePerHour,
                                                  date: _selected!.startTime,
                                                  hours: _selected!.hours,
                                                  loyaltyPoints: ref.watch(authProvider).user?.loyaltyPoints ?? 0,
                                                ).total,
                                              ),
                                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: FilledButton(
                                          onPressed: (_booking || _selectingSlot) ? null : _book,
                                          style: FilledButton.styleFrom(
                                            minimumSize: const Size(0, 48),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                            ),
                                          ),
                                          child: _booking
                                              ? SizedBox(
                                                  height: 22,
                                                  width: 22,
                                                  child: CircularProgressIndicator(color: c.onPrimary, strokeWidth: 2),
                                                )
                                              : Text(l10n.confirmBooking),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  List<Widget> _scheduleDaySlivers(BuildContext context, FieldSchedule schedule, AppLocalizations l10n) {
    final slivers = <Widget>[];
    final columns = _slotColumns(context);

    for (final day in schedule.schedule) {
      final slots = day.slots;
      if (slots.isEmpty) continue;

      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceSm, DesignTokens.spaceMd, 0),
            child: Text(
              formatDateTime(day.date).split(' ').take(3).join(' '),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceMd,
            DesignTokens.spaceSm,
            DesignTokens.spaceMd,
            DesignTokens.spaceMd,
          ),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: DesignTokens.spaceSm,
              crossAxisSpacing: DesignTokens.spaceSm,
              childAspectRatio: columns >= 4 ? 2.4 : 2.1,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => Align(
                alignment: Alignment.center,
                child: _slotChip(slots[i], schedule),
              ),
              childCount: slots.length,
            ),
          ),
        ),
      );
    }
    return slivers;
  }

  int _slotColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 720) return 4;
    if (w >= 480) return 3;
    return 2;
  }

  Widget _slotChip(TimeSlot slot, FieldSchedule schedule) {
    final c = context.colors;
    final l10n = context.l10n;
    final heldByOther = _isHeldByOther(slot);
    final isMine = _selected?.startTime == slot.startTime && _selected?.hours == slot.hours;
    final bookable = BookingPolicy.isSlotBookable(slot, schedule: schedule);
    final timeLabel = '${formatTime12Ar(slot.startTime)} • ${slot.hours}س';

    if (!bookable && !heldByOther && !isMine) {
      return FilterChip(
        avatar: Icon(Icons.block_rounded, size: 16, color: c.onSurfaceVariant.withValues(alpha: 0.5)),
        label: Text(
          timeLabel,
          style: TextStyle(color: c.onSurfaceVariant.withValues(alpha: 0.55), fontWeight: FontWeight.w500, fontSize: 12),
        ),
        onSelected: null,
        backgroundColor: c.surfaceVariant.withValues(alpha: 0.35),
        side: BorderSide(color: c.outline.withValues(alpha: 0.2)),
        showCheckmark: false,
      );
    }

    if (heldByOther) {
      return FilterChip(
        avatar: Icon(Icons.hourglass_top_rounded, size: 16, color: c.warning),
        label: Text(
          l10n.slotUnderSelection,
          style: TextStyle(color: c.onSurfaceVariant, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        onSelected: null,
        backgroundColor: c.warningSurface.withValues(alpha: context.isDarkMode ? 0.35 : 0.22),
        side: BorderSide(color: c.warning.withValues(alpha: 0.4)),
        showCheckmark: false,
      );
    }

    return FilterChip(
      avatar: isMine ? Icon(Icons.check_rounded, size: 16, color: c.onPrimary) : null,
      label: Text(timeLabel),
      selected: isMine,
      onSelected: _selectingSlot ? null : (_) => _onSlotTap(slot, schedule),
      selectedColor: c.primary,
      checkmarkColor: c.onPrimary,
      labelStyle: TextStyle(
        color: isMine ? c.onPrimary : null,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
