import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/park_model.dart';
import '../services/database_helper.dart';
import '../services/location_service.dart';
import '../widgets/car_drawer.dart';
import '../widgets/park_dialog.dart';
import '../widgets/valet_ticket_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  LatLng? _currentPosition;
  List<ParkedCar> _activeCars = [];
  List<ParkedCar> _deliveredCars = [];
  bool _isLoadingLocation = true;

  // Active Route
  ParkedCar? _activeRouteCar;
  List<LatLng> _routePoints = [];
  String? _distanceInfoText;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadParkedCars();
    await _fetchCurrentLocation();
  }

  Future<void> _loadParkedCars() async {
    final active = await DatabaseHelper.instance.getActiveParkedCars();
    final delivered = await DatabaseHelper.instance.getDeliveredCars();
    setState(() {
      _activeCars = active;
      _deliveredCars = delivered;
    });
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    String errorMessage = 'Konum bilgisi alınamadı. İzinleri ve GPS servislerini kontrol edin.';
    final pos = await _locationService.getCurrentLocation(
      onError: (err) {
        errorMessage = err;
      },
    );
    if (pos != null) {
      setState(() {
        _currentPosition = pos;
        _isLoadingLocation = false;
      });
      _mapController.move(pos, 16.0);
      if (_activeRouteCar != null) {
        _drawRouteToCar(_activeRouteCar!);
      }
    } else {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _drawRouteToCar(ParkedCar car) {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konumunuz alınamadı, rota çizilemiyor.')),
      );
      return;
    }

    final carPos = LatLng(car.latitude, car.longitude);
    const distanceCalc = Distance();
    final meters = distanceCalc.as(LengthUnit.Meter, _currentPosition!, carPos);

    String distStr;
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(1);
      final walkMins = (meters / 80).round();
      distStr = '$km km (Yürüyerek ~$walkMins dk)';
    } else {
      final walkMins = (meters / 80).round();
      final walkText = walkMins <= 1 ? '1 dk' : '$walkMins dk';
      distStr = '${meters.toInt()} Metre (Yürüyerek ~$walkText)';
    }

    setState(() {
      _activeRouteCar = car;
      _routePoints = [_currentPosition!, carPos];
      _distanceInfoText = distStr;
    });

    // Fit bounds to show both user and car
    final bounds = LatLngBounds.fromPoints([_currentPosition!, carPos]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80.0),
      ),
    );
  }

  void _clearRoute() {
    setState(() {
      _activeRouteCar = null;
      _routePoints = [];
      _distanceInfoText = null;
    });
  }

  Future<void> _parkCar() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mevcut konumunuz henüz alınamadı. Lütfen bekleyin.')),
      );
      return;
    }

    final result = await showDialog<ParkDialogResult>(
      context: context,
      builder: (context) => const ParkDialog(),
    );

    if (result != null && result.plate.isNotEmpty) {
      final newCar = ParkedCar(
        plate: result.plate,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        floorInfo: result.floorInfo,
        note: result.note,
        carType: result.carType,
        keyLocation: result.keyLocation,
      );

      final savedCar = await DatabaseHelper.instance.insertPark(newCar);
      await _loadParkedCars();

      if (mounted) {
        _showValetTicketSheet(savedCar);
      }

      _mapController.move(
        LatLng(savedCar.latitude, savedCar.longitude),
        17.0,
      );
    }
  }

  void _showValetTicketSheet(ParkedCar car) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ValetTicketSheet(
        car: car,
        currentPosition: _currentPosition,
        onDrawRoute: () {
          _drawRouteToCar(car);
        },
        onDelete: () {
          _deliverCar(car);
        },
      ),
    );
  }

  void _goToLatestCar() {
    if (_activeCars.isNotEmpty) {
      final latestCar = _activeCars.first;
      _showValetTicketSheet(latestCar);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktif vale kaydı bulunamadı.')),
      );
    }
  }

  Future<void> _deliverCar(ParkedCar car) async {
    if (car.id != null) {
      await DatabaseHelper.instance.markAsDelivered(car.id!);
      if (_activeRouteCar?.id == car.id) {
        _clearRoute();
      }
      await _loadParkedCars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${car.plate} aracı başarıyla teslim edildi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _deleteCar(ParkedCar car) async {
    if (car.id != null) {
      await DatabaseHelper.instance.deletePark(car.id!);
      await _loadParkedCars();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${car.plate} geçmiş kaydı silindi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition ?? const LatLng(41.0082, 28.9784);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 22),
            SizedBox(width: 8),
            Text(
              'VIP Vale & Park',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Konumuma Git',
            onPressed: _fetchCurrentLocation,
          ),
        ],
      ),
      drawer: CarDrawer(
        activeCars: _activeCars,
        deliveredCars: _deliveredCars,
        onSelectCar: (car) {
          _showValetTicketSheet(car);
        },
        onDeliverCar: _deliverCar,
        onDeleteCar: _deleteCar,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              minZoom: 3.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.parkbulucu',
              ),
              // Polyline Rota Katmanı
              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.0,
                      color: Colors.blueAccent,
                      borderColor: Colors.black54,
                      borderStrokeWidth: 2.0,
                    ),
                  ],
                ),
              // Marker Katmanı
              MarkerLayer(
                markers: [
                  // Mevcut konum marker'ı
                  if (_currentPosition != null)
                    Marker(
                      point: _currentPosition!,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blueAccent, width: 2),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                    ),
                  // Park edilmiş araçlar marker'ları
                  ..._activeCars.map((car) {
                    final carPos = LatLng(car.latitude, car.longitude);
                    return Marker(
                      point: carPos,
                      width: 130,
                      height: 70,
                      child: GestureDetector(
                        onTap: () {
                          _showValetTicketSheet(car);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber, width: 1.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.stars, color: Colors.amber, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    car.plate,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 36,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          // Aktif Rota Bilgisi Kartı
          if (_distanceInfoText != null && _activeRouteCar != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.black,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.amber, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '📍 ${_activeRouteCar!.plate} Rotası',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _distanceInfoText!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: _clearRoute,
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_isLoadingLocation)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Mevcut konum alınıyor...'),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _parkCar,
                icon: const Icon(Icons.stars, color: Colors.black),
                label: const Text(
                  'VIP Park Yerini Kaydet',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _goToLatestCar,
                icon: const Icon(Icons.confirmation_number, color: Colors.blueAccent),
                label: const Text(
                  'Vale Fişlerimi Gör',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
