import 'package:flutter/material.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Image.asset(
                'assets/images/bg theme 1.png',
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'BikeBlues',
                    style: TextStyle(
                      fontSize: 24,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: <Color>[
                            Color(0xFF4E9CD4),
                            Color(0xFF53DDA3),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(
                            Rect.fromLTWH(0, 0, screenWidth * 0.5, screenHeight * 0.05)),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Divider(thickness: 3, color: Colors.white,),
                  SizedBox(height: screenHeight * 0.02,),
                  Text('Modify Your Bike', style: TextStyle(fontSize: 20, color: Colors.white),),
                  SizedBox(height: screenHeight * 0.02,),
                  Divider(thickness: 3, color: Colors.white,),
                  SizedBox(height: screenHeight * 0.02,),
                  Text('Purchase Parts', style: TextStyle(fontSize: 20, color: Colors.white),),
                  SizedBox(height: screenHeight * 0.02,),
                  Divider(thickness: 3, color: Colors.white,),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
