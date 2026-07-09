import 'package:flutter/material.dart';

import '../../../app/ui/ui.dart';
import '../../auth/domain/business_category.dart';
import '../domain/owner_setup_models.dart';

class OwnerBusinessPicker extends StatelessWidget {
  const OwnerBusinessPicker({
    super.key,
    required this.businesses,
    required this.selectedBusiness,
    required this.onChanged,
    required this.onEdit,
  });

  final List<OwnerBusiness> businesses;
  final OwnerBusiness? selectedBusiness;
  final ValueChanged<OwnerBusiness?> onChanged;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader(title: 'Business'),
          const SizedBox(height: 12),
          SelectField<String>(
            label: 'Business',
            value: selectedBusiness?.id,
            options: businesses
                .map(
                  (business) => SelectFieldOption(
                    value: business.id,
                    label: business.name,
                  ),
                )
                .toList(),
            onChanged: (value) {
              onChanged(
                businesses
                    .where((business) => business.id == value)
                    .firstOrNull,
              );
            },
          ),
          const SizedBox(height: 12),
          SecondaryButton(
            label: 'Edit business',
            icon: Icons.edit_rounded,
            onPressed: selectedBusiness == null ? null : onEdit,
          ),
        ],
      ),
    );
  }
}

class OwnerBusinessSettingsDialog extends StatefulWidget {
  const OwnerBusinessSettingsDialog({
    super.key,
    required this.business,
    required this.errorMessage,
    this.onClearError,
    required this.isSaving,
    required this.onSave,
  });

  final OwnerBusiness business;
  final String? errorMessage;
  final VoidCallback? onClearError;
  final bool isSaving;
  final Future<bool> Function({
    required String name,
    required String? category,
    required String? publicEmail,
    required String? publicPhone,
    required String? websiteUrl,
    required String? addressLine1,
    required String? addressLine2,
    required String? city,
    required String? region,
    required String? postalCode,
    required String countryCode,
    required String timezone,
  })
  onSave;

  @override
  State<OwnerBusinessSettingsDialog> createState() =>
      _OwnerBusinessSettingsDialogState();
}

class _OwnerBusinessSettingsDialogState
    extends State<OwnerBusinessSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _publicEmailController;
  late final TextEditingController _publicPhoneController;
  late final TextEditingController _websiteController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryCodeController;
  late final TextEditingController _timezoneController;
  String? _category;

  @override
  void initState() {
    super.initState();
    final business = widget.business;
    _nameController = TextEditingController(text: business.name);
    _publicEmailController = TextEditingController(
      text: business.publicEmail ?? '',
    );
    _publicPhoneController = TextEditingController(
      text: business.publicPhone ?? '',
    );
    _websiteController = TextEditingController(text: business.websiteUrl ?? '');
    _addressLine1Controller = TextEditingController(
      text: business.addressLine1 ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: business.addressLine2 ?? '',
    );
    _cityController = TextEditingController(text: business.city ?? '');
    _regionController = TextEditingController(text: business.region ?? '');
    _postalCodeController = TextEditingController(
      text: business.postalCode ?? '',
    );
    _countryCodeController = TextEditingController(text: business.countryCode);
    _timezoneController = TextEditingController(text: business.timezone);
    _category = business.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _publicEmailController.dispose();
    _publicPhoneController.dispose();
    _websiteController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _countryCodeController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(
        title: 'Business Settings',
        variant: AppTopBarVariant.service,
      ),
      body: SafeArea(
        child: DashboardScroll(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.errorMessage != null) ...[
                InlineBanner(
                  message: widget.errorMessage!,
                  tone: BannerTone.error,
                  onClose: widget.onClearError,
                ),
                const SizedBox(height: 16),
              ],
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'Business profile'),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _nameController,
                            label: 'Business name',
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if ((value?.trim() ?? '').length < 2) {
                                return 'Business name is required.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SelectField<String>(
                            label: 'Category',
                            value: _category,
                            options: businessCategoryOptions
                                .map(
                                  (option) => SelectFieldOption(
                                    value: option.value,
                                    label: option.label,
                                  ),
                                )
                                .toList(),
                            onChanged: widget.isSaving
                                ? null
                                : (value) => setState(() => _category = value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'Public contact'),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _publicEmailController,
                            label: 'Public email',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _publicPhoneController,
                            label: 'Public phone',
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _websiteController,
                            label: 'Website',
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'Address'),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _addressLine1Controller,
                            label: 'Address line 1',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _addressLine2Controller,
                            label: 'Address line 2',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _cityController,
                            label: 'City',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _regionController,
                            label: 'Region',
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _postalCodeController,
                            label: 'Postal code',
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SectionHeader(title: 'Advanced'),
                          const SizedBox(height: 12),
                          AppTextField(
                            controller: _countryCodeController,
                            label: 'Country code',
                            enabled: false,
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _timezoneController,
                            label: 'Timezone',
                            enabled: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Save business',
                      icon: Icons.check_rounded,
                      isLoading: widget.isSaving,
                      onPressed: widget.isSaving ? null : _save,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final navigator = Navigator.of(context);
    final saved = await widget.onSave(
      name: _nameController.text,
      category: _category,
      publicEmail: _publicEmailController.text,
      publicPhone: _publicPhoneController.text,
      websiteUrl: _websiteController.text,
      addressLine1: _addressLine1Controller.text,
      addressLine2: _addressLine2Controller.text,
      city: _cityController.text,
      region: _regionController.text,
      postalCode: _postalCodeController.text,
      countryCode: _countryCodeController.text,
      timezone: _timezoneController.text,
    );
    if (!mounted || !saved) {
      return;
    }
    navigator.pop();
  }
}
