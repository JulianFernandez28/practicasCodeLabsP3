// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
import 'package:admob_ads_influtter/add_helper.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:admob_ads_influtter/drawing.dart';
import 'package:admob_ads_influtter/app_theme.dart';
import 'package:admob_ads_influtter/drawing_painter.dart';
import 'package:admob_ads_influtter/quiz_manager.dart';
import 'package:flutter/material.dart';

class GameRoute extends StatefulWidget {
  const GameRoute({super.key});

  @override
  State<GameRoute> createState() => _GameRouteState();
}

class _GameRouteState extends State<GameRoute> implements QuizEventListener {
  BannerAd? _bannerAd;

   InterstitialAd? _interstitialAd;

  RewardedAd? _rewardedAd;

  @override
  void initState() {
    super.initState();

    QuizManager.instance
      ..listener = this
      ..startGame();

    // TODO: Load a banner ad
    BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              _bannerAd = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, error) {
            print('Failed to load banner ad: ${error.message}');
          },
        )).load();

    _loadRewardedAd();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Level ${QuizManager.instance.currentLevel}/5',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32.0),
                      ),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          var answer = '';

                          return AlertDialog(
                            title: const Text('Enter your answer'),
                            content: TextField(
                              autofocus: true,
                              onChanged: (value) {
                                answer = value;
                              },
                            ),
                            actions: [
                              TextButton(
                                child: Text('submit'.toUpperCase()),
                                onPressed: () {
                                  Navigator.pop(context);
                                  QuizManager.instance.checkAnswer(answer);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Text(
                        QuizManager.instance.clue,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    margin: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24.0),
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: DrawingPainter(
                              drawing: QuizManager.instance.drawing,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TODO: Display a banner when ready
            if (_bannerAd != null)
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: ButtonBar(
          alignment: MainAxisAlignment.start,
          children: [
            TextButton(
              child: Text('Skip this level'.toUpperCase()),
              onPressed: () {
                QuizManager.instance.nextLevel();
              },
            )
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // TODO: Return a FloatingActionButton if a Rewarded Ad is available
    return (!QuizManager.instance.isHintUsed && _rewardedAd != null)
      ? FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Need a hint?'),
                  content: Text('Watch an Ad to get a hint!'),
                  actions: [
                    TextButton(
                      child: Text('cancel'.toUpperCase()),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text('ok'.toUpperCase()),
                      onPressed: () {
                        Navigator.pop(context);
                        _rewardedAd?.show(
                          onUserEarnedReward: (_, reward) {
                            QuizManager.instance.useHint();
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
          label: Text('Hint'),
          icon: Icon(Icons.card_giftcard),
        )
    :null;
  }

  void _moveToHome() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _moveToHome();
            },
          );

          setState(() {
            _interstitialAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              setState(() {
                ad.dispose();
                _rewardedAd = null;
              });
              _loadRewardedAd();
            },
          );

          setState(() {
            _rewardedAd = ad;
          });
        },
        onAdFailedToLoad: (err) {
          print('Failed to load a rewarded ad: ${err.message}');
        },
      ),
    );
  }
  

  @override
  void dispose() {

    _bannerAd?.dispose();

    _interstitialAd?.dispose();

    _rewardedAd?.dispose();

    QuizManager.instance.listener = null;

    super.dispose();
  }

  @override
  void onWrongAnswer() {
    _showSnackBar('Wrong answer!');
  }

  @override
  void onNewLevel(int level, Drawing drawing, String clue) {
    setState(() {});

    // TODO: Load an Interstitial Ad
    if (level >= 3 && _interstitialAd == null) {
    _loadInterstitialAd();
  }
  }

  @override
  void onLevelCleared() {
    _showSnackBar('Good job!');
  }

  @override
  void onGameOver(int correctAnswers) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game over!'),
          content: Text('Score: $correctAnswers/5'),
          actions: [
            TextButton(
              child: Text('close'.toUpperCase()),
              onPressed: () {
                if (_interstitialAd != null) {
                _interstitialAd?.show();
              } else {
                _moveToHome();
              }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void onClueUpdated(String clue) {
    setState(() {});

    _showSnackBar('You\'ve got one more clue!');
  }
}
