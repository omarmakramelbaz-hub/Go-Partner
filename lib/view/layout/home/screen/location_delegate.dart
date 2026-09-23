import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:provider/provider.dart';

import '../../../../helpers/hive/hive_methods.dart';
import '../../../../helpers/locale/app_locale_key.dart';
import '../../../../helpers/utils/common_methods.dart';
import '../../../../helpers/utils/navigator_methods.dart';
import '../../../custom_widgets/buttons/custom_button.dart';
import '../../auth/controller/auth_controller.dart';
import '../../delegate_bottom_nav_bar.dart/screen/delegate_bottom_nav_bar_screen.dart';
import '../../order/screen/delivery_location_screen.dart';
import '../service/delegate_address_search_service.dart';

class DelegateLocationScreen extends StatefulWidget {
  static const String routeName = 'DelegateLocationScreen';
  const DelegateLocationScreen({super.key});

  @override
  State<DelegateLocationScreen> createState() => _DelegateLocationScreenState();
}

class _DelegateLocationScreenState extends State<DelegateLocationScreen> {
  static const _navy = Color(0xFF171A1F);
  static const _orange = Color(0xffFD7201);
  static const _softText = Color(0xff7D8490);
  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _bikeAsset = 'assets/images/go_motorcycle_marker.png';
  static const _bikeImageId = 'go-motorcycle';

  final List<Placemark> _placemarks = [];
  final DelegateAddressSearchService _searchService =
      DelegateAddressSearchService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  MapLibreMapController? _mapController;
  Symbol? _bike;
  Circle? _pulse;
  Circle? _destinationMarker;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _searchDebounce;

  double? _lat;
  double? _lng;
  double? _accuracy;
  double _heading = 0;
  double _speedKmh = 0;
  String? _address;
  String? _locationError;
  bool _isLocating = true;
  bool _isLive = false;
  bool _styleReady = false;
  bool _showBikeCard = false;
  bool _isResolvingAddress = false;
  bool _followBikeEnabled = true;
  bool _searchLoading = false;
  String? _searchError;
  List<DelegateAddressSearchResult> _searchResults = const [];
  DelegateAddressSearchResult? _selectedDestination;
  DateTime? _lastAddressAt;
  double? _lastAddressLat;
  double? _lastAddressLng;

  bool get _isArabic => context.locale.languageCode == 'ar';
  bool get _hasLocation => _lat != null && _lng != null;
  bool get _hasDestination => _selectedDestination != null;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _positionSubscription?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(MapLibreMapController controller) async {
    _mapController = controller;
    controller.onSymbolTapped.add((symbol) {
      if (symbol.id == _bike?.id && mounted) {
        setState(() => _showBikeCard = !_showBikeCard);
      }
    });
  }

