import 'dart:ui';
import 'package:flutter/material.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🌈 Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F3D2E),
                  Color(0xFF1E7F5C),
                  Color(0xFF8ED16F),
                ],
              ),
            ),
          ),

          // 🌫 Bokeh light effects
          _bokeh(80, 100, 120),
          _bokeh(250, -40, 160),
          _bokeh(-60, 420, 200),
          _bokeh(280, 600, 140),

          // 📜 Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 30,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🥗 App title
                  const Text(
                    "NutriSnap",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Eat smarter. One snap at a time.",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // 🧠 Glass info card
                  _glassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _InfoRow(
                          icon: Icons.camera_alt,
                          text: "Just snap your food.",
                        ),
                        SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.smart_toy,
                          text: "Our AI understands what you eat.",
                        ),
                        SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.restaurant,
                          text: "Get nutrition insights instantly.",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🧩 Feature grid
                  Row(
                    children: [
                      Expanded(
                        child: _featureCard(
                          icon: Icons.restaurant_menu,
                          title: "Food Detection",
                          subtitle: "AI-powered recognition",
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _featureCard(
                          icon: Icons.favorite,
                          title: "Health Focus",
                          subtitle: "Eat with intention",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _featureCard(
                          icon: Icons.bar_chart,
                          title: "Nutrition",
                          subtitle: "Calories & macros",
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _featureCard(
                          icon: Icons.notifications_active,
                          title: "Smart Tips",
                          subtitle: "Gentle reminders",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ❤️ Emotional line
                  const Text(
                    "You don’t need to be perfect.\n"
                    "Just be aware. We’ll help 💚",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  // 💚 Glowing CTA
                  _glowButton(
                    text: "Snap Your Food",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CameraScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // UI COMPONENTS
  // --------------------------------------------------

  static Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return _glassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _glowButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.greenAccent.withOpacity(0.8),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7ED957),
          padding:
              const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.camera_alt, color: Colors.black),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onTap,
      ),
    );
  }

  static Widget _bokeh(double left, double top, double size) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.18),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Container(),
        ),
      ),
    );
  }
}

// --------------------------------------------------
// 🧾 Info Row Widget
// --------------------------------------------------
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }
}
