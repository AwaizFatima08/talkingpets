import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ads/ads_service.dart';
import 'core/audio.dart';
import 'core/pets.dart';
import 'core/settings.dart';
import 'screens/intro_screen.dart';
import 'screens/play_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Full screen, so little fingers don't hit the system bars.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Settings.load();
  await PetAudio.instance.init(allSfxNames());
  runApp(const TalkyPalsApp());
  // Ads start after the first frame so play is never blocked on the network.
  WidgetsBinding.instance.addPostFrameCallback((_) => AdsService.instance.init());
}

class TalkyPalsApp extends StatelessWidget {
  const TalkyPalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalkyPals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF7A3D)),
        useMaterial3: true,
        fontFamily: 'Quicksand',
      ),
      home: Settings.instance.introSeen ? const PlayScreen() : const IntroScreen(),
    );
  }
}
