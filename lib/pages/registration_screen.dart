// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../app_theme.dart';
// import '../provider/auth_provider.dart';

// class RegisterScreen extends StatefulWidget {
//   final int? roleId;
//   const RegisterScreen({super.key, this.roleId});

//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }

// class _RegisterScreenState extends State<RegisterScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _usernameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   final _mobileController = TextEditingController();
//   final _dobController = TextEditingController();
//   final _addressController = TextEditingController();

//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   bool _obscureConfirmPassword = true;

//   void _register() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });
//       Map<String, dynamic> parameter = {
//         "username": _usernameController.text.trim(),
//         "email": _emailController.text.trim(),
//         "password": _passwordController.text.trim(),
//         "mobile_no": _mobileController.text.trim(),
//         "birth_date": DateTime.parse(
//           _dobController.text.trim(),
//         ).toString().split(" ")[0],
//         "address": _addressController.text.trim(),
//         "role_id": widget.roleId ?? 2,
//       };
//       try {
//         final authProvider = Provider.of<AuthProvider>(context, listen: false);
//         final success = await authProvider.register(parameter);
//         if (success) {
//           // SHOW SUCCESS MESSAGE
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Registration successful!"),
//               backgroundColor: Colors.green,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//           );

//           Navigator.of(context).pop();
//           return;
//         } else {
//           // SHOW ERROR MESSAGE
//           if (authProvider.error != null) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text(authProvider.error!),
//                 backgroundColor: AppTheme.dangerColor,
//                 behavior: SnackBarBehavior.floating,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             );
//           }
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Registration failed: $e'),
//             backgroundColor: AppTheme.dangerColor,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Join MindCare'),
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               const SizedBox(height: 20),
//               Text(
//                 'Begin Your Wellness Journey',
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                   color: AppTheme.primaryRed,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Create your secure account and start your path to mental wellness',
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   color: AppTheme.textSecondary,
//                   height: 1.4,
//                 ),
//               ),
//               const SizedBox(height: 40),

//               // Username Field
//               TextFormField(
//                 controller: _usernameController,
//                 decoration: InputDecoration(
//                   labelText: 'Username',
//                   hintText: 'Enter your full name',
//                   prefixIcon: Icon(
//                     Icons.person_outline,
//                     color: AppTheme.primaryRed,
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a username';
//                   }
//                   if (value.length < 3) {
//                     return 'Username must be at least 3 characters';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Email Field
//               TextFormField(
//                 controller: _emailController,
//                 decoration: InputDecoration(
//                   labelText: 'Email Address',
//                   hintText: 'your.email@example.com',
//                   prefixIcon: Icon(
//                     Icons.email_outlined,
//                     color: AppTheme.primaryRed,
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your email';
//                   }
//                   if (!value.contains('@')) {
//                     return 'Please enter a valid email';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Mobile Number Field
//               TextFormField(
//                 controller: _mobileController,
//                 decoration: InputDecoration(
//                   labelText: 'Mobile Number',
//                   hintText: '+1 234 567 8900',
//                   prefixIcon: Icon(
//                     Icons.phone_outlined,
//                     color: AppTheme.primaryRed,
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 keyboardType: TextInputType.phone,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your mobile number';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Date of Birth Field
//               TextFormField(
//                 controller: _dobController,
//                 decoration: InputDecoration(
//                   labelText: 'Date of Birth',
//                   hintText: 'YYYY-MM-DD',
//                   prefixIcon: Icon(
//                     Icons.calendar_today_outlined,
//                     color: AppTheme.primaryRed,
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your date of birth';
//                   }
//                   final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
//                   if (!dateRegex.hasMatch(value)) {
//                     return 'Please use YYYY-MM-DD format';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Address Field
//               TextFormField(
//                 controller: _addressController,
//                 decoration: InputDecoration(
//                   labelText: 'Address',
//                   hintText: 'Your current address',
//                   prefixIcon: Icon(
//                     Icons.location_on_outlined,
//                     color: AppTheme.primaryRed,
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 maxLines: 2,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter your address';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Password Field
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: 'Password',
//                   hintText: 'At least 6 characters',
//                   prefixIcon: Icon(
//                     Icons.lock_outline,
//                     color: AppTheme.primaryRed,
//                   ),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscurePassword
//                           ? Icons.visibility_outlined
//                           : Icons.visibility_off_outlined,
//                       color: AppTheme.textSecondary,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscurePassword = !_obscurePassword;
//                       });
//                     },
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please enter a password';
//                   }
//                   if (value.length < 6) {
//                     return 'Password must be at least 6 characters';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Confirm Password Field
//               TextFormField(
//                 controller: _confirmPasswordController,
//                 obscureText: _obscureConfirmPassword,
//                 decoration: InputDecoration(
//                   labelText: 'Confirm Password',
//                   hintText: 'Re-enter your password',
//                   prefixIcon: Icon(
//                     Icons.lock_outline,
//                     color: AppTheme.primaryRed,
//                   ),
//                   suffixIcon: IconButton(
//                     icon: Icon(
//                       _obscureConfirmPassword
//                           ? Icons.visibility_outlined
//                           : Icons.visibility_off_outlined,
//                       color: AppTheme.textSecondary,
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         _obscureConfirmPassword = !_obscureConfirmPassword;
//                       });
//                     },
//                   ),
//                   floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please confirm your password';
//                   }
//                   if (value != _passwordController.text) {
//                     return 'Passwords do not match';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 30),

