import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class DropdownTemplates {
  // Usamos 'SearchMatchFn<T>' que es el tipo de función correcto del paquete
  static DropdownSearchData<T> searchData<T>({
    required TextEditingController controller,
    required String hintText,
    required SearchMatchFn<T> searchMatchFn,
  }) {
    return DropdownSearchData<T>(
      searchController: controller,
      // Los nombres oficiales correctos en la versión actual:
      searchBarWidgetHeight: 50,
      searchBarWidget: Container(
        height: 50,
        padding: const EdgeInsets.only(top: 8, bottom: 4, right: 8, left: 8),
        child: TextFormField(
          expands: true,
          maxLines: null,
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      searchMatchFn: searchMatchFn,
    );
  }
}
