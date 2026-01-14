import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../sidebar.dart';
import '../../supabase_config.dart';
import 'meeting_details_dialog.dart';
import 'add_meeting_popup.dart';

class AppColors {
  static const bg = Color(0xFF202020);
  static const panel = Color(0xFF2D2D2D);
  static const blue = Color(0xFF50B2E7);
  static const white = Color(0xFFFFFFFF);
  static const textGrey = Color(0xFF999999);
  static const divider = Color(0xFF3A3A3A);
  static const yellowBtn = Color(0xFFF9D949);
}

class DamagedProductsPage extends StatefulWidget {
  const DamagedProductsPage({super.key});

  @override
  State<DamagedProductsPage> createState() => _DamagedProductsPageState();
}

class _DamagedProductsPageState extends State<DamagedProductsPage> {
  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> filteredMeetings = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int? hoveredRow;

  @override
  void initState() {
    super.initState();
    _fetchMeetings();
    _searchController.addListener(_filterMeetings);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMeetings() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredMeetings = meetings);
      return;
    }

    setState(() {
      filteredMeetings = meetings
          .where(
            (meeting) =>
                meeting['meeting_topics']?.toString().toLowerCase().contains(
                      query,
                    ) ==
                    true ||
                meeting['meeting_address']?.toString().toLowerCase().contains(
                      query,
                    ) ==
                    true,
          )
          .toList();
    });
  }

  Future<void> _fetchMeetings() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('damaged_products_meeting')
          .select('''
            meeting_id,
            meeting_address,
            meeting_time,
            meeting_topics,
            result_of_meeting
          ''')
          .order('meeting_time', ascending: false);

      final List<Map<String, dynamic>> fetchedMeetings = [];

      for (var meeting in response) {
        fetchedMeetings.add({
          'meeting_id': meeting['meeting_id'],
          'meeting_address': meeting['meeting_address'] ?? 'N/A',
          'meeting_time': _formatDateTime(meeting['meeting_time']),
          'meeting_topics': meeting['meeting_topics'] ?? 'N/A',
          'result_of_meeting': meeting['result_of_meeting'] ?? 'N/A',
        });
      }

      if (mounted) {
        setState(() {
          meetings = fetchedMeetings;
          filteredMeetings = fetchedMeetings;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching meetings: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  void _showMeetingDetails(Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (context) =>
          MeetingDetailsDialog(meetingId: meeting['meeting_id']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          const Sidebar(activeIndex: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Damaged Products',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Action Bar
                  Row(
                    children: [
                      const Spacer(),
                      // Add Meeting Button (optional - can remove if not needed)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.yellowBtn,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        onPressed: () {
                          showAddMeetingPopup(context, () {
                            _fetchMeetings();
                          });
                        },
                        icon: const Icon(Icons.add, color: Colors.black),
                        label: const Text(
                          'Add Meeting',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _SearchBox(
                        hint: "Enter Topic or Address",
                        controller: _searchController,
                        onChanged: (val) => _filterMeetings(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Table
                  Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.blue,
                            ),
                          )
                        : filteredMeetings.isEmpty
                        ? const Center(
                            child: Text(
                              'No meetings found',
                              style: TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                // Table Header
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: _headerText('ID #'),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: _headerText('Meeting Topics'),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: _headerText('Address'),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: _headerText('Date & Time'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(color: Colors.white24),

                                // Table Rows
                                for (
                                  int i = 0;
                                  i < filteredMeetings.length;
                                  i++
                                )
                                  Builder(
                                    builder: (context) {
                                      final meeting = filteredMeetings[i];
                                      final isHovered = hoveredRow == i;
                                      return MouseRegion(
                                        onEnter: (_) {
                                          if (mounted) {
                                            setState(() => hoveredRow = i);
                                          }
                                        },
                                        onExit: (_) {
                                          if (mounted) {
                                            setState(() => hoveredRow = null);
                                          }
                                        },
                                        child: InkWell(
                                          onTap: () =>
                                              _showMeetingDetails(meeting),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.panel,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isHovered
                                                    ? AppColors.blue
                                                    : Colors.transparent,
                                                width: 1.5,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 1,
                                                  child: Text(
                                                    '#${meeting['meeting_id']}',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    meeting['meeting_topics'] ??
                                                        'N/A',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    meeting['meeting_address'] ??
                                                        'N/A',
                                                    style: GoogleFonts.roboto(
                                                      color: Colors.grey[400],
                                                      fontSize: 13,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: Text(
                                                      meeting['meeting_time'] ??
                                                          'N/A',
                                                      style: GoogleFonts.roboto(
                                                        color: Colors.grey[400],
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.roboto(
        color: Colors.grey[300],
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Search Box Widget
class _SearchBox extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final Function(String) onChanged;

  const _SearchBox({
    required this.hint,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.white60, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