//               // Register Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _register,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppTheme.primaryRed,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(16),
//                     ),
//                     elevation: 3,
//                     shadowColor: AppTheme.primaryRed.withOpacity(0.3),
//                   ),
//                   child: _isLoading
//                       ? SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation<Color>(
//                               Colors.white,
//                             ),
//                           ),
//                         )
//                       : Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Text(
//                               'Start My Journey',
//                               style: GoogleFonts.inter(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Icon(Icons.arrow_forward, size: 20),
//                           ],
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Login Link
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Already part of our community? ',
//                     style: GoogleFonts.inter(
//                       color: AppTheme.textSecondary,
//                       fontSize: 12,
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pushReplacementNamed(context, '/login');
//                     },
//                     child: Text(
//                       'Sign In',
//                       style: GoogleFonts.inter(
//                         color: AppTheme.primaryRed,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               // Terms and conditions
//               Text(
//                 'By creating an account, you agree to our Terms of Service and Privacy Policy',
//                 style: GoogleFonts.inter(
//                   color: AppTheme.textSecondary,
//                   fontSize: 10,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     _mobileController.dispose();
//     _dobController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../provider/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  final int? roleId;
  const RegisterScreen({super.key, this.roleId});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Helper method to check if we should show admin UI
  bool get _isAdminRegistration => widget.roleId == 1 || widget.roleId != null;

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      Map<String, dynamic> parameter = {
        "username": _usernameController.text.trim(),
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
        "mobile_no": _mobileController.text.trim(),
        "birth_date": DateTime.parse(
          _dobController.text.trim(),
        ).toString().split(" ")[0],
        "address": _addressController.text.trim(),
        "role_id": widget.roleId ?? 2,
      };
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.register(parameter);
        if (success) {
          // SHOW SUCCESS MESSAGE
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isAdminRegistration
                    ? "Admin added successfully!"
                    : "Registration successful!",
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          Navigator.of(context).pop();
          return;
        } else {
          // SHOW ERROR MESSAGE
          if (authProvider.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.error!),
                backgroundColor: AppTheme.dangerColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isAdminRegistration
                  ? 'Failed to add admin: $e'
                  : 'Registration failed: $e',
            ),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdminRegistration ? 'Add Admin' : 'Join MindCare'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              Text(
                _isAdminRegistration
                    ? 'Add New Administrator'
                    : 'Begin Your Wellness Journey',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isAdminRegistration
                    ? 'Create a new admin account with elevated privileges'
                    : 'Create your secure account and start your path to mental wellness',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // Username Field
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter full name',
                  prefixIcon: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryRed,
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'admin.email@example.com',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryRed,
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email address';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: '+1 234 567 8900',
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: AppTheme.primaryRed,
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date of Birth Field
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.primaryRed,
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter date of birth';
                  }
                  final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                  if (!dateRegex.hasMatch(value)) {
                    return 'Please use YYYY-MM-DD format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Address Field
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  hintText: 'Current address',
                  prefixIcon: Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primaryRed,
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password Field
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'At least 6 characters',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryRed,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryRed,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  floatingLabelStyle: TextStyle(color: AppTheme.primaryRed),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    shadowColor: AppTheme.primaryRed.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isAdminRegistration
                                  ? 'Add Admin Account'
                                  : 'Start My Journey',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Only show login link for regular registration (not admin)
              if (!_isAdminRegistration) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already part of our community? ',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          color: AppTheme.primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Terms and conditions (only for regular users)
                Text(
                  'By creating an account, you agree to our Terms of Service and Privacy Policy',
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