  Future<void> _onStyleLoaded() async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      final data = await rootBundle.load(_bikeAsset);
      final bytes = Uint8List.sublistView(data);
      await controller.addImage(_bikeImageId, bytes);
      _styleReady = true;
      await _syncBike();
      await _syncDestinationMarker();
      if (_selectedDestination != null) {
        await _focusDestination(_selectedDestination!);
      } else {
        await _followBike(initial: true);
      }
    } catch (e) {
      log('MapLibre style setup failed: $e');
      if (mounted) {
        setState(() {
          _locationError = _isArabic
              ? 'تعذر تحميل عناصر الخريطة.'
              : 'Could not load map elements.';
        });
      }
    }
  }

  Future<void> _syncBike() async {
    final controller = _mapController;
    if (!_styleReady || controller == null || !_hasLocation) return;

    final point = LatLng(_lat!, _lng!);
    try {
      if (_pulse == null) {
        _pulse = await controller.addCircle(
          CircleOptions(
            geometry: point,
            circleRadius: 24,
            circleColor: '#FD7201',
            circleOpacity: .14,
            circleStrokeColor: '#FF9B46',
            circleStrokeWidth: 2,
            circleStrokeOpacity: .35,
          ),
        );
      } else {
        await controller.updateCircle(_pulse!, CircleOptions(geometry: point));
      }

      if (_bike == null) {
        _bike = await controller.addSymbol(
          SymbolOptions(
            geometry: point,
            iconImage: _bikeImageId,
            iconSize: .62,
            iconRotate: _heading,
            iconAnchor: 'center',
            zIndex: 20,
          ),
          {'type': 'delegate', 'live': true},
        );
      } else {
        await controller.updateSymbol(
          _bike!,
          SymbolOptions(geometry: point, iconRotate: _heading),
        );
      }
    } catch (e) {
      log('MapLibre annotation update failed: $e');
    }
  }

  Future<void> _syncDestinationMarker() async {
    final controller = _mapController;
    final destination = _selectedDestination;
    if (!_styleReady || controller == null) return;

    try {
      if (_destinationMarker != null) {
        await controller.removeCircle(_destinationMarker!);
        _destinationMarker = null;
      }
      if (destination == null) return;

      _destinationMarker = await controller.addCircle(
        CircleOptions(
          geometry: LatLng(destination.lat, destination.lng),
          circleRadius: 13,
          circleColor: '#FD7201',
          circleOpacity: .98,
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 4,
          circleStrokeOpacity: 1,
        ),
      );
    } catch (e) {
      log('Destination marker update failed: $e');
    }
  }

  Future<void> _followBike({bool initial = false}) async {
    final controller = _mapController;
    if (!_styleReady || controller == null || !_hasLocation) return;
    if (!_followBikeEnabled && !initial) return;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_lat!, _lng!),
            zoom: initial ? 17.3 : 17.0,
            tilt: 46,
            bearing: _heading,
          ),
        ),
        duration: const Duration(milliseconds: 650),
      );
    } catch (e) {
      log('MapLibre camera follow failed: $e');
    }
  }

  Future<void> _focusDestination(DelegateAddressSearchResult destination) async {
    final controller = _mapController;
    if (!_styleReady || controller == null) return;
    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(destination.lat, destination.lng),
            zoom: 16.7,
            tilt: 38,
            bearing: 0,
          ),
        ),
        duration: const Duration(milliseconds: 650),
      );
    } catch (e) {
      log('Destination camera focus failed: $e');
    }
  }

  Future<void> _determinePosition() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (mounted) {
      setState(() {
        _isLocating = true;
        _isLive = false;
        _locationError = null;
        _followBikeEnabled = true;
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
        throw Exception('Location permission is denied');
      }

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 15),
      );
      await _handlePosition(position, forceCamera: true, forceAddress: true);
      _startLiveTracking();
    } catch (e) {
      log('Failed to start live location: $e');
      final savedLat = HiveMethods.getLat();
      final savedLng = HiveMethods.getLan();

      if (savedLat != null && savedLng != null) {
        await _applyFallbackLocation(savedLat, savedLng);
        if (mounted) {
          setState(() {
            _locationError = _isArabic
                ? 'تعذر تشغيل التتبع المباشر. يتم عرض آخر موقع محفوظ.'
                : 'Live tracking could not start. Showing the last saved location.';
          });
        }
      } else if (mounted) {
        setState(() {
          _isLocating = false;
          _locationError = _isArabic
              ? 'تعذر تحديد موقعك. فعّل إذن الموقع ثم حاول مرة أخرى.'
              : 'Could not detect your location. Enable location permission and retry.';
        });
      }
    }
  }

  void _startLiveTracking() {
    _positionSubscription?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) => _handlePosition(position),
      onError: (Object error) {
        log('Live location stream error: $error');
        if (!mounted) return;
        setState(() {
          _isLive = false;
          _isLocating = false;
          _locationError = _isArabic
              ? 'توقف التتبع المباشر مؤقتاً. اضغط زر الموقع لإعادة تشغيله.'
              : 'Live tracking paused. Tap the location button to restart it.';
        });
      },
    );

    if (mounted) {
      setState(() {
        _isLive = true;
        _isLocating = false;
      });
    }
  }

  Future<void> _handlePosition(
    Position position, {
    bool forceCamera = false,
    bool forceAddress = false,
  }) async {
    if (!mounted) return;

    final heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : _heading;
    final speed = position.speed.isFinite && position.speed > 0
        ? position.speed * 3.6
        : 0.0;

    setState(() {
      _lat = position.latitude;
      _lng = position.longitude;
      _heading = heading;
      _speedKmh = speed;
      _accuracy = position.accuracy;
      _isLocating = false;
      _isLive = true;
      _locationError = null;
    });

    HiveMethods.updateLat(position.latitude);
    HiveMethods.updateLan(position.longitude);

    await _syncBike();
    if (_followBikeEnabled || forceCamera) {
      await _followBike(initial: forceCamera);
    }
    await _resolveAddressIfNeeded(
      position.latitude,
      position.longitude,
      force: forceAddress,
    );
  }

  Future<void> _applyFallbackLocation(double lat, double lng) async {
    if (!mounted) return;
    setState(() {
      _lat = lat;
      _lng = lng;
      _accuracy = null;
      _speedKmh = 0;
      _isLocating = false;
      _isLive = false;
    });
    await _syncBike();
    await _followBike(initial: true);
    await _resolveAddressIfNeeded(lat, lng, force: true);
  }

  Future<void> _resolveAddressIfNeeded(
    double lat,
    double lng, {
    bool force = false,
  }) async {
    if (_isResolvingAddress) return;

    final now = DateTime.now();
    final elapsed = _lastAddressAt == null
        ? const Duration(days: 1)
        : now.difference(_lastAddressAt!);
    final moved = _lastAddressLat == null || _lastAddressLng == null
        ? double.infinity
        : Geolocator.distanceBetween(
            _lastAddressLat!,
            _lastAddressLng!,
            lat,
            lng,
          );

    if (!force && elapsed < const Duration(seconds: 15) && moved < 35) return;

    _lastAddressAt = now;
    _lastAddressLat = lat;
    _lastAddressLng = lng;
    await _resolveAddress(lat, lng);
  }

  Future<void> _resolveAddress(double lat, double lng) async {
    final coordinates = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _placemarks.clear();
        _address = _isLive
            ? (_isArabic ? 'موقع المندوب الحالي' : 'Current delegate location')
            : coordinates;
      });
      return;
    }

    _isResolvingAddress = true;
    try {
      final result = await placemarkFromCoordinates(lat, lng);
      if (!mounted) return;
      final first = result.isNotEmpty ? result.first : null;
      final parts = <String>[
        first?.street ?? '',
        first?.subLocality ?? '',
        first?.locality ?? '',
      ].where((e) => e.trim().isNotEmpty).toList();

      setState(() {
        _placemarks
          ..clear()
          ..addAll(result);
        _address = parts.isEmpty ? coordinates : parts.join('، ');
      });
    } catch (e) {
      log('Reverse geocoding failed: $e');
      if (mounted) setState(() => _address = coordinates);
    } finally {
      _isResolvingAddress = false;
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final query = value.trim();

    if (_selectedDestination != null &&
        query != _selectedDestination!.fullAddress) {
      _clearDestination(clearText: false);
    }

    if (query.length < 2) {
      if (mounted) {
        setState(() {
          _searchResults = const [];
          _searchLoading = false;
          _searchError = null;
        });
      }
      return;
    }

    _searchDebounce = Timer(
      const Duration(milliseconds: 700),
      () => _performSearch(query),
    );
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });

    try {
      final results = await _searchService.search(query, isArabic: _isArabic);
      if (!mounted || _searchController.text.trim() != query) return;
      setState(() {
        _searchResults = results;
        _searchLoading = false;
        _searchError = results.isEmpty
            ? (_isArabic ? 'لم يتم العثور على نتائج' : 'No addresses found')
            : null;
      });
    } catch (e) {
      log('Address search failed: $e');
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
        _searchResults = const [];
        _searchError = _isArabic
            ? 'تعذر البحث الآن. حاول مرة أخرى.'
            : 'Search is unavailable right now. Try again.';
      });
    }
  }

  Future<void> _selectDestination(DelegateAddressSearchResult result) async {
    _searchDebounce?.cancel();
    _searchFocus.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    setState(() {
      _selectedDestination = result;
      _searchController.text = result.fullAddress;
      _searchResults = const [];
      _searchError = null;
      _searchLoading = false;
      _followBikeEnabled = false;
    });

    await _syncDestinationMarker();
    await _focusDestination(result);
  }

  Future<void> _clearDestination({bool clearText = true}) async {
    final controller = _mapController;
    if (mounted) {
      setState(() {
        _selectedDestination = null;
        _searchResults = const [];
        _searchError = null;
        _followBikeEnabled = true;
        if (clearText) _searchController.clear();
      });
    }

    try {
      if (controller != null && _destinationMarker != null) {
        await controller.removeCircle(_destinationMarker!);
      }
    } catch (_) {}
    _destinationMarker = null;
    await _followBike(initial: true);
  }

  void _startDestinationNavigation() {
    final destination = _selectedDestination;
    if (destination == null) return;

    NavigatorMethods.pushNamed(
      context,
      DeliveryLocationScreen.routeName,
      arguments: DeliveryLocationArgs(
        lat: destination.lat,
        lng: destination.lng,
        address: destination.fullAddress,
        navigationMode: true,
      ),
    );
  }

  void _confirm(BuildContext context) {
    if (!_hasLocation) {
      CommonMethods.showError(
        message: _isArabic
            ? 'انتظر حتى يتم تحديد موقعك أولاً'
            : 'Wait until your location is detected first',
      );
      return;
    }

    context.read<AuthController>().updateDelegateLocation(
      lat: _lat!,
      lng: _lng!,
      onSuccess: () {
        HiveMethods.updateLan(_lng!);
        HiveMethods.updateLat(_lat!);
        context.read<AuthController>().getProfile();

        final p = _placemarks.isNotEmpty ? _placemarks.first : null;
        final area = p?.locality ??
            p?.subLocality ??
            p?.administrativeArea ??
            _address ??
            '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}';
        HiveMethods.delegateAddress(area);

        NavigatorMethods.pushNamedAndRemoveUntil(
          context,
          DelegateBottomNavBarScreen.routeName,
        );
      },
    );
  }

  String get _coordinates =>
      _hasLocation ? '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}' : '--';

  String get _accuracyText {
    if (!_isLive || _accuracy == null) {
      return _isArabic ? 'آخر موقع محفوظ' : 'Saved location';
    }
    return _isArabic
        ? 'دقة GPS ±${_accuracy!.round()} م'
        : 'GPS ±${_accuracy!.round()}m';
  }

  @override
  Widget build(BuildContext context) {
    final mapHeight =
        (MediaQuery.sizeOf(context).height * .43).clamp(350.0, 500.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 130),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 14),
                  _liveCard(),
                  const SizedBox(height: 12),
                  _searchCard(),
                  const SizedBox(height: 12),
                  _mapCard(mapHeight),
                  const SizedBox(height: 14),
                  _hasDestination ? _destinationCard() : _locationCard(),
                  if (_locationError != null) ...[
                    const SizedBox(height: 12),
                    _warningCard(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: CustomButton(
            height: 60,
            radius: 20,
            hasShadow: true,
            text: _hasDestination
                ? (_isArabic ? 'ابدأ الملاحة' : 'Start navigation')
                : AppLocaleKey.confirm.tr(),
            gradient: const LinearGradient(
              colors: [Color(0xffFF8A08), Color(0xffFF6500)],
            ),
            prefixIcon: Icon(
              _hasDestination
                  ? Icons.navigation_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
            onPressed: _hasDestination
                ? _startDestinationNavigation
                : (_hasLocation ? () => _confirm(context) : null),
          ),
        ),
      ),
    );
  }

  Widget _header() => _card(
        child: Row(
          children: [
            InkWell(
              onTap: () => Navigator.maybePop(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 48,
                height: 48,
                decoration: _iconBox(),
                child: Icon(
                  _isArabic
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  color: _orange,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocaleKey.location.tr(),
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isArabic
                        ? 'حدد موقعك أو ابحث عن وجهة للبدء'
                        : 'Confirm your location or search for a destination',
                    style: const TextStyle(
                      color: _softText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.location_on_outlined, color: _orange, size: 26),
          ],
        ),
      );

  Widget _liveCard() => _card(
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFF9A17), Color(0xffFF6500)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'موقعك الحالي مباشر' : 'Your live location',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isArabic
                        ? 'الموتوسيكل يتحرك ويلف مع موقع واتجاه المندوب الحقيقي.'
                        : 'The motorcycle follows the delegate GPS and heading.',
                    style: const TextStyle(
                      color: _softText,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            _badge(),
          ],
        ),
      );

  Widget _searchCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _searchFocus.hasFocus
                ? const Color(0xffFFB16B)
                : const Color(0xffE8EAEE),
          ),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.055),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          children: [
            Focus(
              onFocusChange: (_) {
                if (mounted) setState(() {});
              },
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  _searchDebounce?.cancel();
                  if (value.trim().length >= 2) _performSearch(value.trim());
                },
                style: const TextStyle(
                  color: _navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: _isArabic
                      ? 'ابحث عن شارع، منطقة أو عنوان...'
                      : 'Search street, area or address...',
                  hintStyle: const TextStyle(
                    color: Color(0xff9AA0AA),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: _orange),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => _clearDestination(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xff8B919B),
                          ),
                        ),
                  filled: true,
                  fillColor: const Color(0xffF8F9FB),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xffFFC28C),
                      width: 1.1,
                    ),
                  ),
                ),
              ),
            ),
            if (_searchLoading) ...[
              const SizedBox(height: 9),
              const LinearProgressIndicator(
                color: _orange,
                backgroundColor: Color(0xffFFF0E3),
                minHeight: 2,
              ),
            ],
            if (_searchError != null && !_searchLoading) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: _orange, size: 17),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _searchError!,
                      style: const TextStyle(
                        color: _softText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (_searchResults.isNotEmpty) ...[
              const SizedBox(height: 7),
              Container(
                constraints: const BoxConstraints(maxHeight: 270),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xffECEEF1)),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 48,
                    color: Color(0xffF0F1F3),
                  ),
                  itemBuilder: (context, index) {
                    final result = _searchResults[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectDestination(result),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xffFFF1E5),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  color: _orange,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      result.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _navy,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (result.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        result.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _softText,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Color(0xffA6ABB3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      );

  Widget _mapCard(double height) => Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: MapLibreMap(
                styleString: _styleUrl,
                initialCameraPosition: CameraPosition(
                  target: LatLng(_lat ?? 31.043867, _lng ?? 31.388388),
                  zoom: 15.7,
                  tilt: 42,
                ),
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoaded,
                compassEnabled: false,
                myLocationEnabled: false,
                trackCameraPosition: true,
              ),
            ),
            PositionedDirectional(
              top: 14,
              start: 14,
              end: 14,
              child: Center(
                child: _glass(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasDestination
                            ? Icons.flag_rounded
                            : Icons.wifi_tethering_rounded,
                        color: _hasDestination
                            ? _orange
                            : const Color(0xff319B63),
                        size: 17,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _hasDestination
                            ? (_isArabic ? 'الوجهة جاهزة للملاحة' : 'Destination ready')
                            : (_isArabic
                                ? 'تتبع مباشر لموقع المندوب'
                                : 'Live delegate tracking'),
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_showBikeCard && _hasLocation)
              PositionedDirectional(
                start: 14,
                end: 14,
                bottom: 82,
                child: _bikeInfo(),
              ),
            PositionedDirectional(
              start: 14,
              bottom: 14,
              child: _glass(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speed_rounded, color: _orange, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${_speedKmh.round()} ${_isArabic ? 'كم/س' : 'km/h'}',
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              end: 14,
              bottom: 14,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                elevation: 5,
                child: InkWell(
                  onTap: _isLocating
                      ? null
                      : () async {
                          if (mounted) {
                            setState(() => _followBikeEnabled = true);
                          }
                          await _followBike(initial: true);
                        },
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: _isLocating
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.3,
                              color: _orange,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: _orange,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _destinationCard() {
    final destination = _selectedDestination!;
    return _card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffFF9A17), Color(0xffFF6500)],
              ),
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Icon(Icons.flag_rounded, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isArabic ? 'الوجهة المختارة' : 'Selected destination',
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFFF0E3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _isArabic ? 'جاهزة' : 'READY',
                        style: const TextStyle(
                          color: _orange,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  destination.fullAddress,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const Icon(Icons.route_rounded, color: _orange, size: 17),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _isArabic
                            ? 'اضغط ابدأ الملاحة لرسم الطريق البرتقالي والتوجيه للوجهة.'
                            : 'Start navigation to draw the orange route and begin guidance.',
                        style: const TextStyle(
                          color: _softText,
                          fontSize: 10.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationCard() => _card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xffFFF0E3),
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(Icons.near_me_rounded, color: _orange),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isArabic ? 'الموقع الحالي' : 'Current location',
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      _badge(),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLocating
                        ? (_isArabic
                            ? 'جارٍ تحديد موقعك...'
                            : 'Detecting your location...')
                        : (_address ??
                            (_isArabic ? 'موقع المندوب الحالي' : 'Current location')),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F8FA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _info(Icons.pin_drop_outlined, _coordinates),
                        const SizedBox(height: 7),
                        _info(Icons.gps_fixed_rounded, _accuracyText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _bikeInfo() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _navy.withOpacity(.94),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.two_wheeler_rounded, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isArabic ? 'GO مباشر' : 'GO Live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${_speedKmh.round()} ${_isArabic ? 'كم/س' : 'km/h'} • $_accuracyText',
                    style: const TextStyle(
                      color: Color(0xffD7E4EF),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _badge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: _isLive ? const Color(0xffECF8F1) : const Color(0xffFFF4E8),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          _isLive
              ? (_isArabic ? 'مباشر' : 'LIVE')
              : (_isLocating
                  ? (_isArabic ? 'جاري...' : 'Locating')
                  : (_isArabic ? 'متوقف' : 'Paused')),
          style: TextStyle(
            color: _isLive ? const Color(0xff267C51) : _orange,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  Widget _warningCard() => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xffFFF8EC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffFFE3B7)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xffC77A18)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                _locationError!,
                style: const TextStyle(
                  color: Color(0xff9A661F),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _info(IconData icon, String value) => Row(
        children: [
          Icon(icon, color: const Color(0xff747B86), size: 15),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff747B86),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );

  Widget _glass(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.94),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: child,
      );

  BoxDecoration _iconBox() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffECEEF1)),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffECEEF1)),
          boxShadow: [
            BoxShadow(
              color: _navy.withOpacity(.055),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: child,
      );
}
