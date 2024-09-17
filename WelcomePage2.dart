import 'package:bikeblues/Authentication/U_login.dart';
import 'package:bikeblues/Authentication/V_SignIn.dart';
import 'package:flutter/material.dart';

class WelcomePage2 extends StatefulWidget {
  const WelcomePage2({super.key});

  @override
  State<WelcomePage2> createState() => _WelcomePage2State();
}

class _WelcomePage2State extends State<WelcomePage2> {
  // Boolean state variables to track if the container is tapped
  bool isModifyBikeTapped = false;
  bool isSellPartsTapped = false;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
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
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: h * 0.05, left: w * 0.3),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/defaultLogo.png',
                      ),
                      SizedBox(width: w * 0.04),
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
                              Rect.fromLTWH(0, 0, w * 0.5, h * 0.05),
                            ),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: h * 0.06),
                Text(
                  'Choose Your Role',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: h * 0.4),
                SingleChildScrollView(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isModifyBikeTapped = true;
                              isSellPartsTapped = false;
                            });
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const Signin()));
                          },
                          child: Container(
                            height: h * 0.17,
                            width: w * 0.4,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(86, 86, 86, 0.8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isModifyBikeTapped
                                    ? Color.fromRGBO(78, 156, 212, 1)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                      'assets/images/Vector.png'),
                                ),
                                Text(
                                  'Modify a Bike',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      height: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isSellPartsTapped = true;
                              isModifyBikeTapped = false;
                            });
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => VendorLoginScreen()));
                          },
                          child: Container(
                            height: h * 0.17,
                            width: w * 0.4,
                            decoration: BoxDecoration(
                              color: Color.fromRGBO(86, 86, 86, 0.8),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isSellPartsTapped
                                    ? Color.fromRGBO(78, 156, 212, 1)
                                    : Colors.transparent,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Image.asset(
                                      'assets/images/Vector (2).png'),
                                ),
                                Text(
                                  'Sell Parts',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      height: 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
