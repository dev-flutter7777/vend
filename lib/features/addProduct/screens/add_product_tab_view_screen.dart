import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/features/addProduct/domain/models/add_product_model.dart';
import 'package:sixvalley_vendor_app/features/addProduct/domain/models/edt_product_model.dart';
import 'package:sixvalley_vendor_app/features/addProduct/domain/models/product_general_info_data_model.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_next_screen.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_screen.dart';
import 'package:sixvalley_vendor_app/features/addProduct/screens/add_product_seo_screen.dart';
import 'package:sixvalley_vendor_app/features/addProduct/widgets/add_product_tabbar_widget.dart';
import 'package:sixvalley_vendor_app/features/ai/widgets/genertate_count_widget.dart';
import 'package:sixvalley_vendor_app/features/product/domain/models/product_model.dart';
import 'package:sixvalley_vendor_app/features/seller_package/controllers/seller_package_controller.dart';
import 'package:sixvalley_vendor_app/features/seller_package/screens/seller_package_screen.dart';
import 'package:sixvalley_vendor_app/localization/language_constrants.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';

class AddProductTabView extends StatefulWidget {
  final Product? product;
  final AddProductModel? addProduct;
  final EditProductModel? editProduct;
  final bool fromHome;
  const AddProductTabView({super.key, this.product, this.addProduct, this.editProduct, required this.fromHome});

  @override
  State<AddProductTabView> createState() => _AddProductTabViewState();
}

class _AddProductTabViewState extends State<AddProductTabView>  with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<AddProductScreenState> _firstTabKey = GlobalKey<AddProductScreenState>();
  final GlobalKey<AddProductNextScreenState> _secondTabKey = GlobalKey<AddProductNextScreenState>();

  ProductGeneralInfoData? productGeneralInfoData;
  ProductCombinedData? productCombinedData;
  bool _eligibilityChecked = false;
  bool _canAddNewProduct = true;
  String? _eligibilityReason;

  final List<Tab> productTabs = const <Tab>[
    Tab(text: 'General Info', icon: Icon(Icons.info_outline)),
    Tab(text: 'Variations', icon: Icon(Icons.color_lens_outlined)),
    Tab(text: 'SEO', icon: Icon(Icons.search)),
  ];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.product == null) {
      // Every new-product entry point reaches this screen, so the check cannot be bypassed from another menu.
      Future.microtask(_checkNewProductEligibility);
    } else {
      _eligibilityChecked = true;
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchDataFromFirstTab();
          _fetchDataFromSecondTab();
        });
      }
    });
  }


  void _fetchDataFromFirstTab() {
    ProductGeneralInfoData? latestData = _firstTabKey.currentState?.getCurrentFormData();
    setState(() {
      productGeneralInfoData = latestData;
    });
  }

  void _fetchDataFromSecondTab() {
    ProductCombinedData? data = _secondTabKey.currentState?.getCurrentFormData();
    setState(() {
      productCombinedData = data;
    });
  }

  void _navigateToTab(int index) {
    if(index ==1 ) {
      _fetchDataFromFirstTab();
    }

    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product == null && !_eligibilityChecked) {
      return Scaffold(
        appBar: CustomAppBarWidget(centerTitle: false, title: getTranslated('add_product', context)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.product == null && !_canAddNewProduct) {
      return Scaffold(
        appBar: CustomAppBarWidget(centerTitle: false, title: getTranslated('add_product', context)),
        body: _AddProductEligibilityBlocked(reason: _eligibilityReason ?? 'A seller package is required.'),
      );
    }

    return DefaultTabController(
      length: productTabs.length,
      child: Scaffold(
        appBar: CustomAppBarWidget(
          centerTitle: false,
          title: widget.product != null ? getTranslated('update_product', context) : getTranslated('add_product', context),
          widget: GeneratesLeftCount(),
          isFilter: true,
          isAction: true,
          onBackPressed: () {
            Navigator.of(context).pop();
          },
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              height: 60,
              child: AddProductTitleBar(tabController: _tabController),
            ),

            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  AddProductScreen(product: widget.product, addProduct: widget.addProduct, fromHome: widget.fromHome, onTabChanged: _navigateToTab, key: _firstTabKey),

                  AddProductNextScreen(
                    key: _secondTabKey,
                    categoryId: productGeneralInfoData?.categoryId,
                    subCategoryId:  productGeneralInfoData?.subCategoryId,
                    subSubCategoryId: productGeneralInfoData?.subSubCategoryId,
                    brandId: productGeneralInfoData?.brandId,
                    unit: productGeneralInfoData?.unit,
                    product: widget.product,
                    addProduct: productGeneralInfoData?.addProduct,
                    title: productGeneralInfoData?.title,
                    description: productGeneralInfoData?.description,
                    onTabChanged: _navigateToTab,
                  ),

                  AddProductSeoScreen(
                    unitPrice: productCombinedData?.unitPrice,
                    tax: productCombinedData?.tax,
                    unit: productCombinedData?.unit,
                    categoryId: productCombinedData?.categoryId,
                    subCategoryId: productCombinedData?.subCategoryId,
                    subSubCategoryId: productCombinedData?.subSubCategoryId,
                    brandyId: productCombinedData?.brandId,
                    discount: productCombinedData?.discount,
                    currentStock: productCombinedData?.currentStock,
                    minimumOrderQuantity: productCombinedData?.minimumOrderQuantity,
                    shippingCost: productCombinedData?.shippingCost,
                    product: widget.product,
                    addProduct: productCombinedData?.addProduct,
                    title: productCombinedData?.title,
                    description: productCombinedData?.description,
                    onTabChanged: _navigateToTab,
                  ),
                ],
              ),
            )

          ],
        ),




      ),
    );
  }

  Future<void> _checkNewProductEligibility() async {
    final packageController = Provider.of<SellerPackageController>(context, listen: false);
    await Future.wait([packageController.getOverview(), packageController.getInsuranceStatus()]);
    final overview = packageController.overview;
    if (!mounted) return;

    // A request failure is left to the protected product endpoint rather than falsely blocking a seller offline.
    if (overview == null) {
      setState(() => _eligibilityChecked = true);
      return;
    }

    final insuranceActive = packageController.insuranceOverview?.active ?? overview.subscription.insuranceSatisfied;
    final subscription = overview.subscription.active;
    String? reason;
    if (!insuranceActive) {
      reason = 'Activate your seller insurance before adding products.';
    } else if (subscription == null) {
      reason = 'Activate a seller package before adding products.';
    } else if (subscription.remainingProductLimit <= 0) {
      reason = 'Your package product limit has been reached.';
    }
    setState(() {
      _eligibilityReason = reason;
      _canAddNewProduct = reason == null;
      _eligibilityChecked = true;
    });
  }
}

class _AddProductEligibilityBlocked extends StatelessWidget {
  final String reason;

  const _AddProductEligibilityBlocked({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock_outline, size: 40, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(reason, textAlign: TextAlign.center),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SellerPackageScreen())),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('Open packages'),
          ),
        ]),
      ),
    );
  }
}
