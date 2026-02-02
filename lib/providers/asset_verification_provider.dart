import 'package:flutter/material.dart';

class AssetVerificationProvider extends ChangeNotifier {
  String? _selectedWarehouse;
  String? _selectedOwner;

  String? get selectedWarehouse => _selectedWarehouse;
  String? get selectedOwner => _selectedOwner;

  void selectWarehouse(String warehouse) {
    _selectedWarehouse = warehouse;
    notifyListeners();
  }

  void selectOwner(String? owner) {
    _selectedOwner = owner;
    notifyListeners();
  }

  bool hasResponsibleConflict({
    required String? articleResponsible,
  }) {
    if (_selectedOwner == null || _selectedOwner!.isEmpty) {
      return false;
    }

    return articleResponsible != _selectedOwner;
  }
}
