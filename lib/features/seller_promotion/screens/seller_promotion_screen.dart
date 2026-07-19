import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/features/seller_promotion/controllers/seller_promotion_controller.dart';
import 'package:sixvalley_vendor_app/features/seller_promotion/domain/models/seller_promotion_overview_model.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';

class SellerPromotionScreen extends StatefulWidget {
  const SellerPromotionScreen({super.key});

  @override
  State<SellerPromotionScreen> createState() => _SellerPromotionScreenState();
}

class _SellerPromotionScreenState extends State<SellerPromotionScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = Provider.of<SellerPromotionController>(context, listen: false);
      // Both summaries come from the backend, where package quotas and insurance are enforced.
      controller.getOverview(SellerPromotionType.search);
      controller.getOverview(SellerPromotionType.homepage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: const CustomAppBarWidget(title: 'Promotions'),
        body: Column(children: [
          Container(
            color: Theme.of(context).cardColor,
            child: const TabBar(tabs: [
              Tab(text: 'Search results'),
              Tab(text: 'Homepage'),
            ]),
          ),
          const Expanded(child: TabBarView(children: [
            _PromotionTypeView(type: SellerPromotionType.search),
            _PromotionTypeView(type: SellerPromotionType.homepage),
          ])),
        ]),
      ),
    );
  }
}

class _PromotionTypeView extends StatelessWidget {
  final SellerPromotionType type;

  const _PromotionTypeView({required this.type});

  @override
  Widget build(BuildContext context) {
    return Consumer<SellerPromotionController>(builder: (context, controller, _) {
      final overview = controller.overview(type);
      if (overview == null) {
        return controller.isLoading(type)
            ? const Center(child: CircularProgressIndicator())
            : Center(child: IconButton(
              tooltip: 'Retry', icon: const Icon(Icons.refresh),
              onPressed: () => controller.getOverview(type),
            ));
      }

      return RefreshIndicator(
        onRefresh: () => controller.getOverview(type),
        child: ListView(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          children: [
            _PromotionQuotaCard(summary: overview.summary, type: type),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text('Eligible products', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            if (overview.products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge),
                child: Center(child: Text('No approved products are available.')),
              ),
            ...overview.products.map((product) => _PromotionProductTile(
              product: product, summary: overview.summary, type: type,
            )),
          ],
        ),
      );
    });
  }
}

class _PromotionQuotaCard extends StatelessWidget {
  final SellerPromotionSummary summary;
  final SellerPromotionType type;

  const _PromotionQuotaCard({required this.summary, required this.type});

  @override
  Widget build(BuildContext context) {
    final title = type == SellerPromotionType.search ? 'Search promotion' : 'Homepage promotion';
    final available = summary.canPromote;
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: .25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(type == SellerPromotionType.search ? Icons.search : Icons.home_outlined),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: Text(title, style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge))),
          Icon(available ? Icons.verified_outlined : Icons.lock_outline,
            color: available ? Colors.green : Theme.of(context).colorScheme.error),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text('Remaining: ${summary.remaining} / ${summary.limit}', style: titilliumSemiBold),
        Text('Duration: ${summary.durationDays} days', style: titilliumRegular),
        if (summary.activePackage != null) Text('Package: ${summary.activePackage}', style: titilliumRegular),
        if (!summary.insuranceSatisfied)
          Text('Insurance activation is required.', style: titilliumRegular.copyWith(color: Theme.of(context).colorScheme.error)),
      ]),
    );
  }
}

class _PromotionProductTile extends StatelessWidget {
  final SellerPromotionProduct product;
  final SellerPromotionSummary summary;
  final SellerPromotionType type;

  const _PromotionProductTile({required this.product, required this.summary, required this.type});

  @override
  Widget build(BuildContext context) {
    final canActivate = summary.canPromote && !product.isPromoted;
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: titilliumSemiBold),
        subtitle: product.isPromoted
            ? Text('Active until: ${product.expiresAt ?? '-'}', style: titilliumRegular)
            : null,
        trailing: product.isPromoted
            ? const Icon(Icons.verified, color: Colors.green)
            : IconButton(
              tooltip: 'Activate promotion',
              onPressed: canActivate ? () => _activate(context) : null,
              icon: const Icon(Icons.campaign_outlined),
            ),
      ),
    );
  }

  Future<void> _activate(BuildContext context) async {
    final activated = await Provider.of<SellerPromotionController>(context, listen: false)
        .activatePromotion(type: type, productId: product.id);
    if (activated && context.mounted) {
      showCustomSnackBarWidget('Promotion activated successfully.', context, isError: false);
    }
  }
}
