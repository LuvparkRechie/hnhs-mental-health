import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/service/journal_service.dart';
import 'package:iconsax/iconsax.dart';
import '../../app_theme.dart';

class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  _DailyJournalScreenState createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  List<MotivationalQuote> _quotes = [];
  bool _isLoading = true;
  final String _selectedCategory = 'All';

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
      // Load real quotes from database
      final quotesResponse = await JournalService.getMotivationalQuotes();
      if (quotesResponse['success'] == true && quotesResponse['data'] is List) {
        setState(() {
          _quotes = (quotesResponse['data'] as List)
              .map((item) => MotivationalQuote.fromMap(item))
              .toList();
        });
      }
    } catch (e) {
      print('Error loading quotes: $e');
      // Show empty state if loading fails
      _quotes = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      appBar: AppBar(
        title: Text(
          'Daily Motivation',
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
            onPressed: _loadQuotes,
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                if (_quotes.isNotEmpty) _buildQuoteOfTheDay(),

                // Quotes List
                Expanded(child: _buildQuotesList(filteredQuotes)),
              ],
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
            'Loading inspirational quotes...',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteOfTheDay() {
    // Use the first quote as quote of the day
    final quoteOfTheDay = _quotes.first;

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryRed, AppTheme.secondaryRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryRed.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Quote of the Day',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(
                  quoteOfTheDay.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () {
                  _toggleFavorite(quoteOfTheDay.id);
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            '"${quoteOfTheDay.quote}"',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            '- ${quoteOfTheDay.author}',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              quoteOfTheDay.category,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotesList(List<MotivationalQuote> quotes) {
    return quotes.isEmpty
        ? _buildEmptyQuotesState()
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: quotes.length,
            itemBuilder: (context, index) {
              return _buildQuoteCard(quotes[index]);
            },
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

            // Author and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQuotesState() {
    return Center(
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
            'Check back later for new inspirational quotes',
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
          SizedBox(height: 20),
          IconButton(
            icon: Icon(Iconsax.refresh, color: AppTheme.primaryRed),
            onPressed: _loadQuotes,
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(String quoteId) {
    setState(() {
      final quote = _quotes.firstWhere((q) => q.id == quoteId);
      quote.isFavorite = !quote.isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _quotes.firstWhere((q) => q.id == quoteId).isFavorite
              ? 'Added to favorites'
              : 'Removed from favorites',
        ),
        backgroundColor: AppTheme.primaryRed,
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void _shareQuote(MotivationalQuote quote) {
    // This would typically use the share plugin
    // For now, show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Share Quote'),
        content: Text('This would open the share dialog with the quote.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
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
      isFavorite: false, // Default to false since we don't have favorites in DB
    );
  }
}
