import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/features/seller_package/controllers/seller_package_controller.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/models/seller_package_overview_model.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/models/seller_insurance_overview_model.dart';
import 'package:sixvalley_vendor_app/features/seller_package/screens/seller_insurance_payment_screen.dart';
import 'package:sixvalley_vendor_app/features/seller_package/screens/seller_package_payment_screen.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class SellerPackageScreen extends StatefulWidget {
  const SellerPackageScreen({super.key});

  @override
  State<SellerPackageScreen> createState() => _SellerPackageScreenState();
}

class _SellerPackageScreenState extends State<SellerPackageScreen> {
  @override
  void initState() {
    super.initState();
    // Load subscription and insurance separately because they are backed by distinct seller APIs.
    Future.microtask(() {
      final controller = Provider.of<SellerPackageController>(context, listen: false);
      controller.getOverview();
      controller.getInsuranceStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBarWidget(title: getTranslated('packages', context) ?? 'Packages & Insurance'),
      body: Consumer<SellerPackageController>(
        builder: (context, controller, _) {
          final overview = controller.overview;
          if (overview == null) {
            return controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _EmptyState(onRefresh: controller.getOverview);
          }

          return RefreshIndicator(
            onRefresh: controller.getOverview,
            child: ListView(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              children: [
                _InsuranceStatusCard(summary: overview.subscription, insurance: controller.insuranceOverview),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                _CurrentPackageCard(summary: overview.subscription),
                const SizedBox(height: Dimensions.paddingSizeLarge),
                Text('Available packages', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                ...overview.packages.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                  child: _PackagePlanCard(plan: plan, overview: overview),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InsuranceStatusCard extends StatelessWidget {
  final SellerPackageSummary summary;
  final SellerInsuranceOverviewModel? insurance;

  const _InsuranceStatusCard({required this.summary, required this.insurance});

  @override
  Widget build(BuildContext context) {
    final active = insurance?.active ?? summary.insuranceSatisfied;
    final pending = insurance?.pendingReview ?? false;
    final enabled = insurance?.enabled ?? true;
    final color = active ? Colors.green : Theme.of(context).colorScheme.error;
    final text = !enabled ? 'Insurance is not enabled' : active ? 'Insurance active' : pending
        ? 'Insurance payment is under review' : 'Insurance required';

    return InkWell(
      // A pending insurance transfer cannot be replaced until the administrator decides on it.
      onTap: insurance != null && insurance!.canPay && !pending ? () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => SellerInsurancePaymentScreen(overview: insurance!),
      )) : null,
      borderRadius: BorderRadius.circular(8),
      child: _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(active ? Icons.verified_user_outlined : Icons.shield_outlined, color: color),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(text, style: titilliumSemiBold.copyWith(color: color))),
          if (pending || summary.pendingReview) const Icon(Icons.hourglass_top_outlined, color: Colors.orange),
        ]),
        if (insurance != null && enabled) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text('Insurance amount: ${insurance!.configuredAmount.toStringAsFixed(2)}', style: titilliumRegular),
        ],
      ])),
    );
  }
}

class _CurrentPackageCard extends StatelessWidget {
  final SellerPackageSummary summary;

  const _CurrentPackageCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final subscription = summary.active;
    if (subscription == null) {
      final waiting = summary.pending;
      return _SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(waiting == null ? 'No active package' : 'Package payment is under review', style: titilliumSemiBold),
          if (waiting != null) ...[
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Text(waiting.packageName, style: titilliumRegular),
          ],
        ]),
      );
    }

    return _SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.inventory_2_outlined),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(subscription.packageName, style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
          Text(subscription.paidPackagePrice.toStringAsFixed(2), style: titilliumSemiBold),
        ]),
        const Divider(height: Dimensions.paddingSizeLarge),
        _QuotaRow(icon: Icons.add_box_outlined, title: 'Product listings', value: subscription.remainingProductLimit),
        _QuotaRow(icon: Icons.search_outlined, title: 'Search promotions', value: subscription.remainingSearchPromotionLimit),
        _QuotaRow(icon: Icons.home_outlined, title: 'Homepage promotions', value: subscription.remainingHomepagePromotionLimit),
        _QuotaRow(icon: Icons.confirmation_number_outlined, title: 'Coupons', value: subscription.remainingCouponLimit),
        if (subscription.expiresAt != null) ...[
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text('Valid until: ${subscription.expiresAt}', style: titilliumRegular.copyWith(color: Theme.of(context).hintColor)),
        ],
      ]),
    );
  }
}

class _PackagePlanCard extends StatelessWidget {
  final SellerPackagePlan plan;
  final SellerPackageOverviewModel overview;

  const _PackagePlanCard({required this.plan, required this.overview});

  @override
  Widget build(BuildContext context) {
    final canSelect = !overview.subscription.pendingReview;
    return InkWell(
      // Keep a pending offline request immutable until an admin approves or rejects it.
      onTap: canSelect ? () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => SellerPackagePaymentScreen(plan: plan, overview: overview),
      )) : null,
      borderRadius: BorderRadius.circular(8),
      child: _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(plan.name, style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
          Text(plan.packagePrice.toStringAsFixed(2), style: titilliumSemiBold.copyWith(color: Theme.of(context).primaryColor)),
        ]),
        if (plan.description.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(plan.description, style: titilliumRegular),
        ],
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Wrap(spacing: Dimensions.paddingSizeDefault, runSpacing: Dimensions.paddingSizeExtraSmall, children: [
          _PlanFact(label: 'Listings', value: plan.productLimit),
          _PlanFact(label: 'Search', value: plan.searchPromotionLimit),
          _PlanFact(label: 'Homepage', value: plan.homepagePromotionLimit),
          _PlanFact(label: 'Coupons', value: plan.couponLimit),
          _PlanFact(label: 'Days', value: plan.packageValidityDays),
        ]),
      ])),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: .25)),
      ),
      child: child,
    );
  }
}

class _QuotaRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final int value;

  const _QuotaRow({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
      child: Row(children: [
        Icon(icon, size: Dimensions.iconSizeSmall, color: Theme.of(context).hintColor),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text(title, style: titilliumRegular)),
        Text(value.toString(), style: titilliumSemiBold),
      ]),
    );
  }
}

class _PlanFact extends StatelessWidget {
  final String label;
  final int value;

  const _PlanFact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$label: $value', style: titilliumRegular.copyWith(color: Theme.of(context).hintColor));
  }
}

class _EmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton(
        tooltip: 'Retry',
        onPressed: onRefresh,
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}
