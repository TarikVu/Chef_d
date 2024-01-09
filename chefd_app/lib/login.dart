import 'package:chefd_app/discover.dart';
import 'package:chefd_app/home.dart';
import 'package:chefd_app/sign_up.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  bool _isLoading = false;
  final TextEditingController _emailController =
      //TextEditingController(text: "test@gmail.com");
      TextEditingController(text: "");
  final TextEditingController _passwordController =
      // TextEditingController(text: "password");
      TextEditingController(text: "");

  // login function that handles the supabase transactio
  Future<String?> userLogin({
    required final String email,
    required final String password,
  }) async {
    if (email.isEmpty || password.isEmpty) return null;
    // if client.auth.
    final response = await supabase.auth
        .signInWithPassword(email: email, password: password);
    final user = response.user;
    return user?.id;
  }

  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeWidget()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: SafeArea(
          child: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            // Icon
            const SizedBox(
              width: 400,
              height: 200,
              child: Image(
                fit: BoxFit.fill,
                image: AssetImage('assets/logo.jpg'),
              ),
            ),
            const SizedBox(height: 20),
            // Welcome to Chef'd
            Text(
              'Welcome back Chef!',
              style: GoogleFonts.anton(color: primaryOrange, fontSize: 40),
            ),
            const SizedBox(
              height: 40,
            ),
            //Email/Username
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                        hintText: 'Username / Email',
                      ),
                    ))),
            const SizedBox(
              height: 15,
            ),

            //Password
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                    decoration: BoxDecoration(
                      color: white,
                      border: Border.all(color: grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(10),
                        border: InputBorder.none,
                        hintText: 'Password',
                      ),
                      obscureText: true,
                    ))),
            const SizedBox(
              height: 15,
            ),

            //Login button
            _isLoading
                ? Container(
                    height: 30,
                    width: 30,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: primaryOrange,
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });

                        try {
                          dynamic loginValue = await userLogin(
                              email: _emailController.text,
                              password: _passwordController.text);
                          setState(() {
                            _isLoading = false;
                          });
                          if (loginValue != null) {
                            userId = supabase.auth.currentUser!.id;
                            _navigateToHome();
                            // Navigator.pushReplacementNamed(context, '/home');
                          }
                        } on AuthException catch (e) {
                          context.showErrorMessage(e.message);
                          setState(() {
                            _isLoading = false;
                          });
                        } catch (e) {
                          context.showErrorMessage(e.toString());
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(23.0),
                          elevation: 15.0,
                          backgroundColor: primaryOrange),
                      child: const Center(
                          child: Text(
                        'Login',
                        style: TextStyle(
                            color: white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      )),
                    ),
                  ),
            const SizedBox(
              height: 15,
            ),

            //Register
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sign Up? ',
                  style: TextStyle(
                      color: primaryOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpWidget())),

                  //   Navigator.pushReplacementNamed(context, '/signup'),
                  child: const Text(
                    'Register now',
                    style: TextStyle(
                      color: secondaryOrange,
                      fontSize: 13,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 8,
            ),

            //Forgot Password
            InkWell(
                onTap: () => null,
                child: const Text(
                  'Forgot Password',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: primaryOrange),
                ))
          ]))),
    );
  }
}
