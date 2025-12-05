import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:hnhsmind_care/app_theme.dart';
import 'package:provider/provider.dart';

import '../../api_key/api_key.dart';
import '../../provider/auth_provider.dart';

class UserProfileUpdateScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserProfileUpdateScreen({super.key, required this.userData});

  @override
  State<UserProfileUpdateScreen> createState() =>
      _UserProfileUpdateScreenState();
}

class _UserProfileUpdateScreenState extends State<UserProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _birthDateController;

  // Form values
  late String _selectedRole;
  DateTime? _selectedDate;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize form fields from user data
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.userData['email'] ?? '',
    );
    _mobileController = TextEditingController(
      text: widget.userData['mobile_no'] ?? '',
    );
    _addressController = TextEditingController(
      text: widget.userData['address'] ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _selectedRole = widget.userData['role_id']?.toString() ?? '2';

    _birthDateController = TextEditingController(
      text: widget.userData['birth_date'] ?? '',
    );

    DateTime myDate = DateTime.parse(widget.userData['birth_date']);

    _selectedDate = DateTime(myDate.year, myDate.month, myDate.day);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _birthDateController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check password confirmation
    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID
      final userId = widget.userData['id'];

      // Prepare updated data - only include fields that have changed or are not null/empty
      final updatedData = <String, dynamic>{};

      // Add username if not null and not empty
      final username = _usernameController.text.trim();
      if (username.isNotEmpty && username != widget.userData['username']) {
        updatedData['username'] = username;
      }

      // Add email if not null and not empty
      final email = _emailController.text.trim();
      if (email.isNotEmpty && email != widget.userData['email']) {
        updatedData['email'] = email;
      }

      // Add mobile number if not null and not empty
      final mobile = _mobileController.text.trim();
      if (mobile.isNotEmpty && mobile != widget.userData['mobile_no']) {
        updatedData['mobile_no'] = mobile;
      }

      // Add address if not null and not empty
      final address = _addressController.text.trim();
      if (address.isNotEmpty && address != widget.userData['address']) {
        updatedData['address'] = address;
      }

      // Add birth date if changed
      final formattedDate = _formatDateForDatabase(_selectedDate!);
      if (formattedDate != widget.userData['birth_date']) {
        updatedData['birth_date'] = formattedDate;
      }

      // Add role if changed
      final roleId = int.parse(_selectedRole);
      if (roleId.toString() != widget.userData['role_id']?.toString()) {
        updatedData['role_id'] = roleId;
      }

      // Add password only if provided and not empty
      final password = _passwordController.text;
      if (password.isNotEmpty) {
        updatedData['password'] = password;
      }

      // Check if there's anything to update
      if (updatedData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No changes to update'),
            backgroundColor: Colors.blue,
          ),
        );
        Navigator.pop(context);
        return;
      }

      // Call API to update
      final api = ApiPhp(
        tableName: 'users',
        parameters: updatedData,
        whereClause: {'id': userId},
      );

      final response = await api.update();

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Update auth provider if updating current user
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final currentUser = authProvider.user;

        if (currentUser != null && currentUser.id == userId.toString()) {
          await authProvider.updateProfile(updatedData);
        }

        // Navigate back with updated data
        Navigator.pop(context, {
          'success': true,
          'updatedData': {'id': userId, ...widget.userData, ...updatedData},
        });
      } else {
        throw Exception(response['message'] ?? 'Update failed');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDateForDatabase(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _selectDate(BuildContext context) async {
    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: AppTheme.primaryRed,
              colorScheme: ColorScheme.light(primary: AppTheme.primaryRed),
              buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );

      if (picked != null) {
        setState(() {
          _selectedDate = DateTime(picked.year, picked.month, picked.day);
        });
        _birthDateController.text = _formatDateForDatabase(
          _selectedDate!,
        ).toString();
      } else {}
      // ignore: empty_catches
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: AppTheme.primaryRed),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit User Profile',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryRed,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              Text(
                'Basic Information',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),

              // Username Field
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
                hintText: 'Enter username',
                icon: Iconsax.user,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Username is required';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Email Field
              _buildTextField(
                controller: _emailController,
                label: 'Email Address',
                hintText: 'Enter email address',
                icon: Iconsax.sms,
                isReadOnly: true,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Mobile Number Field
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                hintText: 'Enter mobile number',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Mobile number is required';
                  }
                  if (!RegExp(r'^[0-9]{10,15}$').hasMatch(value)) {
                    return 'Enter a valid mobile number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Address Field
              _buildTextField(
                controller: _addressController,
                label: 'Address',
                hintText: 'Enter address',
                icon: Iconsax.location,
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Additional Information
              Text(
                'Additional Information',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),

              // Birth Date Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Birth Date',
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      print("ataya");
                      _selectDate(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.lightRed.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.calendar_1,
                            size: 20,
                            color: AppTheme.primaryRed,
                          ),
                          SizedBox(width: 12),
                          Text(
                            _birthDateController.text,
                            style: GoogleFonts.inter(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          Spacer(),
                          // Calculate age
                          Text(
                            ' 10 years',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Database format:  ',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Password Update (Optional)
              Text(
                'Update Password (Optional)',
                style: GoogleFonts.poppins(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Leave blank to keep current password',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 16),

              // New Password Field
              _buildPasswordField(
                controller: _passwordController,
                label: 'New Password',
                hintText: 'Enter new password',
                isVisible: _showPassword,
                onToggleVisibility: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
                validator: (value) {
                  if (value!.isNotEmpty && value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password Field
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Confirm new password',
                isVisible: _showConfirmPassword,
                onToggleVisibility: () {
                  setState(() {
                    _showConfirmPassword = !_showConfirmPassword;
                  });
                },
                validator: (value) {
                  if (_passwordController.text.isNotEmpty &&
                      value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: AppTheme.lightRed),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Update Profile'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool? isReadOnly,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,

    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.lightRed.withOpacity(0.5)),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: isReadOnly ?? false,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryRed),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.lightRed.withOpacity(0.5)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: !isVisible,
            style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(
                Iconsax.lock,
                size: 20,
                color: AppTheme.primaryRed,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isVisible ? Iconsax.eye : Iconsax.eye_slash,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }
}
