import 'dart:async';
import 'package:flutter/material.dart';
void test() {
  Autocomplete<String>(
    optionsBuilder: (textEditingValue) async {
      return ['hello'];
    }
  );
}
