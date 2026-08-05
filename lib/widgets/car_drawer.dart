import 'package:flutter/material.dart';
import '../models/park_model.dart';

class CarDrawer extends StatefulWidget {
  final List<ParkedCar> activeCars;
  final List<ParkedCar> deliveredCars;
  final Function(ParkedCar) onSelectCar;
  final Function(ParkedCar) onDeliverCar;
  final Function(ParkedCar) onDeleteCar;

  const CarDrawer({
    super.key,
    required this.activeCars,
    required this.deliveredCars,
    required this.onSelectCar,
    required this.onDeliverCar,
    required this.onDeleteCar,
  });

  @override
  State<CarDrawer> createState() => _CarDrawerState();
}

class _CarDrawerState extends State<CarDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 12,
            ),
            decoration: const BoxDecoration(
              color: Colors.black,
              border: Border(bottom: BorderSide(color: Colors.amber, width: 1)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: const Icon(Icons.stars, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VIP Vale & Park',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Aktif: ${widget.activeCars.length} · Teslim: ${widget.deliveredCars.length}',
                            style: const TextStyle(color: Colors.amber, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Tab Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    dividerHeight: 0,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_parking, size: 16),
                            const SizedBox(width: 6),
                            Text('Aktif (${widget.activeCars.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 16),
                            const SizedBox(width: 6),
                            Text('Teslim (${widget.deliveredCars.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildActiveList(),
                _buildDeliveredList(),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'VIP Valet & Park Assistant v2.0',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveList() {
    if (widget.activeCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_parking, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            const Text(
              'Aktif vale kaydı bulunmuyor.',
              style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.activeCars.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, index) {
        final car = widget.activeCars[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.amber.withValues(alpha: 0.15),
            child: const Icon(Icons.directions_car, color: Colors.amber),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  car.plate,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  car.ticketCode,
                  style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '⏱️ ${car.formattedDuration} · ${car.carType}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
            tooltip: 'Aracı Teslim Et',
            onPressed: () => _showDeliverConfirmDialog(context, car),
          ),
          onTap: () {
            widget.onSelectCar(car);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Widget _buildDeliveredList() {
    if (widget.deliveredCars.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 12),
            const Text(
              'Henüz teslim edilen araç yok.',
              style: TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.deliveredCars.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
      itemBuilder: (context, index) {
        final car = widget.deliveredCars[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.green.withValues(alpha: 0.15),
            child: const Icon(Icons.check_circle, color: Colors.greenAccent),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(
                  car.plate,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TESLİM EDİLDİ',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${car.ticketCode} · ${car.carType}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                'Toplam park süresi: ${car.formattedDuration}',
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
            tooltip: 'Kaydı Sil',
            onPressed: () => _showDeleteConfirmDialog(context, car),
          ),
        );
      },
    );
  }

  void _showDeliverConfirmDialog(BuildContext context, ParkedCar car) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 8),
            Text('Aracı Teslim Et', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          '${car.plate} (${car.ticketCode}) plakalı araç teslim edilecek.\n\nPark süresi: ${car.formattedDuration}',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeliverCar(car);
            },
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Teslim Et', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, ParkedCar car) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Kaydı Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '${car.plate} (${car.ticketCode}) geçmiş kaydı kalıcı olarak silinecektir.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onDeleteCar(car);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
