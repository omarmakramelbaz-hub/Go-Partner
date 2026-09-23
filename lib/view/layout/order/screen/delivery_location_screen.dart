import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../../helpers/hive/hive_methods.dart';
import '../service/delegate_navigation_service.dart';

class DeliveryLocationArgs {
  final double lat;
  final double lng;
  final String? address;
  final int? orderId;
  final bool navigationMode;

  const DeliveryLocationArgs({
    required this.lat,
    required this.lng,
    this.address,
    this.orderId,
    this.navigationMode = false,
  });
}

class DeliveryLocationScreen extends StatefulWidget {
  static const String routeName = 'DeliveryLocationScreen';
  final DeliveryLocationArgs? args;

  const DeliveryLocationScreen({super.key, this.args});

  @override
  State<DeliveryLocationScreen> createState() => _DeliveryLocationScreenState();
}

class _DeliveryLocationScreenState extends State<DeliveryLocationScreen> {
  static const _orange = Color(0xffFD7201);
  static const _navy = Color(0xFF171A1F);
  static const _softText = Color(0xff7D8490);
  static const _tileUrl =
      'https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png';

  final DelegateNavigationService _navigationService =
      DelegateNavigationService();
  final fmap.MapController _mapController = fmap.MapController();

  StreamSubscription<Position>? _positionSubscription;
  DelegateNavigationRoute? _route;

  double? _currentLat;
  double? _currentLng;
  double _heading = 0;
  double _speedKmh = 0;
  bool _locationLoading = false;
  bool _routeLoading = false;
  bool _arrived = false;
  bool _followMode = true;
  bool _mapReady = false;
  String? _navigationError;
  int _stepIndex = 0;
  DateTime? _lastRouteAttemptAt;
  double? _lastRouteLat;
  double? _lastRouteLng;

  bool get _isArabic => context.locale.languageCode == 'ar';
  bool get _navigationMode => widget.args?.navigationMode == true;
  bool get _hasCurrentLocation => _currentLat != null && _currentLng != null;

  ll.LatLng get _destination {
    final args = widget.args!;
    return ll.LatLng(args.lat, args.lng);
  }

