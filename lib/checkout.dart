import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'midtrans_config.dart';

class CheckoutPage extends StatefulWidget {
  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool isLoading = false; // Menandakan status loading

  // Fungsi untuk menghubungi API Midtrans dan memulai pembayaran
  Future<void> initiatePayment(double amount) async {
    setState(() {
      isLoading =
          true; // Set isLoading menjadi true untuk menampilkan indikator loading
    });

    final url = Uri.parse('${MidtransConfig.baseUrl}charge');

    Map<String, dynamic> data = {
      "payment_type": "gopay", // Bisa sesuaikan jenis pembayaran
      "transaction_details": {
        "order_id": "order-${DateTime.now().millisecondsSinceEpoch}",
        "gross_amount": amount.toInt(),
      },
      "credit_card": {
        "secure": true,
      }
    };

    try {
      final response = await http.post(url, body: json.encode(data), headers: {
        'Authorization':
            'Basic ${base64Encode(utf8.encode(MidtransConfig.serverKey))}',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        // Jika transaksi sukses, beri notifikasi
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Pembayaran Berhasil!'),
            content: const Text('Pembayaran Anda telah diproses.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Tangani jika gagal
        throw Exception('Pembayaran gagal, coba lagi.');
      }
    } catch (error) {
      // Menangani kesalahan jaringan atau server error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan: $error')),
      );
    } finally {
      setState(() {
        isLoading =
            false; // Menghentikan indikator loading setelah proses selesai
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = Provider.of<CartModel>(context).items;

    // Mengelompokkan item berdasarkan judul dan menjumlahkan quantity
    Map<String, Map<String, dynamic>> groupedItems = {};
    for (var item in cartItems) {
      final title = item['title'];
      if (title != null) {
        if (groupedItems.containsKey(title)) {
          groupedItems[title]!['quantity'] += 1;
        } else {
          groupedItems[title] = {
            'price': item['price'],
            'imagePath': item['imagePath'],
            'quantity': 1,
          };
        }
      }
    }

    double totalAmount = groupedItems.entries.fold(
      0,
      (sum, entry) => sum + (entry.value['price'] * entry.value['quantity']),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.brown[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: groupedItems.length,
                itemBuilder: (context, index) {
                  final entry = groupedItems.entries.elementAt(index);
                  final itemTitle = entry.key;
                  final itemData = entry.value;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Image.asset(
                        itemData['imagePath'] ?? '',
                        height: 70,
                        width: 70,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        itemTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Rp ${itemData['price']?.toStringAsFixed(0) ?? '0'} x ${itemData['quantity'] ?? 0}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          // Logika untuk menghapus item dari cart
                          Provider.of<CartModel>(context, listen: false)
                              .removeFromCart(index);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('$itemTitle dihapus dari keranjang.')),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.brown[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total: Rp ${totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading
                  ? null // Disable button saat pembayaran sedang diproses
                  : () {
                      initiatePayment(totalAmount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Checkout sedang diproses...')),
                      );
                      Provider.of<CartModel>(context, listen: false)
                          .clearCart(); // Bersihkan keranjang setelah checkout
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[800],
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white) // Menampilkan loader saat loading
                  : const Text('Checkout',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
