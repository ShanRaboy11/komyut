import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './admin_add_route.dart';

class AdminRoutesPage extends StatefulWidget {
  const AdminRoutesPage({super.key});

  @override
  State<AdminRoutesPage> createState() => _AdminRoutesPageState();
}

class _AdminRoutesPageState extends State<AdminRoutesPage> {
  List<Map<String, dynamic>> _routes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      final response = await supabase
          .from('routes')
          .select('*, route_stops(count)')
          .order('code', ascending: true);

      setState(() {
        _routes = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading routes: ${e.toString()}', isError: true);
    }
  }

  Future<void> _deleteRoute(String routeId, String routeCode) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Route',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete route $routeCode? This action cannot be undone.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('routes').delete().eq('id', routeId);

      _showSnackBar('Route $routeCode deleted successfully');
      _loadRoutes();
    } catch (e) {
      _showSnackBar('Error deleting route: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredRoutes {
    if (_searchQuery.isEmpty) return _routes;
    
    return _routes.where((route) {
      final code = (route['code'] ?? '').toString().toLowerCase();
      final name = (route['name'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return code.contains(query) || name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Manage Routes',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F4FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_routes.length} routes',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B53C2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search routes...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.purple.shade100),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.purple.shade100),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF7F4FF),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ],
              ),
            ),

            // Routes List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRoutes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.route,
                                size: 80,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No routes yet'
                                    : 'No routes found',
                                style: GoogleFonts.manrope(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadRoutes,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredRoutes.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final route = _filteredRoutes[index];
                              final stopCount = route['route_stops'] != null
                                  ? (route['route_stops'] as List).length
                                  : 0;

                              return _RouteCard(
                                routeCode: route['code'] ?? 'N/A',
                                routeName: route['name'],
                                description: route['description'],
                                stopCount: stopCount,
                                onDelete: () => _deleteRoute(
                                  route['id'],
                                  route['code'] ?? 'N/A',
                                ),
                                onTap: () {
                                  // Navigate to route details
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RouteDetailsPage(
                                        routeId: route['id'],
                                        routeCode: route['code'] ?? 'N/A',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminAddRoutePage(),
            ),
          );
          _loadRoutes();
        },
        backgroundColor: const Color(0xFF5B53C2),
        icon: const Icon(Icons.add),
        label: Text(
          'Add Route',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final String routeCode;
  final String? routeName;
  final String? description;
  final int stopCount;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _RouteCard({
    required this.routeCode,
    this.routeName,
    this.description,
    required this.stopCount,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.purple.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B53C2), Color(0xFFB945AA)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    routeCode,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            if (routeName != null) ...[
              const SizedBox(height: 8),
              Text(
                routeName!,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  '$stopCount stops',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Route Details Page
class RouteDetailsPage extends StatefulWidget {
  final String routeId;
  final String routeCode;

  const RouteDetailsPage({
    super.key,
    required this.routeId,
    required this.routeCode,
  });

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  Map<String, dynamic>? _routeData;
  List<Map<String, dynamic>> _stops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRouteDetails();
  }

  Future<void> _loadRouteDetails() async {
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;

      // Load route
      final routeResponse = await supabase
          .from('routes')
          .select()
          .eq('id', widget.routeId)
          .single();

      // Load stops
      final stopsResponse = await supabase
          .from('route_stops')
          .select()
          .eq('route_id', widget.routeId)
          .order('sequence', ascending: true);

      setState(() {
        _routeData = routeResponse;
        _stops = List<Map<String, dynamic>>.from(stopsResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      appBar: AppBar(
        title: Text(
          'Route ${widget.routeCode}',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Route Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.purple.shade100),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _routeData?['name'] ?? 'Unnamed Route',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_routeData?['description'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _routeData!['description'],
                            style: GoogleFonts.nunito(color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stops List
                  Text(
                    'Stops (${_stops.length})',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _stops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final stop = _stops[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5B53C2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${stop['sequence']}',
                                  style: GoogleFonts.manrope(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                stop['name'],
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}