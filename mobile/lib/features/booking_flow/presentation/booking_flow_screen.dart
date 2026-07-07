import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../domain/enums/payment_method.dart';
import '../../../models/field.dart';
import '../../../theme/design_tokens.dart';
import '../../../theme/riyada_theme_extension.dart';
import '../../../utils/l10n_extension.dart';
import '../../../widgets/premium/glass_surface.dart';
import '../../payment/presentation/payment_widgets.dart';

class BookingFlowScreen extends StatefulWidget {
  const BookingFlowScreen({super.key, required this.field});

  final Field field;

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  int _step = 0;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _hours = 1;
  PaymentMethod _method = PaymentMethod.visa;
  bool _paying = false;
  String? _reference;

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    setState(() => _paying = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _paying = false;
      _reference = 'RYD-${DateTime.now().millisecondsSinceEpoch}';
      _step = 4;
    });
  }

  List<Widget> _stepSlivers(AppLocalizations l10n) {
    return switch (_step) {
      0 => [
        SliverToBoxAdapter(
          child: CalendarDatePicker(
            initialDate: _date,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 90)),
            onDateChanged: (d) => setState(() => _date = d),
          ),
        ),
      ],
      1 => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.selectDuration,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _hours.toDouble(),
                min: 1,
                max: 4,
                divisions: 3,
                activeColor: DesignTokens.primaryTeal,
                label: '$_hours',
                onChanged: (v) => setState(() => _hours = v.round()),
              ),
              ListTile(
                title: Text(l10n.startTime),
                trailing: TextButton(
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _time,
                    );
                    if (t != null) setState(() => _time = t);
                  },
                  child: Text(_time.format(context)),
                ),
              ),
            ],
          ),
        ),
      ],
      2 => [
        SliverToBoxAdapter(
          child: PaymentSummaryCard(
            fieldName: widget.field.name,
            date: '${_date.toLocal()} ${_time.format(context)}',
            hours: _hours,
            total: widget.field.pricePerHour * _hours,
          ),
        ),
      ],
      3 => [
        SliverToBoxAdapter(
          child: PaymentMethodSelector(
            selected: _method,
            onSelected: (PaymentMethod m) => setState(() => _method = m),
          ),
        ),
      ],
      _ => [SliverFillRemaining(hasScrollBody: false, child: _success(l10n))],
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final titles = [
      l10n.chooseDate,
      l10n.chooseTime,
      l10n.confirmBooking,
      l10n.payment,
      l10n.bookingSuccess,
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(titles[_step.clamp(0, 4)])),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceLg,
                      DesignTokens.spaceLg,
                      DesignTokens.spaceLg,
                      DesignTokens.spaceSm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _StepIndicator(current: _step, total: 5),
                    ),
                  ),
                  ..._stepSlivers(l10n),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: DesignTokens.spaceSm),
                  ),
                ],
              ),
            ),
            if (_step < 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceLg,
                  DesignTokens.spaceSm,
                  DesignTokens.spaceLg,
                  DesignTokens.spaceLg,
                ),
                child: PayNowButton(
                  amount: widget.field.pricePerHour * _hours,
                  onPressed: _next,
                  loading: _paying && _step == 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _success(AppLocalizations l10n) {
    final code = _reference ?? 'RYD-DEMO';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: GlassSurface(
          borderRadius: DesignTokens.radiusXl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: DesignTokens.primaryTeal,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.bookingSuccess,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                code,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(data: code, size: 160, backgroundColor: Colors.white),
              const SizedBox(height: 8),
              Text(
                l10n.qrTicketHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 4,
            margin: EdgeInsetsDirectional.only(end: i < total - 1 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? c.primary : c.surfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}
