import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final h = await HistoryService.getHistory();
    setState(() {
      _history = h;
      _loading = false;
    });
  }

  String _formatWeight(double grams) {
    if (grams >= 1000) return '${(grams / 1000).toStringAsFixed(2)} kg';
    return '${grams.toStringAsFixed(0)} g';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E1A),
        title: const Text('Scan History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_history.isNotEmpty)
            TextButton(
              onPressed: () async {
                await HistoryService.clearHistory();
                _loadHistory();
              },
              child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)))
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 60)),
                      const Gap(16),
                      Text(
                        'No scan history',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (ctx, i) {
                    final item = _history[i];
                    final grams = (item['estimatedWeightGrams'] as num).toDouble();
                    final conf = (item['confidenceScore'] as num).toDouble();
                    final dt = DateTime.tryParse(item['timestamp'] ?? '');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2940),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            item['icon'] ?? '📦',
                            style: const TextStyle(fontSize: 36),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['objectName'] ?? 'Unknown',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                SizedBox(height: 5),
                                // Text(
                                //   item['objectNameHindi'] ?? '',
                                //   style: const TextStyle(
                                //       color: Color(0xFF00D4AA), fontSize: 12),
                                // ),
                                if (dt != null)
                                  Text(
                                    '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatWeight(grams),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${(conf * 100).round()}% conf',
                                style: TextStyle(
                                  color: conf >= 0.7
                                      ? const Color(0xFF00D4AA)
                                      : Colors.orange,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: (i * 50).ms).slideX(begin: 0.1);
                  },
                ),
    );
  }
}
