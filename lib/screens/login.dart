import 'package:app_limiter/common/fetcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:art_sweetalert_new/art_sweetalert_new.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    try {
      final response = await Fetcher.post('/auth/login', {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'name': _nameController.text.trim(),
      });

      if (response['success'] == true) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      ArtSweetAlert.show(
        context: context,
        title: Text(e.toString()),
        type: ArtAlertType.error,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon kunci
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E00FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Color(0xFF1E00FF),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 24),

                // Judul
                const Text(
                  "App Limiter",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Subjudul
                const Text(
                  "Welcome back! Please sign in to continue.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 14),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.person,
                      color: Color(0xFFB3B3B3),
                    ),
                    hintText: "Name",
                    hintStyle: const TextStyle(color: Color(0xFF6E6E6E)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C28),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFFB3B3B3),
                    ),
                    hintText: "Email",
                    hintStyle: const TextStyle(color: Color(0xFF6E6E6E)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C28),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Color(0xFFB3B3B3),
                    ),
                    hintText: "Password",
                    hintStyle: const TextStyle(color: Color(0xFF6E6E6E)),
                    filled: true,
                    fillColor: const Color(0xFF1C1C28),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tombol Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _isLoading ? null : _handleLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E00FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.grey)
                        : Text(
                            "Login",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider "Or continue with"
                Row(
                  children: const [
                    Expanded(
                      child: Divider(color: Color(0xFF2A2A35), thickness: 1),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "Or continue with",
                        style: TextStyle(color: Color(0xFF7D7D89)),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Color(0xFF2A2A35), thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tombol Google
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFF191926),
                      side: const BorderSide(color: Color(0xFF2A2A35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: SvgPicture.network(
                      'https://cdn.jsdelivr.net/gh/devicons/devicon/icons/google/google-original.svg',
                      height: 20,
                    ),
                    label: const Text(
                      "Sign in with Google",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Link ke Create Account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don’t have an account? ",
                      style: TextStyle(color: Color(0xFFB3B3B3)),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: const Text(
                        "Create Account",
                        style: TextStyle(
                          color: Color(0xFF1E00FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
