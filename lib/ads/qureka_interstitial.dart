import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/remote_config_service.dart';

const bool ENABLE_THIRD_PARTY_ADS = true;

// TODO: Add the following images to assets/images/ folder:
const String inter = 'assets/images/third_image_ads.jpg';

bool isAtme = false;
bool isgameZop = false;

class QurekaInterstitial extends StatefulWidget {
  final Widget? nextpage;
  
  const QurekaInterstitial(this.nextpage, {Key? key}) : super(key: key);

  @override
  State<QurekaInterstitial> createState() => _QurekaInterstitialState();
}

class _QurekaInterstitialState extends State<QurekaInterstitial> {
  double progres = 0.0;
  int check = 0;
  bool isclose = false;
  int interint = 1;
  Timer? _timer;
  
  int currentAdIndex = 0;
  String currentAdUrl = '';

  @override
  void initState() {
    super.initState();
    progres = 0.0;
    check = 0;
    setState(() {
      interint = 0;
      currentAdIndex = 0;
      
      if (currentAdIndex == 0) {
        isAtme = true;
        isgameZop = false;
        currentAdUrl = RemoteConfigService.instance.thirdPartyInterstitialAdUrl1;
      }
    });
    
    debugPrint('🎯 Third-party ad selected: ${currentAdIndex + 1}, URL: $currentAdUrl');
    startlosding();
  }

  void startlosding() {
    const onesec = Duration(seconds: 1);
    _timer = Timer.periodic(onesec, (Timer t) {
      setState(() {
        progres = progres + 1.0;
        check = check + 1;
        
        if (check == 3) {
          setState(() {
            isclose = true;
          });
          t.cancel();
          return;
        }
      });
    });
  }

  Future<void> launchgraphic() async {
    try {
      final Uri url = Uri.parse(currentAdUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            alignment: Alignment.topRight,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {
                    launchgraphic();
                  },
                  child: Container(
                    height: double.infinity,
                    width: double.infinity,
                    child: isAtme == true
                        ? Image.asset(inter, fit: BoxFit.fill)
                        : isgameZop == true
                            ? Image.asset(inter, fit: BoxFit.fill)
                            : Image.asset(inter, fit: BoxFit.fill),
                  ),
                ),
              ),
              isclose
                  ? GestureDetector(
                      onTap: () {
                        // launchgraphic();
                        // Close the ad screen using go_router
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.black, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.close_sharp,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 10, top: 10),
                      child: Text(
                        'Skip ${check == 1 ? 3 : check == 2 ? 2 : check == 3 ? 1 : 3}',
                        style: const TextStyle(fontSize: 20),
                      ),
                    )
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show Qureka interstitial ad
/// This will only show if:
/// 1. ENABLE_THIRD_PARTY_ADS hardcoded flag is true
/// 2. Remote Config 'show_third_party_interstitial_ads' is true
Future<void> showQurekaInterstitialAd(BuildContext context, {Widget? nextPage}) async {
  // Check hardcoded flag
  if (!ENABLE_THIRD_PARTY_ADS) {
    debugPrint('🚫 Third-party ads disabled via ENABLE_THIRD_PARTY_ADS flag');
    return;
  }

  // Check Remote Config flag
  if (!RemoteConfigService.instance.showThirdPartyInterstitialAds) {
    debugPrint('🚫 Third-party ads disabled via Remote Config');
    return;
  }

  debugPrint('✅ Showing third-party interstitial ad');
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => QurekaInterstitial(nextPage),
    ),
  );
}
