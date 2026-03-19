import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your project credentials
  await Supabase.initialize(
    url: 'https://tvfpzoutoowujxpilqeo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR2ZnB6b3V0b293dWp4cGlscWVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg4OTIwNzcsImV4cCI6MjA4NDQ2ODA3N30.Va9InJHhMzfEmkORMi2M1i0Q4qcSJ-2TY2BUVwCih0o',
  );

  runApp(const G14MonitorApp());
}

class G14MonitorApp extends StatelessWidget {
  const G14MonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'G14 Pulse',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F), // ROG Dark Grey
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
            fontSize: 18,
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Real-time stream listening for the newest entry in system_stats
  final Stream<List<Map<String, dynamic>>> _statsStream = Supabase
      .instance
      .client
      .from('system_stats')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .limit(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ROG ZEPHYRUS G14')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _statsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Connection Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }

          // Data mapping from your Python Pulse Agent
          final data = snapshot.data!.first;
          final double cpu = (data['cpu_usage'] ?? 0).toDouble();
          final double ram = (data['ram_usage'] ?? 0).toDouble();
          final bool isPlugged = data['is_plugged'] ?? true;
          final int battery = data['battery_level'] ?? 0;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildStatusHeader(isPlugged, battery),
                _buildGaugeCard("CPU LOAD", cpu, Colors.cyanAccent),
                _buildGaugeCard("RAM USAGE", ram, Colors.pinkAccent),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(bool isPlugged, int battery) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Icon(
                isPlugged ? Icons.power : Icons.battery_std,
                color: isPlugged ? Colors.greenAccent : Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              Text(isPlugged ? "AC POWER" : "BATTERY"),
            ],
          ),
          Text(
            "$battery%",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeCard(String label, double value, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 25, left: 20, right: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(color: color.withOpacity(0.7), letterSpacing: 2),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 15,
                    cornerStyle: CornerStyle.bothCurve,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: value,
                      width: 15,
                      color: color,
                      cornerStyle: CornerStyle.bothCurve,
                      enableAnimation: true,
                      animationDuration: 1000,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Text(
                        '${value.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color,
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
}
