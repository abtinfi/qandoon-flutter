// updated_add_pastry_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

class AddPastryScreen extends StatefulWidget {
  const AddPastryScreen({super.key});

  @override
  State<AddPastryScreen> createState() => _AddPastryScreenState();
}

class _AddPastryScreenState extends State<AddPastryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  File? _imageFile;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select an image.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('Authentication token not found');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.abtinfi.ir/pastries/'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['stock'] = _stockController.text;

      final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          _imageFile!.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pastry added successfully.')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to add pastry: $body');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Pastry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  image: _imageFile != null
                      ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _imageFile == null
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_outlined, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to choose an image'),
                    ],
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _nameController,
              label: 'Pastry Name',
              icon: Icons.cake_outlined,
              validatorMessage: 'Please enter the name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description_outlined,
              maxLines: 3,
              validatorMessage: 'Please enter a description',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _priceController,
              label: 'Price (Toman)',
              icon: Icons.attach_money,
              inputType: TextInputType.number,
              validatorMessage: 'Enter a valid price',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _stockController,
              label: 'Stock',
              icon: Icons.inventory_2_outlined,
              inputType: TextInputType.number,
              validatorMessage: 'Enter a valid stock number',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitForm,
                icon: const Icon(Icons.add),
                label: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Add Pastry'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    required String validatorMessage,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return validatorMessage;
        if (inputType == TextInputType.number && double.tryParse(value) == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    );
  }
}
