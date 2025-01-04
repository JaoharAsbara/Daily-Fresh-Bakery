import 'package:flutter/material.dart';

class CartModel extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];

  List<Map<String, dynamic>> get items => _items;

  void addToCart(String title, double price, String imagePath) {
    _items.add({
      'title': title,
      'price': price,
      'imagePath': imagePath,
    });
    notifyListeners();
  }

  void removeFromCart(int index) {
    _items.removeAt(index);
    notifyListeners(); 
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
