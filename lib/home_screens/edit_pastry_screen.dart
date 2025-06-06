// updated_edit_pastry_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';

import '../models/pastry_model.dart';

class EditPastryScreen extends StatefulWidget {
  final Pastry pastry;

  const EditPastryScreen({super.key, required this.pastry});

  @override
  State<EditPastryScreen> createState() => _EditPastryScreenState();
}

class _EditPastryScreenState extends State<EditPastryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  File? _imageFile;
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.pastry.name);
    _descriptionController = TextEditingController(text: widget.pastry.description);
    _priceController = TextEditingController(text: widget.pastry.price.toString());
    _stockController = TextEditingController(text: widget.pastry.stock.toString());
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) throw Exception('Authentication token not found');

      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('https://api.abtinfi.ir/pastries/${widget.pastry.id}'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['stock'] = _stockController.text;

      if (_imageFile != null) {
        final mimeType = lookupMimeType(_imageFile!.path) ?? 'image/jpeg';
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            _imageFile!.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pastry updated successfully.')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Update failed: $body');
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
    final showImage = _imageFile != null
        ? FileImage(_imageFile!)
        : NetworkImage(widget.pastry.imageUrl) as ImageProvider;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pastry')),
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
                  image: DecorationImage(image: showImage, fit: BoxFit.cover),
                ),
                child: _imageFile == null
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tap to change image'),
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
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Save Changes'),
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
