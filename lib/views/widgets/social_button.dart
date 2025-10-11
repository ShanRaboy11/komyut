import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String imagePath;
  final VoidCallback onPressed; 

  const SocialButton({
    Key? key,
    required this.imagePath,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed, 
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [ 
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            imagePath,
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }
}