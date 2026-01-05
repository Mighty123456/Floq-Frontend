import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.chat_bubble, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  "Register",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: "Name", prefixIcon: Icon(Icons.person)),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email", prefixIcon: Icon(Icons.email)),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: "Password", prefixIcon: Icon(Icons.lock)),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 chars';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: "Confirm Password",
                      prefixIcon: Icon(Icons.lock)),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        if (!mounted) return;
                        final navigator = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        
                        try {
                          // Show loading
                          if (!mounted) return;
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (dialogContext) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          await ApiService.register(
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          );

                          if (!mounted) return;
                          navigator.pop(); // Close loading dialog

                          if (!mounted) return;
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Registration successful! Please check your email for OTP.'),
                              backgroundColor: Colors.green,
                            ),
                          );

                          if (!mounted) return;
                          navigator.pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          navigator.pop(); // Close loading dialog
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(e.toString().replaceAll('Exception: ', '')),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text("Register", style: TextStyle(fontSize: 20,color: Colors.white)),
                  ),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("If have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        "Login",
                        style: TextStyle(
                            color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
