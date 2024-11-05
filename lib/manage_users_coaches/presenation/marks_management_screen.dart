import 'package:flutter/material.dart'; // Importing Flutter Material package for UI components.
import 'package:cloud_firestore/cloud_firestore.dart'; // Importing Cloud Firestore package for database interaction.
import 'package:flutter_svg/flutter_svg.dart'; // Importing SVG package to render SVG images.
import 'package:logger/logger.dart'; // Importing Logger package for debugging purposes.

class MarksManagementScreen extends StatefulWidget {
  final String userId; // User ID to fetch marks for a specific user.
  final String studentName; // Student name for display purposes.

  MarksManagementScreen({required this.userId, required this.studentName}); // Constructor to initialize user ID and student name.

  @override
  _MarksManagementScreenState createState() => _MarksManagementScreenState();
}

class _MarksManagementScreenState extends State<MarksManagementScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form key to manage form validation.
  final List<Map<String, dynamic>> _marks = []; // List to hold marks data.
  DocumentSnapshot? _lastDocument; // To store the last fetched document for pagination.
  bool _hasMore = true; // Flag to check if more data is available.
  bool _isLoading = false; // Flag to check if data is loading.
  final Logger _logger = Logger(); // Logger instance for debugging.

  @override
  void initState() {
    super.initState();
    _resetAndReload(); // Initial data load.
  }

  void _resetAndReload() {
    setState(() {
      _marks.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoading = false;
    });
    _loadMoreMarks(); // Load marks from Firestore.
  }

  Future<void> _loadMoreMarks() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('marks')
          .orderBy('timestamp', descending: true)
          .limit(10);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot querySnapshot = await query.get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = querySnapshot.docs.last;
          _marks.addAll(querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList());
          if (querySnapshot.docs.length < 10) {
            _hasMore = false;
          }
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading marks: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditMarksDialog(BuildContext context, Map<String, dynamic> mark) {
    final marksController = TextEditingController(text: mark['mark'].toString());
    String? selectedExamRange = mark['examRange'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SvgPicture.asset(
                            'assets/images/frame23420.svg',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'تعديل الدرجات',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Marks input field and exam range
                  Row(
                    children: [
                      // Marks input field
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: marksController,
                          decoration: InputDecoration(
                            hintText: 'الدرجات',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dropdown for exam score range
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedExamRange,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedExamRange = newValue;
                            });
                          },
                          items: <String>['10', '20', '30', '40', '50', '60', '70', '80', '90', '100']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            hintText: 'اختر من 10 إلى 100',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (marksController.text.isNotEmpty && selectedExamRange != null) {
                            double pendingMark = double.parse(marksController.text);
                            Navigator.pop(context);

                            // Assuming there's a method to update marks in Firebase
                            _updateMarkInFirebase(mark['id'], pendingMark, selectedExamRange!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('برجاء ملء جميع الحقول')),
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('تعديل', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFB9B9B9), borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('إلغاء', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateMarkInFirebase(String docId, double mark, String examRange) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('marks')
          .doc(docId)
          .update({
        'mark': mark,
        'examRange': examRange,
        'timestamp': Timestamp.now(), // Update timestamp if necessary
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعديل الدرجة بنجاح')),
      );

      _resetAndReload(); // Reload marks after updating
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تعديل الدرجة: $e')),
      );
    }
  }

  Widget _buildMarkTile(Map<String, dynamic> mark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الدرجة: ${mark['mark']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'نطاق الامتحان: ${mark['examRange']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'التاريخ: ${mark['timestamp'].toDate().day}/${mark['timestamp'].toDate().month}/${mark['timestamp'].toDate().year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditMarksDialog(context, mark), // Show edit dialog
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteMark(mark['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4869E8),
        title: const Text(
          'إدارة الدرجات',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        color: const Color(0xFF4869E8),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () async {
              _resetAndReload();
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              itemCount: _marks.length + 1,
              itemBuilder: (context, index) {
                if (index == _marks.length) {
                  if (_hasMore) {
                    _loadMoreMarks();
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                }
                return _buildMarkTile(_marks[index]);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4869E8),
        onPressed: () => _showAddMarksDialog(context), // Show dialog on button press
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

// Modify the _buildMarkTile method to include the edit button
  Future<void> _deleteMark(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('marks')
          .doc(docId)
          .delete();

      setState(() {
        _marks.removeWhere((mark) => mark['id'] == docId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الدرجة بنجاح')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حذف الدرجة: $e')),
        );
      }
    }
  }

  void _showAddMarksDialog(BuildContext context) {
    final marksController = TextEditingController();
    String? selectedExamRange;
    String? selectedTeacher;
    double? pendingMark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SvgPicture.asset(
                            'assets/images/frame23420.svg',
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'إضافة درجات',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Marks input field and exam range
                  Row(
                    children: [
                      // Marks input field
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: marksController,
                          decoration: InputDecoration(
                            hintText: 'الدرجات',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Dropdown for exam score range
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: selectedExamRange,
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedExamRange = newValue;
                            });
                          },
                          items: <String>['10', '20', '30', '40', '50', '60', '70', '80', '90', '100']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                            hintText: 'اختر من 10 إلى 100',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () {
                          if (marksController.text.isNotEmpty && selectedExamRange != null) {
                            pendingMark = double.parse(marksController.text);
                            Navigator.pop(context);

                            // Assuming there's a method to add marks to Firebase
                            _addMarkToFirebase(pendingMark!, selectedExamRange!, selectedTeacher);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('برجاء ملء جميع الحقول')),
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('إضافة', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 100,
                          height: 40,
                          decoration: BoxDecoration(color: const Color(0xFFB9B9B9), borderRadius: BorderRadius.circular(8)),
                          child: const Align(alignment: Alignment.center, child: Text('إلغاء', style: TextStyle(color: Colors.white))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addMarkToFirebase(double mark, String examRange, String? teacher) async {
    // Add the implementation to save the mark to Firestore here
    // Example:
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('marks')
          .add({
        'mark': mark,
        'examRange': examRange,
        'teacher': teacher,
        'timestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة الدرجة بنجاح')),
      );

      _resetAndReload(); // Reload marks after adding
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في إضافة الدرجة: $e')),
      );
    }
  }

}
