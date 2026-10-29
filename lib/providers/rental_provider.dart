import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class RentalProvider extends ChangeNotifier {
  final List<Vehicle> _cart = [];
  bool _isLoading = false;

  List<Vehicle> get cart => _cart;
  bool get isLoading => _isLoading;

  void addToCart(Vehicle car) {
    _cart.add(car);
    notifyListeners();
  }

  Future<void> checkout() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _cart.clear();
    _isLoading = false;
    notifyListeners();
  }
}