import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  final double vectorHeight;
  final double vectorWidth;
  final double komyutHeight;
  final double overlap;
  final double? overallWidth; 
  final double? overallHeight; 

  const Logo({
    super.key,
    this.vectorHeight = 200, 
    this.vectorWidth = 250, 
    this.komyutHeight = 130.77, 
    this.overlap = 45,      
    this.overallWidth,       
    this.overallHeight,     
  });

  @override
  Widget build(BuildContext context) {
    final double calculatedKomyutTop = vectorHeight - overlap;

    final double defaultOverallHeight = vectorHeight + (komyutHeight - overlap);

    return Container(
      width: overallWidth ?? MediaQuery.of(context).size.width, 
      height: overallHeight ?? defaultOverallHeight, 
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -20,
            child: Image.asset(
              "assets/images/Vector.png",
              height: vectorHeight,
              width: vectorWidth,
            ),
          ),

          Positioned(
            top: calculatedKomyutTop,
            child: Image.asset(
              "assets/images/komyut.png",
              height: komyutHeight,
            ),
          ),
        ],
      ),
    );
  }
}