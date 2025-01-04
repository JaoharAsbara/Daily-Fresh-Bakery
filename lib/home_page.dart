import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'cart_model.dart';
import 'login_page.dart';
import 'profile.dart';
import 'checkout.dart';

class HomePage extends StatelessWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            _showLogoutDialog(context);
          },
        ),
        title: const Text(
          "Welcome to DF's Bakery",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.person, size: 50, color: Colors.brown),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.brown),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(username: username),
                      ),
                    );
                  },
                ),
              ],
            ),
            subtitle: const Text(
              'Selamat Pagi',
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(
            'assets/banner.jpg',
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'Menu Daily Fresh Bakery',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          MenuItem(
            imagePath: 'assets/croissant.jpg',
            title: 'Croissant',
            price: 20000.0,
            onAddToCart: () => _addToCart(
                context, 'Croissant', 20000.0, 'assets/croissant.jpg'),
            paymentLink:
                'https://app.sandbox.midtrans.com/payment-links/1735301891902', // Link Midtrans
          ),
          MenuItem(
            imagePath: 'assets/donut.jpg',
            title: 'Donut',
            price: 10000.0,
            onAddToCart: () =>
                _addToCart(context, 'Donut', 10000.0, 'assets/donut.jpg'),
            paymentLink:
                'https://app.sandbox.midtrans.com/payment-links/1734488665647', // Link Midtrans
          ),
          MenuItem(
            imagePath: 'assets/cupcake.jpg',
            title: 'Cupcake',
            price: 15000.0,
            onAddToCart: () =>
                _addToCart(context, 'Cupcake', 15000.0, 'assets/cupcake.jpg'),
            paymentLink:
                'https://app.sandbox.midtrans.com/payment-links/1735302092794', // Link Midtrans
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Lagi Diet Belanja?"),
          content: const Text(
              "Logout dulu? Jangan lupa balik buat cek promo menarik yaa!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  void _addToCart(
      BuildContext context, String title, double price, String imagePath) {
    Provider.of<CartModel>(context, listen: false)
        .addToCart(title, price, imagePath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title telah ditambahkan ke keranjang.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class MenuItem extends StatelessWidget {
  final String imagePath;
  final String title;
  final double price;
  final Function onAddToCart;
  final String paymentLink;

  const MenuItem({
    super.key,
    required this.imagePath,
    required this.title,
    required this.price,
    required this.onAddToCart,
    required this.paymentLink,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(
        imagePath,
        height: 70,
        width: 70,
        fit: BoxFit.cover,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
      subtitle: Text(
        'Rp ${price.toStringAsFixed(0)}',
        style: const TextStyle(
          fontSize: 18,
          color: Colors.brown,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
            onPressed: () => onAddToCart(),
          ),
          IconButton(
            icon: const Icon(Icons.payment, color: Colors.orange),
            onPressed: () => _navigateToPayment(context, paymentLink),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment(BuildContext context, String link) async {
    if (await canLaunchUrl(Uri.parse(link))) {
      await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuka link pembayaran.'),
        ),
      );
    }
  }
}
