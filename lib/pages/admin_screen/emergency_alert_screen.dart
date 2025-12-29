import 'package:auto_size_text_plus/auto_size_text_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hnhsmind_care/api_key/api_key.dart';
import 'package:hnhsmind_care/app_theme.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  List<dynamic> alerts = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await getAllAlertsToday();

      if (mounted) {
        if (response['success'] == true && response['data'] is List) {
          setState(() {
            alerts = response['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            alerts = [];
            isLoading = false;
            hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  Future<Map<String, dynamic>> getAllAlertsToday() async {
    try {
      final api = ApiPhp(tableName: 'admin_alerts');

      final Map<String, dynamic> joinConfig = {
        'join': 'LEFT JOIN users ON admin_alerts.user_id = users.id',
        'columns': '''
          admin_alerts.*,  
          users.mobile_no,
          users.username
        ''',
        'where': 'admin_alerts.is_settled = ?',
        'where_params': ['N'],
        'orderBy': 'admin_alerts.created_date DESC',
      };

      final response = await api.selectWithJoin(joinConfig);
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<void> launchSMS(String phoneNumber, String message) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{'body': message},
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      // Handle error, for example, show a dialog or snackbar
      throw 'Could not launch SMS';
    }
  }

  Future<void> settled(id) async {
    try {
      final api = ApiPhp(
        tableName: 'admin_alerts',
        parameters: {
          'is_settled': 'Y',
          'settled_on': DateTime.now().toString().split(".")[0],
        },
        whereClause: {'id': id},
      );

      final response = await api.update();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 1),
          content: Text(response["message"]),
          backgroundColor: response["success"] ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      _loadAlerts();
      return;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 1),
          content: Text("Error: $e"),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Emergency Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.dangerColor, Colors.red[800]!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.warning_2, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CRITICAL ALERTS',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Immediate attention required',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${alerts.length} alerts',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Loading State
            if (isLoading) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryRed),
                      SizedBox(height: 16),
                      Text(
                        'Loading emergency alerts...',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            // Error State
            else if (hasError) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.warning_2,
                        size: 64,
                        color: AppTheme.dangerColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load alerts',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            // Empty State
            else if (alerts.isEmpty) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.tick_circle,
                        size: 64,
                        color: AppTheme.accentColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No emergency alerts',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'All clear! No critical alerts at this time',
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ]
            // Alerts List
            else ...[
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAlerts,
                  color: AppTheme.primaryRed,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      return buildAlertCard(alerts[index]);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildAlertCard(Map<String, dynamic> alert) {
    final message = alert['user_message'] ?? 'No message';
    final username = alert['username'] ?? 'Unknown User';
    final mobileNo = alert['mobile_no'] ?? 'No contact';
    final createdDate = alert['created_date'] ?? DateTime.now().toString();
    final itemIdx = alert["id"];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [AppTheme.cardShadow],
        border: Border.all(color: AppTheme.dangerColor.withOpacity(0.3)),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with User Info and created_date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.dangerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.profile_circle,
                              size: 12,
                              color: AppTheme.dangerColor,
                            ),
                            SizedBox(width: 6),
                            Text(
                              username,
                              style: GoogleFonts.inter(
                                color: AppTheme.dangerColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (mobileNo != 'No contact') ...[
                        SizedBox(height: 4),
                        Text(
                          mobileNo,
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  formatcreated_date(createdDate),
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            // Alert Message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.lightRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.lightRed),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reported Message:',
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '"$message"',
                    style: GoogleFonts.inter(
                      color: AppTheme.dangerColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Priority Warning
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 16,
                    color: AppTheme.dangerColor,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This user needs immediate attention',
                      style: GoogleFonts.inter(
                        color: AppTheme.dangerColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => settled(itemIdx),
                    icon: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    label: Text('Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => launchSMS(mobileNo, ""),
                    icon: Icon(Iconsax.message, size: 16),
                    label: AutoSizeText(
                      'Send SMS',
                      maxLines: 1,
                      style: TextStyle(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatcreated_date(String createdDate) {
    try {
      final dateTime = DateTime.parse(createdDate);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      try {
        final dateTime = DateFormat('yyyy-MM-dd HH:mm:ss').parse(createdDate);
        return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
      } catch (e) {
        return createdDate;
      }
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.primaryRed),
    );
  }
}
