import 'dart:collection';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:highlight_text/highlight_text.dart';

void main() {
  runApp(MyApp());
}

bool isListening = false;

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FluVoice',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: SpeechScreen(),
    );
  }
}

class SpeechScreen extends StatefulWidget {
  SpeechScreen();

  @override
  _SpeechScreenState createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  LinkedHashMap<String, HighlightedWord> highlightedWords = LinkedHashMap();

  late stt.SpeechToText speech;
  String promptText = "Press the button to start speaking";
  String speechText = '';
  double confidence = 1.0;

  @override
  void initState() {
    super.initState();
    setState(() {
      speech = stt.SpeechToText();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AvatarGlow(
              endRadius: 75,
              animate: isListening,
              glowColor: Colors.red,
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                ),
                onPressed: listenToSpeech,
              ),
            ),
            SizedBox(width: 5),
            FloatingActionButton(
              elevation: speechText.isNotEmpty ? 6 : 1,
              backgroundColor: speechText.isNotEmpty ? Colors.red : Colors.black12,
              child: Icon(Icons.copy_rounded),
              onPressed: textHighLight,
            )
          ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Center(
                child: Text(
              "Confidence level ${(confidence * 100).toStringAsFixed(1)}%",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            )),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SingleChildScrollView(
                reverse: false,
                padding: EdgeInsets.all(30),
                child: Text(promptText,
                    style: TextStyle(
                        fontSize: 32,
                        color: Colors.black,
                        fontWeight: FontWeight.w400)),
                // child: TextHighlight(
                //   text: _promptText,
                //   words: highlightedWords,
                //   textStyle: TextStyle(
                //       fontSize: 32,
                //       color: Colors.black,
                //       fontWeight: FontWeight.w400),
                // ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void textHighLight(){
    if(speechText.isNotEmpty){
      FlutterClipboard.copy(speechText);
    }
  }

  void listenToSpeech() async {
    if (!isListening) {
      bool available = await speech.initialize(
        onStatus: (val) {
          if(val.contains("notListening")){
            setState(() => isListening = false);
          }
          print('onStatus: $val');
        },
        onError: (val){
          setState(() => isListening = false);
          print('onError: $val');
        },
      );
      if (available) {
        setState(() => isListening = true);
        speech.listen(
          onResult: (val) => setState(() {
            promptText = val.recognizedWords;
            speechText = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => isListening = false);
      speech.stop();
    }
  }
}
