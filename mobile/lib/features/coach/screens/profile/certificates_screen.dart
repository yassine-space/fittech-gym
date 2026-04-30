import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart'; // Added File Picker
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/certificate_model.dart';

class CertificatesScreen extends StatefulWidget {
  const CertificatesScreen({super.key});

  @override
  State<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends State<CertificatesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().loadCertificates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final certs = provider.certificates;

        return Scaffold(
          backgroundColor: const Color(0xFFF5EDE8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1C)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'MY CERTIFICATES',
              style: TextStyle(
                color: Color(0xFF1C1C1C),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD44820)),
                onPressed: () => _showAddSheet(context, provider),
              ),
            ],
          ),
          body: provider.certificatesLoading && certs.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD44820)))
              : RefreshIndicator(
                  color: const Color(0xFFD44820),
                  onRefresh: () => provider.loadCertificates(),
                  child: certs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.workspace_premium_outlined,
                                size: 56,
                                color: const Color(0xFFD44820).withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No certificates yet',
                                style: TextStyle(
                                  color: Color(0xFF9A7060),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => _showAddSheet(context, provider),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Certificate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD44820),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: certs.length,
                          itemBuilder: (_, i) => _CertificateTile(
                            cert: certs[i],
                            onDelete: () => _confirmDelete(context, provider, certs[i]),
                          ),
                        ),
                ),
        );
      },
    );
  }

  void _showAddSheet(BuildContext context, CoachProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddCertificateSheet(
        onAdded: () {
          Navigator.pop(context);
          provider.loadCertificates();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Certificate added successfully!'),
              backgroundColor: Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CoachProvider provider,
    CoachCertificate cert,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Certificate',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${cert.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9A7060))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await provider.deleteCertificate(cert.id);
  }
}

class _CertificateTile extends StatelessWidget {
  final CoachCertificate cert;
  final VoidCallback onDelete;
  const _CertificateTile({required this.cert, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM yyyy').format(cert.issueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD44820).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFD44820),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cert.issuingOrganization,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9A7060),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 11, color: Color(0xFF9A7060)),
                    const SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF9A7060)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C), size: 20),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The Bottom Sheet for Adding Certificates
// ─────────────────────────────────────────────────────────────────────────────
class _AddCertificateSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddCertificateSheet({required this.onAdded});

  @override
  State<_AddCertificateSheet> createState() => _AddCertificateSheetState();
}

class _AddCertificateSheetState extends State<_AddCertificateSheet> {
  final _titleCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  DateTime _issueDate = DateTime.now();
  
  // File Picker variables
  String? _selectedFilePath;
  String? _selectedFileName;
  
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _issueDate,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFFD44820)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _issueDate = picked);
  }

  // Method to pick the file
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final org = _orgCtrl.text.trim();
    
    // Validate text fields AND the file
    if (title.isEmpty || org.isEmpty || _selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and attach a file.'),
          backgroundColor: Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    setState(() => _submitting = true);
    try {
      // Calls the real upload method from the CoachProvider
      await context.read<CoachProvider>().uploadCertificate(
        title: title,
        issuingOrganization: org,
        issueDate: _issueDate,
        filePath: _selectedFilePath!, // Pass the file path
      );
      widget.onAdded();
    } catch (e) {
      setState(() => _submitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add certificate: $e'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    
    // We wrap the contents in a SingleChildScrollView so when the keyboard 
    // opens, the bottom sheet gracefully scrolls up.
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Add Certificate',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1C1C1C))),
            const SizedBox(height: 4),
            const Text('Enter your credential details',
                style: TextStyle(fontSize: 13, color: Color(0xFF9A7060))),
            const SizedBox(height: 20),

            // Title
            const Text('Certificate Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C))),
            const SizedBox(height: 6),
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Certified Personal Trainer',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.workspace_premium_outlined, color: Color(0xFFD44820), size: 18),
                filled: true,
                fillColor: const Color(0xFFF5EDE8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Organization
            const Text('Issuing Organization',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C))),
            const SizedBox(height: 6),
            TextField(
              controller: _orgCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. NASM, ACE, ISSA',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFFD44820), size: 18),
                filled: true,
                fillColor: const Color(0xFFF5EDE8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Date
            const Text('Issue Date',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C))),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFFD44820)),
                    const SizedBox(width: 10),
                    Text(
                      DateFormat('MMMM yyyy').format(_issueDate),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // File Picker (PDF/Image) Added here
            const Text('Attach File (PDF/Image)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1C))),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: _selectedFilePath != null ? const Color(0xFF3DB87A).withOpacity(0.1) : const Color(0xFFF5EDE8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _selectedFilePath != null ? const Color(0xFF3DB87A) : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedFilePath != null ? Icons.check_circle : Icons.upload_file,
                      color: _selectedFilePath != null ? const Color(0xFF3DB87A) : const Color(0xFFD44820),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedFileName ?? 'Tap to select document',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedFilePath != null ? FontWeight.w600 : FontWeight.normal,
                          color: _selectedFilePath != null ? const Color(0xFF3DB87A) : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD44820),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add Certificate',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}