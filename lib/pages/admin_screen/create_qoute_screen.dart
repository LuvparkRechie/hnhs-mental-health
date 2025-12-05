import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hnhsmind_care/service/journal_service.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../provider/auth_provider.dart';

class CreateQuoteScreen extends StatefulWidget {
  const CreateQuoteScreen({super.key});

  @override
  State<CreateQuoteScreen> createState() => _CreateQuoteScreenState();
}

class _CreateQuoteScreenState extends State<CreateQuoteScreen> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _isCreating = false;
  final List<String> _categories = [
    'Motivation',
    'Inspiration',
    'Hope',
    'Strength',
    'Life',
    'Success',
    'Positivity',
    'Mindfulness',
    'Growth',
    'Courage',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create New Quote',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Iconsax.refresh, color: AppTheme.primaryRed),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Header Section
            _buildHeaderSection(),
            SizedBox(height: 24),

            // Create Form
            _buildCreateForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withOpacity(0.1),
            AppTheme.lightRed.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(Iconsax.quote_down, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Share Inspiration',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Create a motivational quote that will inspire and uplift users. Your words can make a positive impact on someone\'s day.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quote Details',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 20),

          // Quote Input
          TextField(
            controller: _quoteController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Quote Text *',
              labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              hintText: 'Enter your inspirational quote here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightRed),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryRed),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          SizedBox(height: 16),

          // Author Input
          TextField(
            controller: _authorController,
            decoration: InputDecoration(
              labelText: 'Author *',
              labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              hintText: 'Who said this quote?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightRed),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryRed),
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          ),
          SizedBox(height: 16),

          // Category Dropdown
          DropdownButtonFormField<String>(
            initialValue: _categoryController.text.isEmpty
                ? 'Inspiration'
                : _categoryController.text,
            decoration: InputDecoration(
              labelText: 'Category *',
              labelStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.lightRed),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.primaryRed),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _categoryController.text = newValue!;
              });
            },
          ),
          SizedBox(height: 24),

          // Preview Section
          if (_quoteController.text.isNotEmpty) _buildPreviewSection(),
          if (_quoteController.text.isNotEmpty) SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearForm,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: AppTheme.primaryRed),
                  ),
                  child: Text(
                    'Clear',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _createQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isCreating
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Create Quote',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.lightRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '"${_quoteController.text}"',
            style: GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '- ${_authorController.text.isNotEmpty ? _authorController.text : "Author"}',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.lightRed.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _categoryController.text.isNotEmpty
                  ? _categoryController.text
                  : 'Category',
              style: GoogleFonts.inter(
                color: AppTheme.primaryRed,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createQuote() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userData = await authProvider.getAuthData();

    if (_quoteController.text.isEmpty) {
      _showError('Please enter a quote');
      return;
    }

    if (_authorController.text.isEmpty) {
      _showError('Please enter an author');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final newQuote = {
        'quote': _quoteController.text,
        'author': _authorController.text,
        'category': _categoryController.text.isNotEmpty
            ? _categoryController.text
            : 'Inspiration',
        'date': DateTime.now().toIso8601String(),
        'user_id': userData["id"],
      };

      final response = await JournalService.createMotivationalQuote(newQuote);
      print("📥 Create Quote Response: $response");

      if (response['success'] == true) {
        _showSuccess('Quote created successfully!');
        _clearForm();

        await Future.delayed(Duration(milliseconds: 1500));
        Navigator.pop(context, true); // Return success to previous screen
      } else {
        _showError('Failed to create quote: ${response['message']}');
      }
    } catch (e) {
      _showError('Error creating quote: $e');
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  void _clearForm() {
    setState(() {
      _quoteController.clear();
      _authorController.clear();
      _categoryController.text = 'Inspiration';
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.dangerColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }
}
