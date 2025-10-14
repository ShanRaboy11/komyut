import 'package:flutter/material.dart';

class AnimatedBottomNavBar extends StatefulWidget {
  final List<Widget> pages;
  final List<NavItem> items;
  final int initialIndex;
  final Function(int)? onNavigationChanged;

  const AnimatedBottomNavBar({
    super.key,
    required this.pages,
    required this.items,
    this.initialIndex = 0,
    this.onNavigationChanged,
  });

  @override
  State<AnimatedBottomNavBar> createState() => _AnimatedBottomNavBarState();
}

class _AnimatedBottomNavBarState extends State<AnimatedBottomNavBar>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _oldIndex = _selectedIndex.toDouble();
      _selectedIndex = index;
    });
    _controller.forward(from: 0);
    widget.onNavigationChanged?.call(index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length;

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: widget.pages,
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),// ⬅ horizontal padding added
            child: CustomPaint(
              painter: _MovingCurvePainter(
                colorStops: const [
                  Color(0xFFB945AA),
                  Color(0xFF8E4CB6),
                  Color(0xFF5B53C2),
                ],
                oldIndex: _oldIndex,
                newIndex: _selectedIndex.toDouble(),
                progress: _animation.value,
                itemCount: itemCount,
              ),
              child: SizedBox(
                height: 90,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final isSelected = _selectedIndex == index;
                    final isSmall = MediaQuery.of(context).size.width < 400;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent, // 👈 makes tapping easier
                        onTap: () => _onItemTapped(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOutCubic,
                                transform: Matrix4.translationValues(
                                    0, isSelected ? -25 : 0, 0),
                                child: Container(
                                  width: isSelected ? 44 : 40,
                                  height: isSelected ? 44 : 40,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFB945AA),
                                              Color(0xFF8E4CB6),
                                              Color(0xFF5B53C2),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.25),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      item.icon,
                                      color: Colors.white,
                                      size: isSmall ? 26 : 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOutCubic,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.0),
                                  fontSize: isSmall ? 13 : 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                child: Transform.translate(
                                  offset:
                                      const Offset(0, -8), // lift label a bit
                                  child: Text(item.label),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class NavItem {
  final IconData icon;
  final String label;
  const NavItem({required this.icon, required this.label});
}

/// 🎨 Custom painter for moving notch curve
class _MovingCurvePainter extends CustomPainter {
  final List<Color> colorStops;
  final double oldIndex;
  final double newIndex;
  final double progress;
  final int itemCount;

  _MovingCurvePainter({
    required this.colorStops,
    required this.oldIndex,
    required this.newIndex,
    required this.progress,
    required this.itemCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: colorStops,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final currentIndex = oldIndex + (newIndex - oldIndex) * progress;
    final itemWidth = size.width / itemCount;
    final centerX = (currentIndex * itemWidth) + (itemWidth / 2);
    const notchRadius = 28.0;
    const notchWidth = 72.0;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - notchWidth / 2 - 10, 0);

    // 👇 Centered, smooth curve
    path.quadraticBezierTo(
        centerX - notchWidth / 2, 0, centerX - notchWidth / 2 + 6, 10);
    path.arcToPoint(
      Offset(centerX + notchWidth / 2 - 6, 10),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
        centerX + notchWidth / 2, 0, centerX + notchWidth / 2 + 10, 0);

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withOpacity(0.25), 6, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MovingCurvePainter oldDelegate) => true;
}


/*class NavBarCommuter extends StatelessWidget {
  const NavBarCommuter ({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        Center(child: Text("🏠 Home")),
        Center(child: Text("📋 Activity")),
        Center(child: Text("✍️ QR Scan")),
        Center(child: Text("🔔 Notifications")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.qr_code_scanner_rounded, label: 'QR Scan'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}

class NavBarDriver extends StatelessWidget {
  const NavBarDriver ({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        Center(child: Text("🏠 Home")),
        Center(child: Text("📋 Activity")),
        Center(child: Text("✍️ Feedback")),
        Center(child: Text("🔔 Notifications")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.overview_rounded, label: 'Activity'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Feedback'),
        NavItem(icon: Icons.notifications_rounded, label: 'Notification'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}

class NavBarOperator extends StatelessWidget {
  const NavBarOperator ({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        Center(child: Text("🏠 Home")),
        Center(child: Text("📋 Drivers")),
        Center(child: Text("✍️ Transactions")),
        Center(child: Text("🔔 Reports")),
        Center(child: Text("👤 Profile")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.group, label: 'Drivers'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Transactions'),
        NavItem(icon: Symbols.chat_info_rounded, label: 'Reports'),
        NavItem(icon: Icons.person_rounded, label: 'Profile'),
      ],
    );
  }
}

class NavBarAdmin extends StatelessWidget {
  const NavBarAdmin ({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBottomNavBar(
      pages: const [
        Center(child: Text("🏠 Home")),
        Center(child: Text("📋 Verified")),
        Center(child: Text("✍️ Activity")),
        Center(child: Text("🔔 Reports")),
      ],
      items: const [
        NavItem(icon: Icons.home_rounded, label: 'Home'),
        NavItem(icon: Symbols.verified, label: 'Verified'),
        NavItem(icon: Symbols.rate_review_rounded, label: 'Activity'),
        NavItem(icon: Symbols.chat_info_rounded, label: 'Reports'),
      ],
    );
  }
}*/
