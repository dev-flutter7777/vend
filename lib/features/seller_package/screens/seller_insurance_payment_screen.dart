import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_app_bar_widget.dart';
import 'package:sixvalley_vendor_app/common/basewidgets/custom_snackbar_widget.dart';
import 'package:sixvalley_vendor_app/features/seller_package/controllers/seller_package_controller.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/models/seller_insurance_overview_model.dart';
import 'package:sixvalley_vendor_app/features/seller_package/domain/models/seller_package_overview_model.dart';
import 'package:sixvalley_vendor_app/utill/dimensions.dart';
import 'package:sixvalley_vendor_app/utill/styles.dart';
import 'package:url_launcher/url_launcher.dart';

class SellerInsurancePaymentScreen extends StatelessWidget {
  final SellerInsuranceOverviewModel overview;

  const SellerInsurancePaymentScreen({super.key, required this.overview});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarWidget(title: 'Insurance payment'),
      body: ListView(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), children: [
        _InsuranceAmountCard(amount: overview.configuredAmount),
        if (overview.digitalPaymentAvailable && overview.paymentGateways.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text('Pay online', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ...overview.paymentGateways.map((gateway) => _InsurancePaymentTile(
            title: gateway.title, icon: Icons.credit_card_outlined,
            onTap: () => _startDigitalPayment(context, gateway),
          )),
        ],
        if (overview.offlinePaymentAvailable && overview.offlinePaymentMethods.isNotEmpty) ...[
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text('Manual transfer', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ...overview.offlinePaymentMethods.map((method) => _InsurancePaymentTile(
            title: method.methodName, icon: Icons.account_balance_outlined,
            subtitle: 'Submit proof for admin review',
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => SellerInsuranceOfflinePaymentScreen(method: method, amount: overview.configuredAmount),
            )),
          )),
        ],
        if ((!overview.digitalPaymentAvailable || overview.paymentGateways.isEmpty) &&
            (!overview.offlinePaymentAvailable || overview.offlinePaymentMethods.isEmpty))
          const Padding(
            padding: EdgeInsets.only(top: Dimensions.paddingSizeLarge),
            child: Center(child: Text('No payment method is currently available.')),
          ),
      ]),
    );
  }

  Future<void> _startDigitalPayment(BuildContext context, SellerPaymentGateway gateway) async {
    final controller = Provider.of<SellerPackageController>(context, listen: false);
    final redirectLink = await controller.payInsurance(paymentMethod: gateway.keyName);
    if (redirectLink == null || redirectLink.isEmpty) return;

    // Only the backend creates an insurance payment request; the app opens its returned secure URL.
    final launched = await launchUrl(Uri.parse(redirectLink), mode: LaunchMode.externalApplication);
    if (launched) await controller.getInsuranceStatus();
    if (!launched && context.mounted) {
      showCustomSnackBarWidget('Could not open the payment page.', context, sanckBarType: SnackBarType.error);
    }
  }
}

class SellerInsuranceOfflinePaymentScreen extends StatefulWidget {
  final SellerOfflinePaymentMethod method;
  final double amount;

  const SellerInsuranceOfflinePaymentScreen({super.key, required this.method, required this.amount});

  @override
  State<SellerInsuranceOfflinePaymentScreen> createState() => _SellerInsuranceOfflinePaymentScreenState();
}

class _SellerInsuranceOfflinePaymentScreenState extends State<SellerInsuranceOfflinePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final Map<String, TextEditingController> _informationControllers = {};
  XFile? _paymentProof;

  List<SellerOfflineMethodField> get _textFields => widget.method.methodInformations
      .where((field) => field.inputName.isNotEmpty && !_isProofField(field)).toList();

  @override
  void initState() {
    super.initState();
    for (final field in _textFields) {
      _informationControllers[field.inputName] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final controller in _informationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBarWidget(title: 'Manual insurance transfer'),
      body: SafeArea(child: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(Dimensions.paddingSizeDefault), children: [
          _InsuranceAmountCard(amount: widget.amount),
          if (widget.method.methodFields.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Text('Transfer details', style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            ...widget.method.methodFields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraSmall),
              child: Text('${_title(field)}: ${field.inputData}', style: titilliumRegular),
            )),
          ],
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ..._textFields.map((field) => Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
            child: TextFormField(
              controller: _informationControllers[field.inputName],
              decoration: InputDecoration(
                labelText: '${_title(field)}${field.isRequired ? ' *' : ''}',
                hintText: field.placeholder, border: const OutlineInputBorder(),
              ),
              validator: (value) => field.isRequired && (value == null || value.trim().isEmpty)
                  ? 'This field is required.' : null,
            ),
          )),
          OutlinedButton.icon(
            onPressed: _pickProof, icon: const Icon(Icons.upload_file_outlined),
            label: Text(_paymentProof == null ? 'Upload payment screenshot *' : _paymentProof!.name),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          TextFormField(
            controller: _noteController, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Payment note', border: OutlineInputBorder()),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Consumer<SellerPackageController>(builder: (context, controller, _) => SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: controller.isSubmittingPayment ? null : _submit,
              icon: controller.isSubmittingPayment
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(controller.isSubmittingPayment ? 'Submitting...' : 'Submit for review'),
            ),
          )),
        ]),
      )),
    );
  }

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked != null && mounted) {
      // The proof is always sent as the server's payment_proof multipart field.
      setState(() => _paymentProof = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paymentProof == null) {
      showCustomSnackBarWidget('A payment screenshot is required.', context, sanckBarType: SnackBarType.error);
      return;
    }
    final submitted = await Provider.of<SellerPackageController>(context, listen: false).submitOfflineInsurancePayment(
      methodId: widget.method.id,
      methodInformations: {for (final entry in _informationControllers.entries) entry.key: entry.value.text.trim()},
      paymentProof: _paymentProof!, paymentNote: _noteController.text.trim(),
    );
    if (submitted && mounted) {
      showCustomSnackBarWidget('Insurance payment submitted and waiting for admin review.', context, isError: false);
      Navigator.pop(context);
    }
  }

  bool _isProofField(SellerOfflineMethodField field) {
    final value = '${field.inputName} ${field.placeholder}'.toLowerCase();
    return value.contains('screenshot') || value.contains('image') || value.contains('receipt') || value.contains('proof');
  }

  String _title(SellerOfflineMethodField field) => field.inputName.replaceAll('_', ' ').trim();
}

class _InsuranceAmountCard extends StatelessWidget {
  final double amount;

  const _InsuranceAmountCard({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: .25)),
      ),
      child: Row(children: [
        const Icon(Icons.shield_outlined),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(child: Text('Seller insurance', style: titilliumSemiBold)),
        Text(amount.toStringAsFixed(2), style: titilliumSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
      ]),
    );
  }
}

class _InsurancePaymentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _InsurancePaymentTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).hintColor.withValues(alpha: .25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon), title: Text(title, style: titilliumSemiBold),
        subtitle: subtitle == null ? null : Text(subtitle!, style: titilliumRegular),
        trailing: const Icon(Icons.chevron_right), onTap: onTap,
      ),
    );
  }
}
