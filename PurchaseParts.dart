import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PurchaseParts extends StatefulWidget {
  const PurchaseParts({super.key});

  @override
  State<PurchaseParts> createState() => _PurchasePartsState();
}
Future<List<Map<String, dynamic>>> fetchProducts() async {
  final prod = await FirebaseFirestore.instance.collection('products').get();
  return prod.docs.map((doc) => doc.data()).toList();
}
class _PurchasePartsState extends State<PurchaseParts> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        centerTitle: true,
      ),

      ),

    );
  }
}
