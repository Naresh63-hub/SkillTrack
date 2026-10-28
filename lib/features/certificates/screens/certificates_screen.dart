import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/search_filter_bar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/certificate.dart';
import '../../../repositories/certificates_repository.dart';
import 'add_edit_certificate_dialog.dart';
import 'certificate_viewer_screen.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  final CertificatesRepository _repository = CertificatesRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Certificate> _certificates = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCertificates() async {
    setState(() => _isLoading = true);
    final results = await _repository.getAllCertificates(
      category: _selectedCategory,
      searchQuery: _searchController.text,
    );
    setState(() {
      _certificates = results;
      _isLoading = false;
    });
  }

  Future<void> _addCertificate() async {
    final newCert = await showDialog<Certificate>(
      context: context,
      builder: (context) => const AddEditCertificateDialog(),
    );

    if (newCert != null) {
      await _repository.addCertificate(newCert);
      _loadCertificates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate added successfully')),
        );
      }
    }
  }

  Future<void> _editCertificate(Certificate certificate) async {
    final updated = await showDialog<Certificate>(
      context: context,
      builder: (context) => AddEditCertificateDialog(certificate: certificate),
    );

    if (updated != null) {
      await _repository.updateCertificate(updated);
      _loadCertificates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate updated successfully')),
        );
      }
    }
  }

  Future<void> _deleteCertificate(Certificate certificate) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete Certificate',
      content: 'Are you sure you want to delete "${certificate.name}"?',
    );

    if (confirmed) {
      await _repository.deleteCertificate(certificate.id!);
      _loadCertificates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificate deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certifications'),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brightAccent,
        foregroundColor: Colors.white,
        onPressed: _addCertificate,
        tooltip: 'Add Certificate',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchFilterBar(
              controller: _searchController,
              hintText: 'Search certificates or organizations...',
              onChanged: (_) => _loadCertificates(),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('All'),
                ...AppStrings.skillCategories.map((c) => _buildCategoryChip(c)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.brightAccent))
                : _certificates.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.workspace_premium_outlined,
                        title: _searchController.text.isNotEmpty ||
                                _selectedCategory != 'All'
                            ? 'No Matching Certificates'
                            : 'No Certifications Recorded',
                        description: _searchController.text.isNotEmpty ||
                                _selectedCategory != 'All'
                            ? 'Try different search keywords or category filters.'
                            : 'Upload and organize your AWS, Google, Coursera, and college credentials with verification links.',
                        actionLabel: 'Add Certificate',
                        onAction: _addCertificate,
                      )
                    : RefreshIndicator(
                        color: AppColors.brightAccent,
                        backgroundColor: AppColors.cardBackground,
                        onRefresh: _loadCertificates,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _certificates.length,
                          itemBuilder: (context, index) {
                            final cert = _certificates[index];
                            return _buildCertificateCard(cert);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        selected: isSelected,
        label: Text(category),
        selectedColor: AppColors.elevatedSurface,
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.brightAccent : AppColors.secondaryText,
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.brightAccent : AppColors.border,
          width: isSelected ? 1.2 : 0.8,
        ),
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
          _loadCertificates();
        },
      ),
    );
  }

  Widget _buildCertificateCard(Certificate cert) {
    return CustomCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CertificateViewerScreen(certificate: cert),
          ),
        );
      },
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.brightAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.brightAccent.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.verified,
                    color: AppColors.brightAccent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert.name,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      cert.issuingOrganization,
                      style: const TextStyle(
                        color: AppColors.secondaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.mutedText),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: AppColors.secondaryBackground,
                onSelected: (action) {
                  if (action == 'edit') {
                    _editCertificate(cert);
                  } else if (action == 'delete') {
                    _deleteCertificate(cert);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit,
                            size: 16, color: AppColors.secondaryText),
                        SizedBox(width: 8),
                        Text('Edit',
                            style: TextStyle(
                                color: AppColors.primaryText, fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Issued: ${DateFormatter.format(cert.completionDate)}',
                style:
                    const TextStyle(color: AppColors.mutedText, fontSize: 11),
              ),
              Row(
                children: [
                  if (cert.hasFile)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.attachment,
                              size: 12, color: AppColors.secondaryAccent),
                          SizedBox(width: 2),
                          Text('Doc',
                              style: TextStyle(
                                  color: AppColors.secondaryAccent,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  if (cert.hasVerificationUrl)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.link,
                              size: 12, color: AppColors.brightAccent),
                          SizedBox(width: 2),
                          Text('Link',
                              style: TextStyle(
                                  color: AppColors.brightAccent, fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