  @override
  void initState() {
    super.initState();

    final savedLat = HiveMethods.getLat();
    final savedLng = HiveMethods.getLan();
    if (savedLat != null && savedLng != null) {
      _currentLat = savedLat;
      _currentLng = savedLng;
    }

    if (_navigationMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_hasCurrentLocation) {
          unawaited(_loadRoute(force: true));
        }
        unawaited(_startNavigationLocation());
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startNavigationLocation() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (mounted) {
      setState(() {
        _locationLoading = !_hasCurrentLocation;
        _navigationError = null;
      });
    }

    try {
      if (!kIsWeb && !await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }

      try {
        final first = await Geolocator.getCurrentPosition().timeout(
          const Duration(seconds: 8),
        );
        await _handlePosition(first, initial: true);
      } catch (e) {
        debugPrint('Fresh navigation GPS unavailable: $e');
        if (!_hasCurrentLocation) rethrow;
        if (_route == null) unawaited(_loadRoute(force: true));
      }

      _startGpsStream();
    } catch (e) {
      debugPrint('Navigation location failed: $e');
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _navigationError = _hasCurrentLocation
            ? (_isArabic
                ? 'يتم استخدام آخر موقع معروف لحين عودة تحديث GPS.'
                : 'Using the last known location until GPS updates resume.')
            : (_isArabic
                ? 'تعذر تحديد موقع المندوب. تأكد من تشغيل GPS والسماح بالموقع.'
                : 'Could not detect driver location. Enable GPS and location permission.');
      });
      if (_hasCurrentLocation && _route == null) {
        unawaited(_loadRoute(force: true));
      }
    }
  }

  void _startGpsStream() {
    final settings = LocationSettings(
      accuracy: kIsWeb ? LocationAccuracy.high : LocationAccuracy.bestForNavigation,
      distanceFilter: kIsWeb ? 10 : 5,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) => unawaited(_handlePosition(position)),
      onError: (Object error) {
        debugPrint('Navigation GPS stream failed: $error');
        if (!mounted) return;
        setState(() {
          _navigationError = _isArabic
              ? 'توقف تحديث GPS مؤقتًا. اضغط زر تحديد الموقع للمحاولة مرة أخرى.'
              : 'GPS updates paused. Tap the locate button to retry.';
        });
      },
    );
  }

  Future<void> _handlePosition(Position position, {bool initial = false}) async {
    if (!mounted) return;

    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : _heading;
    final speed = position.speed.isFinite && position.speed > 0
        ? position.speed * 3.6
        : 0.0;

    setState(() {
      _currentLat = position.latitude;
      _currentLng = position.longitude;
      _heading = heading;
      _speedKmh = speed;
      _locationLoading = false;
      _navigationError = null;
    });

    HiveMethods.updateLat(position.latitude);
    HiveMethods.updateLan(position.longitude);
    _updateArrivalAndStep();

    if (_followMode) {
      _moveToDriver(initial: initial);
    }

    if (!_arrived && _shouldRefreshRoute()) {
      unawaited(_loadRoute(force: _route == null));
    }
  }

  bool _shouldRefreshRoute() {
    if (!_hasCurrentLocation || _routeLoading) return false;
    if (_route == null) {
      final last = _lastRouteAttemptAt;
      return last == null || DateTime.now().difference(last).inSeconds >= 20;
    }

    if (_lastRouteLat == null || _lastRouteLng == null) return true;
    final moved = Geolocator.distanceBetween(
      _lastRouteLat!,
      _lastRouteLng!,
      _currentLat!,
      _currentLng!,
    );
    final elapsed = _lastRouteAttemptAt == null
        ? const Duration(minutes: 2)
        : DateTime.now().difference(_lastRouteAttemptAt!);

    return moved >= 120 && elapsed.inSeconds >= 30;
  }

  Future<void> _loadRoute({bool force = false}) async {
    final args = widget.args;
    if (args == null || !_hasCurrentLocation || _routeLoading || _arrived) return;

    final now = DateTime.now();
    if (!force &&
        _lastRouteAttemptAt != null &&
        now.difference(_lastRouteAttemptAt!).inSeconds < 20) {
      return;
    }

    _lastRouteAttemptAt = now;
    if (mounted) setState(() => _routeLoading = true);

    try {
      final result = await _navigationService.route(
        fromLat: _currentLat!,
        fromLng: _currentLng!,
        toLat: args.lat,
        toLng: args.lng,
      );

      if (!mounted) return;
      setState(() {
        _route = result;
        _routeLoading = false;
        _navigationError = null;
        _lastRouteLat = _currentLat;
        _lastRouteLng = _currentLng;
        _stepIndex = 0;
      });
      _updateArrivalAndStep();
      _showRouteOverview(result);
    } catch (e) {
      debugPrint('Route calculation failed: $e');
      if (!mounted) return;
      setState(() {
        _routeLoading = false;
        _navigationError = _isArabic
            ? 'تعذر حساب الطريق الآن. اضغط هنا لإعادة المحاولة.'
            : 'Could not calculate the route. Tap here to retry.';
      });
    }
  }

  void _showRouteOverview(DelegateNavigationRoute route) {
    if (!_mapReady || !_hasCurrentLocation || !_followMode) return;
    try {
      final args = widget.args!;
      final center = ll.LatLng(
        (_currentLat! + args.lat) / 2,
        (_currentLng! + args.lng) / 2,
      );
      final distance = route.distanceMeters;
      final zoom = distance > 15000
          ? 10.8
          : distance > 8000
              ? 11.8
              : distance > 4000
                  ? 12.7
                  : distance > 2000
                      ? 13.6
                      : distance > 900
                          ? 14.5
                          : 15.5;
      _mapController.move(center, zoom);

      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted && _followMode) _moveToDriver();
      });
    } catch (e) {
      debugPrint('Route overview failed: $e');
    }
  }

  void _moveToDriver({bool initial = false}) {
    if (!_mapReady || !_hasCurrentLocation) return;
    try {
      _mapController.move(
        ll.LatLng(_currentLat!, _currentLng!),
        initial ? 16.0 : 16.5,
      );
    } catch (e) {
      debugPrint('Map follow failed: $e');
    }
  }

  void _updateArrivalAndStep() {
    final args = widget.args;
    if (args == null || !_hasCurrentLocation) return;

    final destinationDistance = Geolocator.distanceBetween(
      _currentLat!,
      _currentLng!,
      args.lat,
      args.lng,
    );

    if (destinationDistance <= 35 && !_arrived) {
      if (mounted) {
        setState(() {
          _arrived = true;
          final count = _route?.steps.length ?? 0;
          _stepIndex = count > 0 ? count - 1 : 0;
        });
      }
      return;
    }

    final steps = _route?.steps ?? const <DelegateNavigationStep>[];
    if (steps.isEmpty || _stepIndex >= steps.length) return;

    var next = _stepIndex;
    while (next < steps.length - 1) {
      final step = steps[next];
      final distance = Geolocator.distanceBetween(
        _currentLat!,
        _currentLng!,
        step.location.latitude,
        step.location.longitude,
      );
      if (distance > 38) break;
      next++;
    }
    if (next != _stepIndex && mounted) setState(() => _stepIndex = next);
  }

  String get _instruction {
    if (_arrived) return _isArabic ? 'وصلت إلى موقع العميل' : 'You reached the customer';
    if (_routeLoading && _route == null) {
      return _isArabic ? 'جارٍ حساب أفضل طريق...' : 'Calculating the best route...';
    }
    final steps = _route?.steps ?? const <DelegateNavigationStep>[];
    if (steps.isEmpty) {
      return _isArabic ? 'اتجه نحو موقع العميل' : 'Head toward the customer';
    }
    final index = _stepIndex.clamp(0, steps.length - 1);
    return steps[index].instruction(isArabic: _isArabic);
  }

  String get _nextStepDistance {
    final steps = _route?.steps ?? const <DelegateNavigationStep>[];
    if (!_hasCurrentLocation || steps.isEmpty) return '';
    final index = _stepIndex.clamp(0, steps.length - 1);
    final point = steps[index].location;
    final distance = Geolocator.distanceBetween(
      _currentLat!,
      _currentLng!,
      point.latitude,
      point.longitude,
    );
    if (distance >= 1000) return '${(distance / 1000).toStringAsFixed(1)} كم';
    return '${distance.round()} م';
  }

  String get _distanceText {
    final distance = _route?.distanceMeters;
    if (distance == null) return '--';
    if (distance >= 1000) return '${(distance / 1000).toStringAsFixed(1)} كم';
    return '${distance.round()} م';
  }

  String get _durationText {
    final seconds = _route?.durationSeconds;
    if (seconds == null) return '--';
    final minutes = (seconds / 60).ceil();
    if (minutes < 60) return _isArabic ? '$minutes دقيقة' : '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return _isArabic ? '$hours س $rest د' : '${hours}h ${rest}m';
  }

  String _destinationText(DeliveryLocationArgs args) {
    final address = args.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    return '${args.lat.toStringAsFixed(6)}, ${args.lng.toStringAsFixed(6)}';
  }

  List<ll.LatLng> get _routePoints {
    final geometry = _route?.geometry ?? const [];
    if (geometry.isEmpty) return const [];
    return geometry
        .map((point) => ll.LatLng(point.latitude, point.longitude))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    if (args == null) {
      return const Scaffold(
        body: Center(
          child: Icon(Icons.location_off_rounded, color: _softText, size: 50),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: Icon(
            _isArabic ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
            color: _orange,
          ),
        ),
        title: Text(
          _navigationMode
              ? (_isArabic ? 'الملاحة إلى الوجهة' : 'Navigation')
              : (_isArabic ? 'موقع التسليم' : 'Delivery location'),
          style: const TextStyle(
            color: _navy,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _map(args)),
          if (_navigationMode)
            PositionedDirectional(
              top: 14,
              start: 14,
              end: 14,
              child: _instructionCard(),
            ),
          PositionedDirectional(
            end: 16,
            bottom: _navigationMode ? 154 : 96,
            child: _recenterButton(),
          ),
          if (_navigationError != null)
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: _navigationMode ? 154 : 20,
              child: _errorCard(),
            ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: _navigationMode
                ? _navigationBottomCard(args)
                : _destinationInfoCard(args),
          ),
        ],
      ),
    );
  }

  Widget _map(DeliveryLocationArgs args) {
    final initialCenter = _hasCurrentLocation && _navigationMode
        ? ll.LatLng(_currentLat!, _currentLng!)
        : _destination;

    final markers = <fmap.Marker>[
      fmap.Marker(
        point: _destination,
        width: 52,
        height: 62,
        child: const _DestinationMarker(),
      ),
    ];

    if (_hasCurrentLocation && _navigationMode) {
      markers.add(
        fmap.Marker(
          point: ll.LatLng(_currentLat!, _currentLng!),
          width: 74,
          height: 88,
          child: _DriverMarker(heading: _heading),
        ),
      );
    }

    return fmap.FlutterMap(
      mapController: _mapController,
      options: fmap.MapOptions(
        initialCenter: initialCenter,
        initialZoom: _navigationMode ? 15.8 : 16.2,
        minZoom: 4,
        maxZoom: 19,
        onMapReady: () {
          _mapReady = true;
          if (_navigationMode && _hasCurrentLocation) {
            _moveToDriver(initial: true);
          }
        },
      ),
      children: [
        fmap.TileLayer(
          urlTemplate: _tileUrl,
          userAgentPackageName: 'com.fasakhansta.delegate',
          maxNativeZoom: 19,
        ),
        if (_routePoints.length >= 2)
          fmap.PolylineLayer(
            polylines: [
              fmap.Polyline(
                points: _routePoints,
                strokeWidth: 7,
                color: _orange.withOpacity(.96),
                borderStrokeWidth: 2.5,
                borderColor: Colors.white.withOpacity(.92),
              ),
            ],
          ),
        fmap.MarkerLayer(markers: markers),
        PositionedDirectional(
          start: 8,
          bottom: _navigationMode ? 132 : 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.88),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Text(
              '© OpenStreetMap © CARTO',
              style: TextStyle(
                color: Color(0xff606873),
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _instructionCard() {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.97),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _orange.withOpacity(.22)),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.10),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _orange.withOpacity(.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _arrived ? Icons.flag_rounded : Icons.navigation_rounded,
                color: _orange,
                size: 29,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _instruction,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (_nextStepDistance.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _nextStepDistance,
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_routeLoading || _locationLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _recenterButton() {
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() => _followMode = true);
          if (_hasCurrentLocation) {
            _moveToDriver(initial: true);
          } else {
            unawaited(_startNavigationLocation());
          }
        },
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.my_location_rounded, color: _orange, size: 26),
        ),
      ),
    );
  }

  Widget _navigationBottomCard(DeliveryLocationArgs args) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _stat(Icons.route_rounded, _distanceText),
                const SizedBox(width: 8),
                _stat(Icons.schedule_rounded, _durationText),
                const SizedBox(width: 8),
                _stat(Icons.speed_rounded, '${_speedKmh.round()} كم/س'),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF0E3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _orange,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _destinationText(args),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (args.orderId != null)
                  Container(
                    margin: const EdgeInsetsDirectional.only(start: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${args.orderId}',
                      style: const TextStyle(
                        color: _orange,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(IconData icon, String value) {
    return Expanded(
      child: Container(
        height: 43,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: const Color(0xffF8F9FB),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xffECEEF1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _orange, size: 16),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinationInfoCard(DeliveryLocationArgs args) {
    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffECEEF1)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xffFFF0E3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.location_on_rounded, color: _orange),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isArabic ? 'نقطة التسليم' : 'Delivery point',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _destinationText(args),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _softText,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return GestureDetector(
      onTap: () {
        if (_hasCurrentLocation && !_routeLoading) {
          unawaited(_loadRoute(force: true));
        } else if (!_hasCurrentLocation) {
          unawaited(_startNavigationLocation());
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xF9FFF4EA),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _orange.withOpacity(.32)),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: _orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _navigationError!,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 11.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xffFD7201),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33082A4D),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(Icons.flag_rounded, color: Colors.white, size: 23),
      ),
    );
  }
}

class _DriverMarker extends StatelessWidget {
  final double heading;

  const _DriverMarker({required this.heading});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: const Color(0x24FD7201),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x55FD7201), width: 2),
            ),
          ),
          Transform.rotate(
            angle: heading * math.pi / 180,
            child: Image.asset(
              'assets/images/go_motorcycle_marker.png',
              width: 52,
              height: 68,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ],
      ),
    );
  }
}
