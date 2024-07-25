import 'dart:async';

import 'package:chefd_app/theme/colors.dart';
import 'package:chefd_app/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CookNowWidget extends StatefulWidget {
  const CookNowWidget({super.key});

  @override
  State<CookNowWidget> createState() => _CookNowWidget();
}

class _CookNowWidget extends State<CookNowWidget> {
  int recipeID = 0;
  List<dynamic>? instr;
  bool hasData = false;
  bool displayAllInstructions = false;
  int currentStep = 0;
  int seconds = 60;
  int setSeconds = 60;
  Size screenSize = const Size(100, 100);
  bool isPhone = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      recipeID = ModalRoute.of(context)!.settings.arguments as int;
    });
  }

  Future<void> getInstructions() async {
    final instrResponse = await supabase
        .from(recipeSteps)
        .select('step_number, step, recipes(source)')
        .eq('recipe_id', recipeID);

    if (!mounted) return;

    setState(() {
      instr = instrResponse;
    });
    hasData = true;
  }

  @override
  Widget build(BuildContext context) {
    screenSize = MediaQuery.of(context).size;
    if (screenSize.width > 500) {
      isPhone = false;
    } else {
      isPhone = true;
    }
    return FutureBuilder(
        future: getInstructions(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!hasData) {
            return _loadingScreen();
          } else {
            return _cookNowScreen(context);
          }
        });
  }

  Widget _loadingScreen() {
    return const SafeArea(
      child: Center(
        child: SizedBox(
          width: 400,
          height: 200,
          child: Image(
            fit: BoxFit.fill,
            image: AssetImage('assets/logo.jpg'),
          ),
        ),
      ),
    );
  }

  Scaffold _cookNowScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: background, // Main background color for page
      appBar: AppBar(
        // title banner found at the top
        title: const Text('Instructions'),
        centerTitle: true,
        backgroundColor: primaryOrange,
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(basePadding),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              displayAllInstructions
                  ? buildInstructions()
                  : buildInstructionsStepByStep(),
              const SizedBox(height: divHeight),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Center(
                    child: ElevatedButton(
                      onPressed: _launchURL,
                      child: const Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: Text(
                          'Recipe Source',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  )),
                  Expanded(
                      child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (displayAllInstructions) {
                          displayAllInstructions = false;
                        } else {
                          displayAllInstructions = true;
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(basePadding),
                        child: displayAllInstructions
                            ? const Text(
                                "Show Step by Step",
                                style: TextStyle(fontSize: 13),
                              )
                            : const Text(
                                "Show All Steps",
                                style: TextStyle(fontSize: 13),
                              ),
                      ),
                    ),
                  )),
                ],
              ),
              const Padding(
                  padding: EdgeInsets.all(basePadding),
                  child: Center(
                    child: Text(
                      "Timer",
                      style: TextStyle(fontSize: 20, color: primaryOrange),
                    ),
                  )),
              Padding(
                padding: EdgeInsets.all(basePadding),
                child: Center(
                  child: buildTimer(),
                ),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(basePadding),
                    child: Text('Done'),
                  ),
                ),
              )
            ]),
      ),
    );
  }

  ///https://stackoverflow.com/questions/43149055/how-do-i-open-a-web-browser-url-from-my-flutter-code
  _launchURL() async {
    final uri = Uri.parse(instr![0][recipes]['source']);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not reach' + instr![0][recipes]['source']);
    }
  }

  Column buildInstructionsStepByStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        instr!.isEmpty
            ? headerLabel('Step', primaryOrange)
            : headerLabel(
                "Step ${instr![currentStep]['step_number'].toString()}",
                primaryOrange),
        instr!.isEmpty
            ? headerLabel("loading", primaryOrange)
            : headerLabel(instr![currentStep]['step'], white),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            currentStep == 0
                ? const Text("")
                : Center(
                    child: IconButton(
                        onPressed: () {
                          if (currentStep != 0) {
                            currentStep--;
                          }
                        },
                        icon: const Icon(Icons.navigate_before_rounded,
                            color: primaryOrange, size: 35)),
                  ),
            instr!.length - 1 == currentStep
                ? const Text("")
                : Center(
                    child: IconButton(
                        onPressed: () {
                          currentStep++;
                        },
                        icon: const Icon(Icons.navigate_next_rounded,
                            color: primaryOrange, size: 35)),
                  )
          ],
        ),
      ],
    );
  }

  //https://stackoverflow.com/questions/54610121/flutter-countdown-timer
  String formatHHMMSS(int seconds) {
    int hours = (seconds / 3600).truncate();
    seconds = (seconds % 3600).truncate();
    int minutes = (seconds / 60).truncate();

    String hoursStr = (hours).toString().padLeft(2, '0');
    String minutesStr = (minutes).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');

    if (hours == 0) {
      return "$minutesStr:$secondsStr";
    }

    return "$hoursStr:$minutesStr:$secondsStr";
  }

  /// Creates and returns a row that has a Timer Widget.
  Column buildTimer() {
    /// Check to see if timer is currently running
    final isRunning = timer == null ? false : timer!.isActive;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: screenSize.width * 0.35,
          height: screenSize.height * 0.2,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: seconds / setSeconds,
                strokeWidth: 10,
                valueColor: const AlwaysStoppedAnimation(white),
                backgroundColor: Colors.greenAccent,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                      child: Text(
                    formatHHMMSS(seconds),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: white,
                        fontSize: 30),
                  )),
                  !isRunning
                      ? IconButton(
                          onPressed: () {
                            startTimer();
                          },
                          color: primaryOrange,
                          iconSize: 35,
                          icon: const Icon(Icons.not_started))
                      : IconButton(
                          onPressed: () {
                            pauseTimer(reset: false);
                          },
                          color: secondaryOrange,
                          iconSize: 35,
                          icon: const Icon(Icons.pause_circle_filled_outlined)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: divHeight),
        Center(
          child: isRunning
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                        padding: EdgeInsets.all(basePadding),
                        child: ElevatedButton(
                          onPressed: () {
                            pauseTimer(reset: true);
                            setSeconds = 60;
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(basePadding),
                            child: Text('Reset'),
                          ),
                        )),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(basePadding / 2),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          seconds += 10;
                          setSeconds = seconds;
                        },
                        onLongPress: () {
                          seconds += 60;
                          setSeconds = seconds;
                        },
                        label: const Icon(
                          Icons.timer_10_select_rounded,
                        ),
                        icon: const Icon(
                          Icons.add,
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(basePadding / 2),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (seconds - 10 > 0) {
                              seconds -= 10;
                              setSeconds = seconds;
                            }
                          },
                          onLongPress: () {
                            if (seconds - 60 > 0) {
                              seconds -= 60;
                              setSeconds = seconds;
                            }
                          },
                          icon: const Icon(
                            Icons.remove,
                          ),
                          label: const Icon(
                            Icons.timer_10_select_rounded,
                          ),
                        )),
                  ],
                ),
        ),
        Center(
          child: isRunning
              ? Text("")
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(basePadding / 2),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          seconds += 600;
                          setSeconds = seconds;
                        },
                        onLongPress: () {
                          seconds += 1800;
                          setSeconds = seconds;
                        },
                        label: const Text("10 min",
                            style: TextStyle(fontSize: 15)),
                        icon: const Icon(
                          Icons.add,
                        ),
                      ),
                    ),
                    Padding(
                        padding: const EdgeInsets.all(basePadding / 2),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (seconds - 600 > 0) {
                              seconds -= 600;
                              setSeconds = seconds;
                            }
                          },
                          onLongPress: () {
                            if (seconds - 1800 > 0) {
                              seconds -= 1800;
                              setSeconds = seconds;
                            }
                          },
                          icon: const Icon(
                            Icons.remove,
                          ),
                          label: const Text("10 min",
                              style: TextStyle(fontSize: 15)),
                        )),
                  ],
                ),
        )
      ],
    );
  }

  /// Starts the timer countdown.
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (seconds > 0) {
          seconds--;
        } else if (seconds == 0) {
          //pauseTimer(reset: true);
        } else {
          pauseTimer(reset: false);
        }
      });
    });
  }

  /// Stops the timer.
  void pauseTimer({bool reset = true}) {
    if (reset) {
      seconds = 60;
    }
    setState(() => timer?.cancel());
  }

  Widget headerLabel(String name, Color clr) {
    return Padding(
      padding: const EdgeInsets.all(basePadding),
      child: Text(
        name,
        textAlign: TextAlign.left,
        style: TextStyle(fontSize: 20, color: clr),
      ),
    );
  }

  Column buildInstructions() {
    List<Widget> list = [];
    for (var ins in instr!) {
      String stepNumber = ins!['step_number'].toString();
      String step = ins!['step'];
      list.add(headerLabel("Step $stepNumber", primaryOrange));
      list.add(headerLabel(step, white));
    }
    return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: list);
  }
}
