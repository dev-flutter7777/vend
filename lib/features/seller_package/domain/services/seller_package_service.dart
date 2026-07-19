import 'package:sixvalley_vendor_app/data/model/response/base/api_response.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/repositories/seller_package_repository_interface.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/services/seller_package_service_interface.dart';
import 'package:image_picker/image_picker.dart';

class SellerPackageService implements SellerPackageServiceInterface {
  final SellerPackageRepositoryInterface sellerPackageRepositoryInterface;

  SellerPackageService({required this.sellerPackageRepositoryInterface});

  @override
  Future<ApiResponse> getOverview() => sellerPackageRepositoryInterface.getOverview();

  @override
  Future<ApiResponse> getInsuranceStatus() => sellerPackageRepositoryInterface.getInsuranceStatus();

  @override
  Future<ApiResponse> payPackage({required int packageId, required String paymentMethod}) {
    return sellerPackageRepositoryInterface.payPackage(packageId: packageId, paymentMethod: paymentMethod);
  }

  @override
  Future<ApiResponse> payInsurance({required String paymentMethod}) {
    return sellerPackageRepositoryInterface.payInsurance(paymentMethod: paymentMethod);
  }

  @override
  Future<ApiResponse> submitOfflinePayment({
    required int packageId, required int methodId, required Map<String, String> methodInformations,
    required XFile paymentProof, String? paymentNote,
  }) {
    return sellerPackageRepositoryInterface.submitOfflinePayment(
      packageId: packageId, methodId: methodId, methodInformations: methodInformations,
      paymentProof: paymentProof, paymentNote: paymentNote,
    );
  }

  @override
  Future<ApiResponse> submitOfflineInsurancePayment({
    required int methodId, required Map<String, String> methodInformations,
    required XFile paymentProof, String? paymentNote,
  }) {
    return sellerPackageRepositoryInterface.submitOfflineInsurancePayment(
      methodId: methodId, methodInformations: methodInformations,
      paymentProof: paymentProof, paymentNote: paymentNote,
    );
  }
}
