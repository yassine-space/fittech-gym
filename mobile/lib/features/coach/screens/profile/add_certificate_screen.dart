import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/providers/coach_provider.dart';

class AddCertificateScreen extends StatefulWidget {
  const AddCertificateScreen({super.key});

  @override
  State<AddCertificateScreen> createState() => _AddCertificateScreenState();
}

class _AddCertificateScreenState extends State<AddCertificateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _orgController = TextEditingController();
  
  DateTime? _selectedDate;
  
  // ✅ FIX 1: Use PlatformFile instead of a String path
  PlatformFile? _selectedFile; 
  String? _selectedFileName;
  
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _orgController.dispose();
    super.dispose();
  }

  // ─── Pick File Logic ──────────────────────────────────────────────────
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true, // ✅ FIX 2: Crucial for Flutter Web to load file bytes into memory
    );

    // ✅ FIX 3: Check if result is not null, ignore path checks
    if (result != null) {
      setState(() {
        _selectedFile = result.files.single; // Store the whole PlatformFile object
        _selectedFileName = result.files.single.name;
      });
    }
  }

  // ─── Pick Date Logic ──────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD44820), 
              onPrimary: Colors.white, 
              onSurface: Color(0xFF1C1C1C), 
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ─── Upload Logic ─────────────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue date.')),
      );
      return;
    }

    // ✅ FIX 4: Check if _selectedFile is null instead of _selectedFilePath
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a certificate file (PDF/Image).')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final provider = context.read<CoachProvider>();
      
      // ✅ FIX 5: Pass the whole PlatformFile object to the provider
      await provider.uploadCertificate(
        title: _titleController.text.trim(),
        issuingOrganization: _orgController.text.trim(),
        issueDate: _selectedDate!,
        file: _selectedFile!, // Updated parameter name here
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificate added successfully!'), backgroundColor: Color(0xFF3DB87A)),
      );
      Navigator.pop(context); 
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'ADD CERTIFICATE',
          style: TextStyle(color: Color(0xFF1C1C1C), fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD44820)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Certificate Title'),
                    TextFormField(
                      controller: _titleController,
                      decoration: _inputDecoration('e.g. Certified Personal Trainer'),
                      validator: (v) => v!.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Issuing Organization'),
                    TextFormField(
                      controller: _orgController,
                      decoration: _inputDecoration('e.g. NASM, ACE, ISSA'),
                      validator: (v) => v!.isEmpty ? 'Organization is required' : null,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Issue Date'),
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Color(0xFFD44820), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate == null 
                                ? 'Select Date' 
                                : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                              style: TextStyle(
                                color: _selectedDate == null ? Colors.grey : const Color(0xFF1C1C1C), 
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // File Picker (PDF/Image)
                    _buildLabel('Attach File (PDF or Image)'),
                    InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          // ✅ FIX 6: Updated UI checks to use _selectedFile
                          color: _selectedFile != null ? const Color(0xFF3DB87A).withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedFile != null ? const Color(0xFF3DB87A) : const Color(0xFFD44820), 
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _selectedFile != null ? Icons.check_circle : Icons.upload_file, 
                              color: _selectedFile != null ? const Color(0xFF3DB87A) : const Color(0xFFD44820), 
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _selectedFileName ?? 'Tap to select document',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: _selectedFile != null ? const Color(0xFF3DB87A) : const Color(0xFF1C1C1C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD44820),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('UPLOAD CERTIFICATE', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        text, 
        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9A7060), fontSize: 13),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}