import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/file_utils.dart';
import '../../../models/certificate.dart';

class AddEditCertificateDialog extends StatefulWidget {
  final Certificate? certificate;

  const AddEditCertificateDialog({super.key, this.certificate});

  @override
  State<AddEditCertificateDialog> createState() =>
      _AddEditCertificateDialogState();
}

class _AddEditCertificateDialogState extends State<AddEditCertificateDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _orgController;
  late TextEditingController _credIdController;
  late TextEditingController _urlController;
  late TextEditingController _descController;
  late String _category;
  DateTime _completionDate = DateTime.now();
  DateTime? _expirationDate;
  String? _localFilePath;
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    final c = widget.certificate;
    _nameController = TextEditingController(text: c?.name ?? '');
    _orgController = TextEditingController(text: c?.issuingOrganization ?? '');
    _credIdController = TextEditingController(text: c?.credentialId ?? '');
    _urlController = TextEditingController(text: c?.verificationUrl ?? '');
    _descController = TextEditingController(text: c?.description ?? '');
    _category = c?.category ?? AppStrings.skillCategories.first;
    _localFilePath = c?.localFilePath;

    if (c?.completionDate != null && c!.completionDate.isNotEmpty) {
      try {
        _completionDate = DateTime.parse(c.completionDate);
      } catch (_) {}
    }
    if (c?.expirationDate != null && c!.expirationDate!.isNotEmpty) {
      try {
        _expirationDate = DateTime.parse(c.expirationDate!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _orgController.dispose();
    _credIdController.dispose();
    _urlController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificateFile() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (result != null && result.files.single.path != null) {
        final originalPath = result.files.single.path!;
        // Copy to persistent storage
        final persistentPath =
            await FileUtils.copyFileToAppStorage(originalPath);
        setState(() {
          _localFilePath = persistentPath ?? originalPath;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick file')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.certificate != null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Certificate' : 'Add Certificate',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.mutedText),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Certificate Name
                TextFormField(
                  controller: _nameController,
                  validator: (v) =>
                      Validators.requiredField(v, 'Certificate name'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Certificate Title *',
                    hintText: 'e.g. AWS Certified Cloud Practitioner',
                    prefixIcon:
                        Icon(Icons.badge, size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Issuing Organization
                TextFormField(
                  controller: _orgController,
                  validator: (v) =>
                      Validators.requiredField(v, 'Issuing organization'),
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Issuing Organization *',
                    hintText: 'e.g. Amazon Web Services, Google, Coursera',
                    prefixIcon: Icon(Icons.business,
                        size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Category
                DropdownButtonFormField<String>(
                  value: _category,
                  dropdownColor: AppColors.secondaryBackground,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Domain / Category *',
                    prefixIcon: Icon(Icons.category,
                        size: 20, color: AppColors.mutedText),
                  ),
                  items: AppStrings.skillCategories.map((cat) {
                    return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, overflow: TextOverflow.ellipsis));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _category = v);
                  },
                ),
                const SizedBox(height: 12),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 15),
                        label: Text(
                          'Issued: ${_completionDate.day}/${_completionDate.month}/${_completionDate.year}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _completionDate,
                            firstDate: DateTime(2015),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null)
                            setState(() => _completionDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.event_busy, size: 15),
                        label: Text(
                          _expirationDate == null
                              ? 'No Expiration'
                              : 'Expires: ${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _expirationDate ??
                                DateTime.now()
                                    .add(const Duration(days: 365 * 3)),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040),
                          );
                          if (picked != null)
                            setState(() => _expirationDate = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Credential ID
                TextFormField(
                  controller: _credIdController,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Credential ID (Optional)',
                    hintText: 'e.g. AWS-CCP-9482914',
                    prefixIcon: Icon(Icons.fingerprint,
                        size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // Verification URL
                TextFormField(
                  controller: _urlController,
                  validator: Validators.optionalUrl,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Verification URL (Optional)',
                    hintText: 'https://verify.certificate.com/id',
                    prefixIcon: Icon(Icons.verified,
                        size: 20, color: AppColors.mutedText),
                  ),
                ),
                const SizedBox(height: 12),

                // File Attachment (PDF / Image)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _localFilePath != null
                            ? Icons.attach_file
                            : Icons.upload_file,
                        color: _localFilePath != null
                            ? AppColors.brightAccent
                            : AppColors.mutedText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _localFilePath != null
                              ? 'File attached (${_localFilePath!.split(RegExp(r'[/\\]')).last})'
                              : 'No document attached (PDF or Image)',
                          style: TextStyle(
                            color: _localFilePath != null
                                ? AppColors.primaryText
                                : AppColors.mutedText,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _isPickingFile ? null : _pickCertificateFile,
                        child: Text(
                            _localFilePath != null ? 'Change' : 'Pick File'),
                      ),
                      if (_localFilePath != null)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: AppColors.error),
                          onPressed: () =>
                              setState(() => _localFilePath = null),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(
                      color: AppColors.primaryText, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Description / Topics Covered',
                    hintText: 'Summary of concepts evaluated...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _saveCertificate,
                      child:
                          Text(isEditing ? 'Save Changes' : 'Save Certificate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveCertificate() {
    if (!_formKey.currentState!.validate()) return;

    final cert = Certificate(
      id: widget.certificate?.id,
      name: _nameController.text.trim(),
      issuingOrganization: _orgController.text.trim(),
      category: _category,
      completionDate: _completionDate.toIso8601String().split('T').first,
      expirationDate: _expirationDate?.toIso8601String().split('T').first,
      credentialId: _credIdController.text.trim().isEmpty
          ? null
          : _credIdController.text.trim(),
      verificationUrl: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      localFilePath: _localFilePath,
      createdAt: widget.certificate?.createdAt,
    );

    Navigator.of(context).pop(cert);
  }
}
