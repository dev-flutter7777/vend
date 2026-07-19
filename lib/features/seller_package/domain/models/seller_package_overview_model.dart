class SellerPackageOverviewModel {
  final List<SellerPackagePlan> packages;
  final SellerPackageSummary subscription;
  final bool digitalPaymentAvailable;
  final List<SellerPaymentGateway> paymentGateways;
  final bool offlinePaymentAvailable;
  final List<SellerOfflinePaymentMethod> offlinePaymentMethods;

  SellerPackageOverviewModel({
    required this.packages, required this.subscription,
    required this.digitalPaymentAvailable, required this.paymentGateways,
    required this.offlinePaymentAvailable, required this.offlinePaymentMethods,
  });

  factory SellerPackageOverviewModel.fromJson(Map<String, dynamic> json) {
    final rawPackages = json['packages'] as List? ?? const [];

    // The API keeps package plans and the seller's current subscription separate.
    return SellerPackageOverviewModel(
      packages: rawPackages
          .whereType<Map>()
          .map((item) => SellerPackagePlan.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      subscription: SellerPackageSummary.fromJson(
        Map<String, dynamic>.from(json['subscription'] as Map? ?? const {}),
      ),
      digitalPaymentAvailable: _boolValue(json['digital_payment_available']),
      paymentGateways: (json['payment_gateways'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => SellerPaymentGateway.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      offlinePaymentAvailable: _boolValue(json['offline_payment_available']),
      offlinePaymentMethods: (json['offline_payment_methods'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => SellerOfflinePaymentMethod.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class SellerPaymentGateway {
  final String keyName;
  final String title;

  SellerPaymentGateway({required this.keyName, required this.title});

  factory SellerPaymentGateway.fromJson(Map<String, dynamic> json) => SellerPaymentGateway(
    keyName: json['key_name']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
  );
}

class SellerOfflinePaymentMethod {
  final int id;
  final String methodName;
  final List<SellerOfflineMethodField> methodFields;
  final List<SellerOfflineMethodField> methodInformations;

  SellerOfflinePaymentMethod({
    required this.id, required this.methodName, required this.methodFields,
    required this.methodInformations,
  });

  factory SellerOfflinePaymentMethod.fromJson(Map<String, dynamic> json) => SellerOfflinePaymentMethod(
    id: _intValue(json['id']),
    methodName: json['method_name']?.toString() ?? '',
    methodFields: _methodFields(json['method_fields']),
    methodInformations: _methodFields(json['method_informations']),
  );
}

class SellerOfflineMethodField {
  final String inputName;
  final String inputData;
  final String placeholder;
  final bool isRequired;

  SellerOfflineMethodField({
    required this.inputName, required this.inputData,
    required this.placeholder, required this.isRequired,
  });

  factory SellerOfflineMethodField.fromJson(Map<String, dynamic> json) => SellerOfflineMethodField(
    inputName: json['customer_input']?.toString() ?? json['input_name']?.toString() ?? '',
    inputData: json['input_data']?.toString() ?? '',
    placeholder: json['customer_placeholder']?.toString() ?? json['placeholder']?.toString() ?? '',
    isRequired: _boolValue(json['is_required']),
  );
}

class SellerPackagePlan {
  final int id;
  final String name;
  final String description;
  final double packagePrice;
  final int productLimit;
  final int productDurationDays;
  final int searchPromotionLimit;
  final int searchPromotionDurationDays;
  final int homepagePromotionLimit;
  final int homepagePromotionDurationDays;
  final int couponLimit;
  final int packageValidityDays;

  SellerPackagePlan({
    required this.id, required this.name, required this.description,
    required this.packagePrice, required this.productLimit,
    required this.productDurationDays, required this.searchPromotionLimit,
    required this.searchPromotionDurationDays, required this.homepagePromotionLimit,
    required this.homepagePromotionDurationDays, required this.couponLimit,
    required this.packageValidityDays,
  });

  factory SellerPackagePlan.fromJson(Map<String, dynamic> json) {
    return SellerPackagePlan(
      id: _intValue(json['id']), name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      packagePrice: _doubleValue(json['package_price']), productLimit: _intValue(json['product_limit']),
      productDurationDays: _intValue(json['product_duration_days']),
      searchPromotionLimit: _intValue(json['search_promotion_limit']),
      searchPromotionDurationDays: _intValue(json['search_promotion_duration_days']),
      homepagePromotionLimit: _intValue(json['homepage_promotion_limit']),
      homepagePromotionDurationDays: _intValue(json['homepage_promotion_duration_days']),
      couponLimit: _intValue(json['coupon_limit']), packageValidityDays: _intValue(json['package_validity_days']),
    );
  }
}

class SellerPackageSummary {
  final bool insuranceSatisfied;
  final bool canPurchase;
  final bool pendingReview;
  final SellerPackageSubscription? active;
  final SellerPackageSubscription? pending;

  SellerPackageSummary({
    required this.insuranceSatisfied, required this.canPurchase,
    required this.pendingReview, this.active, this.pending,
  });

  factory SellerPackageSummary.fromJson(Map<String, dynamic> json) {
    return SellerPackageSummary(
      insuranceSatisfied: _boolValue(json['insurance_satisfied']),
      canPurchase: _boolValue(json['can_purchase']),
      pendingReview: _boolValue(json['pending_review']),
      active: json['active'] is Map ? SellerPackageSubscription.fromJson(Map<String, dynamic>.from(json['active'] as Map)) : null,
      pending: json['pending'] is Map ? SellerPackageSubscription.fromJson(Map<String, dynamic>.from(json['pending'] as Map)) : null,
    );
  }
}

class SellerPackageSubscription {
  final int id;
  final String packageName;
  final double paidPackagePrice;
  final int remainingProductLimit;
  final int remainingSearchPromotionLimit;
  final int remainingHomepagePromotionLimit;
  final int remainingCouponLimit;
  final String status;
  final String paymentStatus;
  final String? expiresAt;

  SellerPackageSubscription({
    required this.id, required this.packageName, required this.paidPackagePrice,
    required this.remainingProductLimit, required this.remainingSearchPromotionLimit,
    required this.remainingHomepagePromotionLimit, required this.remainingCouponLimit,
    required this.status, required this.paymentStatus, this.expiresAt,
  });

  factory SellerPackageSubscription.fromJson(Map<String, dynamic> json) {
    return SellerPackageSubscription(
      id: _intValue(json['id']), packageName: json['package_name']?.toString() ?? '',
      paidPackagePrice: _doubleValue(json['paid_package_price']),
      remainingProductLimit: _intValue(json['remaining_product_limit']),
      remainingSearchPromotionLimit: _intValue(json['remaining_search_promotion_limit']),
      remainingHomepagePromotionLimit: _intValue(json['remaining_homepage_promotion_limit']),
      remainingCouponLimit: _intValue(json['remaining_coupon_limit']),
      status: json['status']?.toString() ?? '', paymentStatus: json['payment_status']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString(),
    );
  }
}

int _intValue(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _doubleValue(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
bool _boolValue(dynamic value) => value == true || value == 1 || value?.toString() == '1';

List<SellerOfflineMethodField> _methodFields(dynamic value) => (value as List? ?? const [])
    .whereType<Map>()
    .map((item) => SellerOfflineMethodField.fromJson(Map<String, dynamic>.from(item)))
    .toList();
