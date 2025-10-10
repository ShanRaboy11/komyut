import 'package:flutter/material.dart';
import '../widgets/button.dart';
import '../widgets/logo.dart';

class CreateAccountPage extends StatelessWidget {
  const CreateAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Positioned(
              top: 10,
              child:  const Logo()
              )
            
          ],
        ),
      ),
    );
  }
}