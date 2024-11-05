import 'package:flutter/material.dart'; // Importing Flutter Material package for UI components.
import 'package:cloud_firestore/cloud_firestore.dart'; // Importing Cloud Firestore package for database interaction.
import 'package:logger/logger.dart'; // Importing Logger package for logging/debugging.

class SubscriptionManagementScreen extends StatefulWidget {
  final String userId; // User ID for fetching subscriptions.
  final String studentName; // Student's name.

  SubscriptionManagementScreen({required this.userId, required this.studentName});

  @override
  _SubscriptionManagementScreenState createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  final List<Map<String, dynamic>> _subscriptions = []; // List to hold subscription data.
  DocumentSnapshot? _lastDocument; // For pagination, stores the last fetched document.
  bool _hasMore = true; // Flag to indicate if more data is available.
  bool _isLoading = false; // Flag to indicate if data is loading.
  final Logger _logger = Logger(); // Logger instance for debugging.

  @override
  void initState() {
    super.initState();
    _resetAndReload(); // Initial load.
  }

  void _resetAndReload() {
    setState(() {
      _subscriptions.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoading = false;
    });
    _loadMoreSubscriptions(); // Reload subscriptions from Firestore.
  }

  Future<void> _loadMoreSubscriptions() async {
    if (!_hasMore || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .orderBy('timestamp', descending: true)
          .limit(10);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final QuerySnapshot querySnapshot = await query.get();
      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _lastDocument = querySnapshot.docs.last;
          _subscriptions.addAll(querySnapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList());
          _hasMore = querySnapshot.docs.length >= 10;
        });
      } else {
        setState(() {
          _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteSubscription(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('subscriptions')
          .doc(docId)
          .delete();

      setState(() {
        _subscriptions.removeWhere((subscription) => subscription['id'] == docId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الاشتراك بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حذف الاشتراك: $e')),
      );
    }
  }

  void _showEditDialog(Map<String, dynamic> subscription) {
    final formKey = GlobalKey<FormState>();
    bool active = subscription['active'] ?? true;
    double amount = (subscription['amount'] ?? 30).toDouble();
    String teacherName = subscription['teacherName'] ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الاشتراك'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('نشط'),
                  value: active,
                  onChanged: (value) {
                    setDialogState(() {
                      active = value;
                    });
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                  initialValue: amount.toString(),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'مطلوب';
                    if (double.tryParse(value!) == null) return 'أدخل رقماً صحيحاً';
                    return null;
                  },
                  onSaved: (value) => amount = double.parse(value!),
                ),
                // TextFormField(
                //   decoration: const InputDecoration(labelText: 'اسم المعلم'),
                //   initialValue: teacherName,
                //   onSaved: (value) => teacherName = value ?? '',
                // ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  formKey.currentState?.save();
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.userId)
                        .collection('subscriptions')
                        .doc(subscription['id'])
                        .update({
                      'active': active,
                      'amount': amount,
                      'teacherName': teacherName,
                    });

                    Navigator.pop(context);
                    _resetAndReload();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating subscription: $e')),
                    );
                  }
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTile(Map<String, dynamic> subscription) {
    return ListTile(
      title: Text(  'المبلغ: ${subscription['amount']} '),
      subtitle: Text(
            '${subscription['active'] ? 'نشط' : 'غير نشط'}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () => _showEditDialog(subscription),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => _deleteSubscription(subscription['id']),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final paymentController = TextEditingController();
    double? pendingAmount;

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
                  Text(
                    'دفع الاشتراك',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: paymentController,
                    decoration: InputDecoration(
                      hintText: 'المبلغ المدفوع',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () async {
                          if (paymentController.text.isNotEmpty) {
                            pendingAmount = double.parse(paymentController.text);
                            //       await FirebaseFirestore.instance
                            //                         .collection('users')
                            //                         .doc(widget.userId)
                            //                         .collection('subscriptions')
                            //                         .doc(subscription['id'])
                            //                         .update({
                            //                       'active': active,
                            //                       'amount': amount,
                            //                       'teacherName': teacherName,
                            //                     });
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.userId)
                                .collection('subscriptions')
                                .add({
                              'active': true,
                              'amount': pendingAmount,
                              'teacherName': widget.studentName,
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            Navigator.pop(context);
                            // Handle payment addition here
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
                          child: const Align(
                              alignment: Alignment.center, child: Text('دفع', style: TextStyle(color: Colors.white))),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4869E8),
        title: const Text(
          'إدارة الاشتراكات',
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
              itemCount: _subscriptions.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _subscriptions.length) {
                  if (_hasMore) {
                    _loadMoreSubscriptions();
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
                return _buildSubscriptionTile(_subscriptions[index]);
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4869E8),
        onPressed: () => _showPaymentDialog(context), // Show payment dialog
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
