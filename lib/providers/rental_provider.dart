import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class RentalProvider extends ChangeNotifier {
  final List<Vehicle> _cart = [];
  bool _isLoading = false;

  List<Vehicle> get cart => List.unmodifiable(_cart);
  bool get isLoading => _isLoading;

  void addToCart(Vehicle car) {
    _cart.add(car);
    notifyListeners();
  }

  void removeFromCart(Vehicle car) {
    _cart.remove(car);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  Future<void> checkout() async {
    if (_isLoading || _cart.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Simulasi proses checkout sementara
      await Future.delayed(const Duration(seconds: 2));

      _cart.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
