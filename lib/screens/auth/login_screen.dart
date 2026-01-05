import 'package:flutter/material.dart';
import 'register_screen.dart';
import '../home_screen.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble, size: 100, color: Colors.blue),
                const SizedBox(height: 20),
                const Text(
                  "Login",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email)),
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: "Password",
                      prefixIcon: Icon(Icons.lock)),
                  validator: (value) {
                    if (value == null || value.length < 6) {
                      return 'Password must be at least 6 chars';
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

                          await ApiService.login(
                            email: _emailController.text.trim(),
                            password: _passwordController.text,
                          );

                          // Initialize socket connection
                          await SocketService.initialize();

                          if (!mounted) return;
                          navigator.pop(); // Close loading dialog

                          if (!mounted) return;
                          navigator.pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
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
                    child: const Text("Login", style: TextStyle(fontSize: 20,color: Colors.white),),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        "Register",
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
