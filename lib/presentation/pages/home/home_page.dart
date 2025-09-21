import 'package:flutter/material.dart';
import 'package:vos_app/presentation/widgets/app_rail.dart';
import 'package:vos_app/presentation/widgets/input_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              AppRail(),
              Expanded(
                child: SizedBox(), // Empty space for now
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(),
          ),
        ],
      ),
    );
  }
}