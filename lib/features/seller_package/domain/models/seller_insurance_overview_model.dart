import 'package:sixvalley_vendor_app/features/seller_package/domain/models/seller_package_overview_model.dart';

class SellerInsuranceOverviewModel {
  final bool enabled;
  final double configuredAmount;
  final bool required;
  final bool active;
  final bool pendingReview;
  final bool canPay;
  final SellerInsuranceRecord? latest;
  final bool digitalPaymentAvailable;
  final List<SellerPaymentGateway> paymentGateways;
  final bool offlinePaymentAvailable;
  final List<SellerOfflinePaymentMethod> offlinePaymentMethods;

  SellerInsuranceOverviewModel({
    required this.enabled, required this.configuredAmount, required this.required,
    required this.active, required this.pendingReview, required this.canPay,
    required this.latest, required this.digitalPaymentAvailable, required this.paymentGateways,
    required this.offlinePaymentAvailable, required this.offlinePaymentMethods,
  });

  factory SellerInsuranceOverviewModel.fromJson(Map<String, dynamic> json) {
    final insurance = Map<String, dynamic>.from(json['insurance'] as Map? ?? const {});
    return SellerInsuranceOverviewModel(
      enabled: _insuranceBool(insurance['enabled']),
      configuredAmount: _insuranceDouble(insurance['configured_amount']),
      required: _insuranceBool(insurance['required']),
      active: _insuranceBool(insurance['active']),
      pendingReview: _insuranceBool(insurance['pending_review']),
      canPay: _insuranceBool(insurance['can_pay']),
      latest: insurance['latest'] is Map
          ? SellerInsuranceRecord.fromJson(Map<String, dynamic>.from(insurance['latest'] as Map)) : null,
      digitalPaymentAvailable: _insuranceBool(json['digital_payment_available']),
      paymentGateways: (json['payment_gateways'] as List? ?? const [])
          .whereType<Map>().map((item) => SellerPaymentGateway.fromJson(Map<String, dynamic>.from(item))).toList(),
      offlinePaymentAvailable: _insuranceBool(json['offline_payment_available']),
      offlinePaymentMethods: (json['offline_payment_methods'] as List? ?? const [])
          .whereType<Map>().map((item) => SellerOfflinePaymentMethod.fromJson(Map<String, dynamic>.from(item))).toList(),
    );
  }
}

class SellerInsuranceRecord {
  final int id;
  final double amount;
  final String status;
  final String paymentStatus;

  SellerInsuranceRecord({required this.id, required this.amount, required this.status, required this.paymentStatus});

  factory SellerInsuranceRecord.fromJson(Map<String, dynamic> json) => SellerInsuranceRecord(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    amount: _insuranceDouble(json['amount']),
    status: json['status']?.toString() ?? '',
    paymentStatus: json['payment_status']?.toString() ?? '',
  );
}

bool _insuranceBool(dynamic value) => value == true || value == 1 || value?.toString() == '1';
double _insuranceDouble(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
