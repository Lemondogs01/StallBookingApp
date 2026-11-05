import 'package:flutter/material.dart';
import 'package:mfu_market/model/user_model.dart';
import 'package:mfu_market/theme.dart';
import 'package:mfu_market/views/discover_view.dart';
import 'package:mfu_market/views/my_bookings_view.dart';
import 'package:mfu_market/views/profile_view.dart';

class VendorHomeView extends StatefulWidget {
  final UserModel user;

  const VendorHomeView({super.key, required this.user});

  @override
  State<VendorHomeView> createState() => _VendorHomeViewState();
}

class _VendorHomeViewState extends State<VendorHomeView> {
  int index = 0;

  Widget buildPage() {
    switch (index) {
      case 0:
        return DiscoverView(
          user: widget.user,
          onBooked: () => setState(() => index = 1),
        );
      case 1:
        return MyBookingsView(user: widget.user);
      default:
        return ProfileView(user: widget.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: buildPage()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
          BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
