import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/service/journal_service.dart';
import 'package:iconsax/iconsax.dart';

import '../../app_theme.dart';
import 'create_qoute_screen.dart';

class AdminJournalScreen extends StatefulWidget {
  const AdminJournalScreen({super.key});

  @override
  State<AdminJournalScreen> createState() => _AdminJournalScreenState();
}

class _AdminJournalScreenState extends State<AdminJournalScreen> {
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  List<MotivationalQuote> _quotes = [];
  bool _isLoading = true;
  final String _selectedCategory = 'All';

  final bool _showCreateForm = false; // To toggle form visibility

  @override
  void initState() {
    super.initState();
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quotesResponse = await JournalService.getMotivationalQuotes();

      if (quotesResponse['success'] == true && quotesResponse['data'] is List) {
        setState(() {
          _quotes = (quotesResponse['data'] as List)
              .map((item) => MotivationalQuote.fromMap(item))
              .toList();
        });
      } else {
        _showError('Failed to load quotes: ${quotesResponse['message']}');
      }
    } catch (e) {
      _showError('Error loading quotes: $e');
      _quotes = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteQuote(String quoteId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Quote'),
        content: Text('Are you sure you want to delete this quote?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await JournalService.deleteMotivationalQuote(quoteId);
        if (response['success'] == true) {
          _showSuccess('Quote deleted successfully!');
          _loadQuotes();
        } else {
          _showError('Failed to delete quote: ${response['message']}');
        }
      } catch (e) {
        _showError('Error deleting quote: $e');
      }
    }
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

  void _toggleCreateForm() async {
    final returndata = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateQuoteScreen()),
    );

    if (returndata != null) {
      _loadQuotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredQuotes = _selectedCategory == 'All'
        ? _quotes
        : _quotes
              .where((quote) => quote.category == _selectedCategory)
              .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(toolbarHeight: 0, elevation: 0),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: _isLoading
              ? _buildLoadingState()
              : _buildQuotesList(filteredQuotes),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCreateForm,
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        child: Icon(_showCreateForm ? Iconsax.close_circle : Iconsax.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryRed),
          SizedBox(height: 16),
          Text(
            'Loading quotes...',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesList(List<MotivationalQuote> quotes) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(16),
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
                  Icon(
                    Iconsax.quote_down,
                    color: AppTheme.primaryRed,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: AutoSizeText(
                      'Manage Motivational Quotes',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textPrimary,

                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Create and manage inspirational quotes for users. Each quote will appear in the Daily Motivation section where users can find encouragement and inspiration throughout their day.',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: quotes.isEmpty
              ? _buildEmptyQuotesState()
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: quotes.length,
                  itemBuilder: (context, index) {
                    return _buildQuoteCard(quotes[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQuoteCard(MotivationalQuote quote) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote Text
            Text(
              '"${quote.quote}"',
              style: GoogleFonts.inter(
                color: AppTheme.textPrimary,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),

            // Author and Category
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '- ${quote.author}',
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.lightRed.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          quote.category,
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryRed,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Delete Button
                IconButton(
                  icon: Icon(
                    Iconsax.trash,
                    color: AppTheme.dangerColor,
                    size: 20,
                  ),
                  onPressed: () => _deleteQuote(quote.id),
                ),
              ],
            ),

            // Date
            Text(
              'Created: ${_formatDate(quote.date)}',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuotesState() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.quote_down, size: 80, color: AppTheme.lightRed),
          SizedBox(height: 16),
          Text(
            'No quotes found',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap the + button to create your first quote',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _authorController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}

class MotivationalQuote {
  final String id;
  final String quote;
  final String author;
  final String category;
  final DateTime date;
  bool isFavorite;

  MotivationalQuote({
    required this.id,
    required this.quote,
    required this.author,
    required this.category,
    required this.date,
    required this.isFavorite,
  });

  factory MotivationalQuote.fromMap(Map<String, dynamic> map) {
    return MotivationalQuote(
      id: map['id']?.toString() ?? '',
      quote: map['quote'] ?? '',
      author: map['author'] ?? 'Unknown',
      category: map['category'] ?? 'Inspiration',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      isFavorite: false,
    );
  }
}
