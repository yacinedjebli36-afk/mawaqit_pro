
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MawaqitApp());
}

class MawaqitApp extends StatelessWidget {
  const MawaqitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مواقيت الصلاة',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF071D19),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD6B36A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  String error = '';
  String location = 'تحديد الموقع...';
  Map<String, DateTime> times = {};

  final List<Map<String, String>> prayers = [
    {'key': 'Fajr', 'name': 'الفجر', 'icon': '🌙'},
    {'key': 'Sunrise', 'name': 'الشروق', 'icon': '🌅'},
    {'key': 'Dhuhr', 'name': 'الظهر', 'icon': '☀️'},
    {'key': 'Asr', 'name': 'العصر', 'icon': '🌤️'},
    {'key': 'Maghrib', 'name': 'المغرب', 'icon': '🌇'},
    {'key': 'Isha', 'name': 'العشاء', 'icon': '🌙'},
  ];

  @override
  void initState() {
    super.initState();
    loadTimes();
  }

  Future<void> loadTimes() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('شغّل GPS في هاتفك');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('اسمح للتطبيق باستخدام موقعك');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final coordinates = Coordinates(
        pos.latitude,
        pos.longitude,
      );

      // طريقة حساب افتراضية: رابطة العالم الإسلامي
      final params =
          CalculationMethod.muslim_world_league.getParameters();

      params.madhab = Madhab.hanafi;

      final result = PrayerTimes.today(
        coordinates,
        params,
      );

      if (!mounted) return;

      setState(() {
        times = {
          'Fajr': result.fajr,
          'Sunrise': result.sunrise,
          'Dhuhr': result.dhuhr,
          'Asr': result.asr,
          'Maghrib': result.maghrib,
          'Isha': result.isha,
        };

        location =
            '${pos.latitude.toStringAsFixed(3)}, '
            '${pos.longitude.toStringAsFixed(3)}';

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  String getNextPrayer() {
    final now = DateTime.now();

    for (final prayer in prayers) {
      if (prayer['key'] == 'Sunrise') continue;

      final time = times[prayer['key']]!;

      if (time.isAfter(now)) {
        return prayer['name']!;
      }
    }

    return 'الفجر';
  }

  String getNextTime() {
    final now = DateTime.now();

    for (final prayer in prayers) {
      if (prayer['key'] == 'Sunrise') continue;

      final time = times[prayer['key']]!;

      if (time.isAfter(now)) {
        final remaining = time.difference(now);
        return '${remaining.inHours} ساعة '
            '${remaining.inMinutes.remainder(60)} دقيقة';
      }
    }

    return 'موعد الفجر غداً';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D3028),
        title: const Text(
          'مواقيت الصلاة',
          style: TextStyle(
            color: Color(0xFFE7C77F),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: loadTimes,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: loadTimes,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadTimes,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF205642),
                              Color(0xFF09251E),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(0xFFD6B36A),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.mosque,
                              size: 65,
                              color: Color(0xFFE7C77F),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              'السلام عليكم',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              DateFormat('dd/MM/yyyy')
                                  .format(DateTime.now()),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              location,
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF174536),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'الصلاة القادمة',
                              style: TextStyle(
                                color: Color(0xFFE7C77F),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              getNextPrayer(),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              getNextTime(),
                              style: const TextStyle(fontSize: 17),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Text(
                        'جدول الصلوات',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 22,
                          color: Color(0xFFE7C77F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      ...prayers.map((prayer) {
                        final time = times[prayer['key']]!;
                        final next = prayer['name'] == getNextPrayer();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: next
                                ? const Color(0xFF245A43)
                                : const Color(0xFF102C24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: next
                                  ? const Color(0xFFD6B36A)
                                  : Colors.white10,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                prayer['icon']!,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  prayer['name']!,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm').format(time),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          'تقبّل الله طاعتكم',
                          style: TextStyle(
                            color: Color(0xFFE7C77F),
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
