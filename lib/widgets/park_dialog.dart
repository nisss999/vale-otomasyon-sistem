import 'package:flutter/material.dart';

class ParkDialogResult {
  final String plate;
  final String? floorInfo;
  final String? note;
  final String carType;
  final String keyLocation;

  ParkDialogResult({
    required this.plate,
    this.floorInfo,
    this.note,
    required this.carType,
    required this.keyLocation,
  });
}

class ParkDialog extends StatefulWidget {
  const ParkDialog({super.key});

  @override
  State<ParkDialog> createState() => _ParkDialogState();
}

class _ParkDialogState extends State<ParkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _plateController = TextEditingController();
  final _floorController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCarType = 'Sedan';
  String _selectedKeyLocation = 'Cebimde';

  final List<Map<String, dynamic>> _carTypes = [
    {'name': 'Sedan', 'icon': Icons.directions_car},
    {'name': 'SUV', 'icon': Icons.airport_shuttle},
    {'name': 'Hatchback', 'icon': Icons.directions_car_filled},
    {'name': 'Elektrikli', 'icon': Icons.electric_car},
    {'name': 'Spor', 'icon': Icons.sports_motorsports},
    {'name': 'VIP Minibüs', 'icon': Icons.departure_board},
  ];

  final List<String> _keyLocations = [
    'Cebimde',
    'Torpidoda',
    'Vale Kulübesinde',
    'Resepsiyonda',
    'Kilitli Kutu',
  ];

  @override
  void dispose() {
    _plateController.dispose();
    _floorController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VIP Vale & Park Kaydı',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Park konumunuzu detaylandırın',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _plateController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Araç Plakası *',
                  hintText: 'Örn: 34 VIP 34',
                  prefixIcon: Icon(Icons.badge_outlined, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen araç plakasını girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              const Text('Araç Tipi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedCarType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _carTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['name'],
                    child: Row(
                      children: [
                        Icon(type['icon'] as IconData, size: 20, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(type['name'] as String),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCarType = val);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _floorController,
                decoration: const InputDecoration(
                  labelText: 'Kat / Sektör Bilgisi',
                  hintText: 'Örn: Kat B2 / Sektör A-12',
                  prefixIcon: Icon(Icons.layers_outlined, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Anahtar Nerede?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedKeyLocation,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _keyLocations.map((loc) {
                  return DropdownMenuItem<String>(
                    value: loc,
                    child: Row(
                      children: [
                        const Icon(Icons.key, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(loc),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedKeyLocation = val);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Özel Not / Açıklama',
                  hintText: 'Örn: Resepsiyon yakını, aynalar kapalı',
                  prefixIcon: Icon(Icons.notes_outlined, color: Colors.black),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                ParkDialogResult(
                  plate: _plateController.text.trim(),
                  floorInfo: _floorController.text.trim().isEmpty ? null : _floorController.text.trim(),
                  note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                  carType: _selectedCarType,
                  keyLocation: _selectedKeyLocation,
                ),
              );
            }
          },
          icon: const Icon(Icons.stars, color: Colors.amber, size: 18),
          label: const Text('Vale Kaydını Oluştur'),
        ),
      ],
    );
  }
}
