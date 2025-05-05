import 'package:eindopdracht/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../widgets/common/app_bottom_navigation.dart';
import 'widgets/recent_transactions_list.dart';
import 'widgets/groups_grid.dart';
import '../../core/constants/app_styles.dart';
import '../../widgets/common/add_receipt_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.getAppBarBackgroundColor(context),
        title: Text('Home', style: AppStyles.heading.copyWith(color: AppColors.getAppBarTextColor(context))),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recent Transactions',
                  style: AppStyles.subheading
                      .copyWith(color: AppColors.getTextColor(context))),
              const SizedBox(height: 8),
              const RecentTransactionsList(),
              Transform.translate(
                offset: const Offset(0, -8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/transactions');
                      },
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // const SizedBox(height: 16),
              Text('Groups',
                  style: AppStyles.subheading
                      .copyWith(color: AppColors.getTextColor(context))),
              const SizedBox(height: 8),
              const GroupsGrid(),
            ],
          ),
        ),
      ),
      // Removed floatingActionButton and floatingActionButtonLocation
      bottomNavigationBar: AppBottomNavigation(currentIndex: 0),
    );
  }
}
