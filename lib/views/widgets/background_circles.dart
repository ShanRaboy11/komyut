import 'package:flutter/material.dart';

class BackgroundCircles extends StatelessWidget {
  const BackgroundCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        // Initial purple background from Figma (if you need it, otherwise the Scaffold's gradient takes over)
        // Positioned(
        //   top: 0,
        //   left: 0,
        //   child: Container(
        //     width: 393, // You might want to use MediaQuery.of(context).size.width
        //     height: 852, // You might want to use MediaQuery.of(context).size.height
        //     decoration: BoxDecoration(
        //       color : const Color.fromRGBO(185, 69, 170, 1),
        //     ),
        //   ),
        // ),

        Positioned(
          top: 39,
          left: 172,
          child: Image.asset("assets/images/Ellipse 1.png"),
        ),
        Positioned(
          top: -134,
          left: 22,
          child: Image.asset("assets/images/Ellipse 3.png"),
        ),
        Positioned(
          top: 672,
          left: -94,
          child: Image.asset("assets/images/Ellipse 2.png"),
        ),
        Positioned(
          top: 454,
          left: -293,
          child: Image.asset("assets/images/Ellipse 4.png"),
        ),
        Positioned(
          top: 454, 
          left: -293,
          child: Image.asset("assets/images/Ellipse 5.png"),
        ),
        Positioned(
          top: 39,
          left: 172,
          child: Image.asset("assets/images/Ellipse 1.png"),
        ),
        Positioned(
          top: -134,
          left: 22,
          child: Image.asset("assets/images/Ellipse 3.png"),
        ),
        Positioned(
          top: 672,
          left: -94,
          child: Image.asset("assets/images/Ellipse 2.png"),
        ),
        Positioned(
          top: 454,
          left: -293,
          child: Image.asset("assets/images/Ellipse 4.png"),
        ),
        Positioned(
          top: 454, 
          left: -293,
          child: Image.asset("assets/images/Ellipse 5.png"),
        ),

  
      ],
    );
  }
}