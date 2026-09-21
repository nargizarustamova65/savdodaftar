import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_strings.dart';
import '../../core/network/api_error_text.dart';
import '../../core/network/api_exception.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/widgets.dart';
import 'data/customer_models.dart';
import 'state/customers_providers.dart';

/// TZ 9-bo'lim: mijoz qo'shish/tahrirlash formasi.
/// Muvaffaqiyatda `Navigator.pop(true)` qaytaradi.
class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  /// null — yangi mijoz, aks holda tahrirlash.
  final Customer? customer;

  @override
  ConsumerState<CustomerFormScreen> createState() =>
      _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _noteController;

  String? _nameError;
  String? _phoneError;
  bool _isBusy = false;

  bool get _isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final Customer? customer = widget.customer;
    _nameController = TextEditingController(text: customer?.name ?? '');
    _phoneController = TextEditingController(
      text: customer?.phone == null
          ? ''
          : Phone.formatNational(customer!.phone!),
    );
    _addressController = TextEditingController(text: customer?.address ?? '');
    _noteController = TextEditingController(text: customer?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppStrings s = context.s;
    final String name = _nameController.text.trim();
    final String phone = _phoneController.text.trim();

    setState(() {
      _nameError = name.isEmpty ? s.validationNameRequired : null;
      _phoneError = phone.isNotEmpty && !Phone.isValid(phone)
          ? s.validationPhoneInvalid
          : null;
    });
    if (_nameError != null || _phoneError != null) {
      return;
    }

    setState(() => _isBusy = true);

    try {
      final CustomersRepositoryHelper helper =
          CustomersRepositoryHelper(ref: ref);
      if (_isEdit) {
        await helper.update(
          widget.customer!.id,
          name: name,
          phone: phone,
          address: _addressController.text,
          note: _noteController.text,
        );
      } else {
        await helper.create(
          name: name,
          phone: phone,
          address: _addressController.text,
          note: _noteController.text,
        );
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorText(context.s, error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStrings s = context.s;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? s.customerEditTitle : s.customerAddTitle),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.screen),
                children: <Widget>[
                  AppTextField(
                    label: s.nameLabel,
                    hint: s.nameHint,
                    controller: _nameController,
                    errorText: _nameError,
                    autofocus: !_isEdit,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.person_outline_rounded,
                    onChanged: (String _) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.phoneOptionalLabel,
                    hint: s.phoneHint,
                    controller: _phoneController,
                    errorText: _phoneError,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: <TextInputFormatter>[
                      PhoneTextInputFormatter(),
                    ],
                    prefixIcon: Icons.phone_outlined,
                    onChanged: (String _) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.addressLabel,
                    hint: s.addressHint,
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: s.noteLabel,
                    hint: s.noteHint,
                    controller: _noteController,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.screen),
              child: AppButton(
                label: s.save,
                isLoading: _isBusy,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Repository chaqiruvlarini qisqartirish uchun kichik yordamchi.
class CustomersRepositoryHelper {
  CustomersRepositoryHelper({required WidgetRef ref})
      : _ref = ref;

  final WidgetRef _ref;

  Future<void> create({
    required String name,
    String? phone,
    String? address,
    String? note,
  }) {
    return _ref.read(customersRepositoryProvider).create(
          name: name,
          phone: phone,
          address: address,
          note: note,
        );
  }

  Future<void> update(
    int id, {
    required String name,
    String? phone,
    String? address,
    String? note,
  }) {
    return _ref.read(customersRepositoryProvider).update(
          id,
          name: name,
          phone: phone,
          address: address,
          note: note,
        );
  }
}
