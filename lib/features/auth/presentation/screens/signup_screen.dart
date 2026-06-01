import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111113), // Deep Obsidian Charcoal
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // Header section
              const Text(
                "Start Your Journey",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Create a private space for just the two of you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF8E8E9F), // Muted Gray
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 64),

              // Google Sign Up Button wrapped with BlocConsumer
              BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    // Navigate to the couple linking setup placeholder route
                    Navigator.pushReplacementNamed(context, '/couple_link');
                  } else if (state is AuthFailure) {
                    // Show failure snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.errorMessage),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => context
                            .read<AuthBloc>()
                            .add(GoogleSignInRequestedEvent()),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.transparent, // Minimalist transparent bg
                        border: Border.all(
                          color: const Color(0xFFFFB7CE)
                              .withOpacity(0.5), // Subtle Pastel Pink border
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading)
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color:
                                    Color(0xFFFFB7CE), // Pastel Pink indicator
                                strokeWidth: 2.5,
                              ),
                            )
                          else ...[
                            // Placeholder for Google Icon
                            const Icon(
                              Icons.g_mobiledata,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Sign Up with Google",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const Spacer(),

              // Bottom Text Link
              GestureDetector(
                onTap: () {
                  // Navigate to the Login screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(
                        color: Color(0xFF8E8E9F), // Muted Gray
                        fontSize: 14,
                      ),
                      children: [
                        TextSpan(
                          text: "Sign In",
                          style: TextStyle(
                            color: Color(0xFFFFB7CE), // Pastel Pink accent
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
