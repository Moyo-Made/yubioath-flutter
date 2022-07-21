import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Get the number of bytes used by a String when encoded to UTF-8.
int byteLength(String value) => utf8.encode(value).length;

/// Builds a counter widget showing number of bytes used/available.
///
/// Set this as a [TextField.buildCounter] callback to show the number of bytes
/// used rather than number of characters. [currentValue] should always match
/// the input text value to measure.
InputCounterWidgetBuilder buildByteCounterFor(String currentValue) =>
    (context, {required currentLength, required isFocused, maxLength}) => Text(
          maxLength != null ? '${byteLength(currentValue)}/$maxLength' : '',
          style: Theme.of(context).textTheme.caption,
        );

/// Limits the input in length based on the byte length when encoded.
/// This is generally used together with [buildByteCounterFor].
TextInputFormatter limitBytesLength(int maxByteLength) =>
    TextInputFormatter.withFunction((oldValue, newValue) {
      final newLength = byteLength(newValue.text);
      if (newLength <= maxByteLength) {
        return newValue;
      }
      return oldValue;
    });
