/*
 *    Copyright 2022, the DOGs authors
 *
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

import 'dart:async';

import 'package:dogs_core/dogs_core.dart';
import 'package:lyell/lyell.dart';

extension StructureExtensions on DogStructure {
  List<dynamic Function(dynamic)> get getters => List.generate(
      fields.length, (index) => (obj) => this.proxy.getField(obj, index));

  List<T> metadataOf<T>() {
    return metadata.whereType<T>().toList();
  }

  int? indexOfFieldName(String name) {
    for (var i = 0; i < fields.length; i++) {
      if (fields[i].name == name) {
        return i;
      }
    }
    return null;
  }
}

extension FieldExtension on DogStructureField {
  List<T> metadataOf<T>() {
    return metadata.whereType<T>().toList();
  }

  DogConverter? findConverter() {
    if (converterType == null) {
      return dogs.findAssociatedConverter(serial.typeArgument);
    } else {
      return dogs.findConverter(converterType!);
    }
  }
}

mixin TypeCaptureMixin<T> implements TypeCapture<T> {
  @override
  Type get typeArgument => T;
  @override
  Type get deriveList => List<T>;
  @override
  Type get deriveSet => Set<T>;
  @override
  Type get deriveIterable => Iterable<T>;
  @override
  Type get deriveFuture => Future<T>;
  @override
  Type get deriveFutureOr => FutureOr<T>;
  @override
  Type get deriveStream => Stream<T>;
}
