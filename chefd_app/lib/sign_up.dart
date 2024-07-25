import 'dart:io';
import 'package:chefd_app/allergen_menu.dart';
import 'package:chefd_app/home_layout.dart';
import 'package:chefd_app/login.dart';
import 'package:chefd_app/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chefd_app/utils/image_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  bool _isLoading = false;
  final TextEditingController _emailController =
      TextEditingController(text: "");
  final TextEditingController _usernameController =
      TextEditingController(text: "");
  final TextEditingController _passwordController =
      TextEditingController(text: "");
  final TextEditingController _passwordConfirmController =
      TextEditingController(text: "");
  File? _selectedImg;
  //= File(
  //  supabase.storage.from('misc').getPublicUrl('/blank-profile-picture.png'));
  final _imageHelper = ImageHelper();
  bool hasProfilePic = false;

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

  Future<String?> userCreateAccount({
    required final String email,
    required final String password,
    required final String passwordConfirm,
    required final String username,
  }) async {
    if (password.length < 6) {
      context.showErrorMessage('Password must be at least 6 characters');
      return null;
    }
    if (email.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      context.showErrorMessage('Email or Password left blank');
      return null;
    }
    if (password != passwordConfirm) {
      context.showErrorMessage('Passwords do not match.');
      return null;
    }
    final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username.toLowerCase()});
    final user = response.user;
    final userID = user?.id;

    userId = supabase.auth.currentUser!.id;

    String? imageUrl;

    try {
      if (_selectedImg != null) {
        // These two lines will save the image under storage->pictures->userId->filename
        final imgName = _selectedImg!.path.split('/').last;
        final imagePath = '/$userID/$imgName';
        // Saves as a .png file.
        final imageExtension = _selectedImg!.path.split('.').last.toLowerCase();

        // Holds returned image URL from supabase storge.  Is then inserted into posts table.

        // upload photo to storage
        print(imagePath);
        supabase.storage.from('UserProfilePictures').upload(
            imagePath, _selectedImg!,
            fileOptions: FileOptions(
                contentType: 'image/$imageExtension', upsert: true));

        // pull back the url from storage to insert into the posts table.
        // if no image was chosen, insert null

        imageUrl = supabase.storage
            .from('UserProfilePictures')
            .getPublicUrl(imagePath);
      } else {
        // No prof pic was chosen
        imageUrl = null;
      }

      final info = await supabase.from(userInfo).insert({
        "user_id": userID,
        "difficulty": 0,
        "timespend": 0,
        "username": username,
        "profile_picture": imageUrl
      });
    } catch (e) {
      context.showErrorMessage('Error creating account');
    }

    return userID;
  }

  selectImage(parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: const Text("Image selection"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => {pickImageFromCamera()},
                child: const Text("Photo with Camera"),
              ),
              SimpleDialogOption(
                onPressed: () => {pickImageFromGallery()},
                child: const Text("Image from Gallery"),
              ),
              SimpleDialogOption(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  void _navigateToAdditionalInfo() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeWidget()),
      (route) => false,
    );
  }

  // Utilizes ImageHelper to Select from Gallery & crop.
  Future pickImageFromGallery() async {
    final file = await _imageHelper.pickImageFromGallery();
    final croppedFile = await _imageHelper.crop(file: file);
    if (croppedFile != null) {
      setState(() {
        _selectedImg = File(croppedFile.path);
        hasProfilePic = true;
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

  // Utilizes ImageHelper to Select from Camera & crop.
  Future pickImageFromCamera() async {
    final file = await _imageHelper.pickImageFromCamera();
    final croppedFile = await _imageHelper.crop(file: file);
    if (croppedFile != null) {
      setState(() {
        _selectedImg = File(croppedFile.path);
        hasProfilePic = true;
        Navigator.of(context, rootNavigator: true).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
            child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
              // Icon
              const SizedBox(
                width: 400,
                height: 150,
                child: Image(
                  fit: BoxFit.fill,
                  image: AssetImage('assets/logo.jpg'),
                ),
              ),
              const SizedBox(height: 20),
              Stack(children: [
                CircleAvatar(
                    radius: 64,
                    backgroundImage: !hasProfilePic
                        ? NetworkImage(supabase.storage
                            .from('misc')
                            .getPublicUrl('/blank-profile-picture.png'))
                        : FileImage(File(_selectedImg!.path)) as ImageProvider,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            onPressed: () => selectImage(context),
                            icon: const Icon(Icons.add_a_photo_outlined),
                          ),
                        )
                      ],
                    )),
              ]),

              // Welcome to Chef'd
              Text(
                'Welcome to Chef\'d!',
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
                          hintText: 'Email',
                        ),
                      ))),
              const SizedBox(
                height: 15,
              ),

              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                      decoration: BoxDecoration(
                        color: white,
                        border: Border.all(color: grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          border: InputBorder.none,
                          hintText: 'Username',
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

              //Password Confirmation
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Container(
                      decoration: BoxDecoration(
                        color: white,
                        border: Border.all(color: grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _passwordConfirmController,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(10),
                          border: InputBorder.none,
                          hintText: 'Confirm Password',
                        ),
                        obscureText: true,
                      ))),
              const SizedBox(
                height: 15,
              ),

              //Create Account button
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
                            final signupValue = await userCreateAccount(
                                email: _emailController.text,
                                username: _usernameController.text,
                                password: _passwordController.text,
                                passwordConfirm:
                                    _passwordConfirmController.text);

                            setState(() {
                              _isLoading = false;
                            });
                            if (signupValue != null) {
                              final loginValue = await userLogin(
                                  email: _emailController.text,
                                  password: _passwordController.text);
                              userId = supabase.auth.currentUser!.id;
                              _navigateToAdditionalInfo();
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
                          'Create Account',
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
              // Reroute to Login page
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an Account? ',
                    style: TextStyle(
                        color: primaryOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                  InkWell(
                    // just pop back to login, no need to redirect and add to stack.
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: secondaryOrange,
                        fontSize: 13,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              //Register
            ]))),
      ),
    );
  }
}
