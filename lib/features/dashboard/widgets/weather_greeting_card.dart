import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class WeatherGreetingCard extends StatefulWidget {
  const WeatherGreetingCard({
    super.key,
    required this.displayName,
    required this.primaryColor,
    this.address = '',
  });

  final String displayName;
  final Color primaryColor;
  final String address;

  @override
  State<WeatherGreetingCard> createState() => _WeatherGreetingCardState();
}

class _WeatherGreetingCardState extends State<WeatherGreetingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();
  bool _colonVisible = true;

  // Weather States
  String _tempText = '--°C';
  String _conditionText = 'Đang tải...';
  IconData _weatherIcon = Icons.wb_cloudy_rounded;
  String _cityName = 'Đà Nẵng';

  @override
  void initState() {
    super.initState();
    // 1. Flowing Gradient Animation Controller
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // 2. Dynamic clock timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
          _colonVisible = !_colonVisible;
        });
      }
    });

    // 3. Load Weather Data
    _loadWeather();
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _clockTimer.cancel();
    super.dispose();
  }

  Map<String, dynamic> _getCoords(String address) {
    final addr = address.toLowerCase();
    if (addr.contains('hà nội') || addr.contains('hanoi')) {
      return {'lat': 21.0285, 'lon': 105.8542, 'name': 'Hà Nội'};
    }
    if (addr.contains('hồ chí minh') || addr.contains('hcm') || addr.contains('sài gòn')) {
      return {'lat': 10.8231, 'lon': 106.6297, 'name': 'TP. HCM'};
    }
    if (addr.contains('đà nẵng') || addr.contains('danang')) {
      return {'lat': 16.0544, 'lon': 108.2022, 'name': 'Đà Nẵng'};
    }
    if (addr.contains('nha trang')) {
      return {'lat': 12.2451, 'lon': 109.1943, 'name': 'Nha Trang'};
    }
    if (addr.contains('cần thơ')) {
      return {'lat': 10.0452, 'lon': 105.7469, 'name': 'Cần Thơ'};
    }
    if (addr.contains('hải phòng')) {
      return {'lat': 20.8449, 'lon': 106.6881, 'name': 'Hải Phòng'};
    }
    return {'lat': 21.0285, 'lon': 105.8542, 'name': 'Hà Nội'};
  }

  Future<void> _loadWeather() async {
    final coords = _getCoords(widget.address);
    final lat = coords['lat'];
    final lon = coords['lon'];
    final name = coords['name'];

    try {
      final dio = Dio();
      final response = await dio.get(
        'https://api.open-meteo.com/v1/forecast',
        queryParameters: {
          'latitude': lat,
          'longitude': lon,
          'current_weather': true,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final current = response.data['current_weather'];
        if (current != null) {
          final double temp = (current['temperature'] as num).toDouble();
          final int code = (current['weathercode'] as num).toInt();

          String condition = 'Mát mẻ';
          IconData icon = Icons.wb_cloudy_rounded;

          switch (code) {
            case 0:
              condition = 'Nắng ráo';
              icon = Icons.wb_sunny_rounded;
              break;
            case 1:
            case 2:
            case 3:
              condition = 'Có mây';
              icon = Icons.cloud_queue_rounded;
              break;
            case 45:
            case 48:
              condition = 'Sương mù';
              icon = Icons.filter_drama_rounded;
              break;
            case 51:
            case 53:
            case 55:
              condition = 'Mưa phùn';
              icon = Icons.grain_rounded;
              break;
            case 61:
            case 63:
            case 65:
              condition = 'Mưa rào';
              icon = Icons.umbrella_rounded;
              break;
            case 80:
            case 81:
            case 82:
              condition = 'Mưa giông';
              icon = Icons.thunderstorm_rounded;
              break;
            case 95:
            case 96:
            case 99:
              condition = 'Giông bão';
              icon = Icons.thunderstorm_rounded;
              break;
          }

          if (mounted) {
            setState(() {
              _tempText = '${temp.toStringAsFixed(0)}°C';
              _conditionText = condition;
              _weatherIcon = icon;
              _cityName = name;
            });
          }
          return;
        }
      }
    } catch (_) {
      // Fallback to simulated weather
    }

    if (mounted) {
      setState(() {
        _cityName = name;
        final hour = DateTime.now().hour;
        if (hour >= 18 || hour < 4) {
          _tempText = '27°C';
          _conditionText = 'Trời dịu';
          _weatherIcon = Icons.nights_stay_rounded;
        } else {
          _tempText = '31°C';
          _conditionText = 'Nắng nhẹ';
          _weatherIcon = Icons.wb_sunny_rounded;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour;
    String greeting = 'Chào buổi sáng';

    if (hour >= 18 || hour < 4) {
      greeting = 'Chúc ngủ ngon';
    } else if (hour >= 12) {
      greeting = 'Chào buổi chiều';
    }

    final List<Color> gradientColors = hour >= 18 || hour < 4
        ? [
            const Color(0xFF0F172A),
            const Color(0xFF1E293B),
            widget.primaryColor.withOpacity(0.8),
          ]
        : hour >= 12
            ? [
                widget.primaryColor,
                const Color(0xFF0284C7),
                const Color(0xFF0369A1),
              ]
            : [
                const Color(0xFFF59E0B),
                widget.primaryColor,
                const Color(0xFF0284C7),
              ];

    final hourStr = _now.hour.toString().padLeft(2, '0');
    final minStr = _now.minute.toString().padLeft(2, '0');
    
    final weekdayStr = switch (_now.weekday) {
      1 => 'Thứ Hai',
      2 => 'Thứ Ba',
      3 => 'Thứ Tư',
      4 => 'Thứ Năm',
      5 => 'Thứ Sáu',
      6 => 'Thứ Bảy',
      _ => 'Chủ Nhật',
    };
    final dayMonthStr = '${_now.day.toString().padLeft(2, '0')}/${_now.month.toString().padLeft(2, '0')}';

    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        final xValue = _gradientController.value;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment(xValue - 1.0, -1.0),
              end: Alignment(1.0 - xValue, 1.0),
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        hourStr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: _colonVisible ? 1.0 : 0.2,
                        duration: const Duration(milliseconds: 150),
                        child: const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        minStr,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$weekdayStr, $dayMonthStr',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                width: 1,
                height: 46,
                color: Colors.white.withOpacity(0.18),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _WeatherPulseIcon(
                          icon: _weatherIcon,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_tempText • $_conditionText • $_cityName',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white.withOpacity(0.85),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$greeting,',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeatherPulseIcon extends StatefulWidget {
  const _WeatherPulseIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_WeatherPulseIcon> createState() => _WeatherPulseIconState();
}

class _WeatherPulseIconState extends State<_WeatherPulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Icon(widget.icon, color: widget.color, size: 16),
    );
  }
}
