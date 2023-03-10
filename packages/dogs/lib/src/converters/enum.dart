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

import 'package:conduit_open_api/v3.dart';
import 'package:dogs_core/dogs_core.dart';

typedef EnumFromString<T> = T? Function(String);
typedef EnumToString<T> = String Function(T?);

abstract class GeneratedEnumDogConverter<T extends Enum>
    extends DogConverter<T> {
  EnumToString<T?> get toStr;
  EnumFromString<T?> get fromStr;
  List<String> get values;

  @override
  T convertFromGraph(DogGraphValue value, DogEngine engine) {
    var s = (value as DogString).value;
    return fromStr(s)!;
  }

  @override
  DogGraphValue convertToGraph(T value, DogEngine engine) {
    var s = toStr(value);
    return DogString(s);
  }

  @override
  APISchemaObject get output {
    return APISchemaObject.string()
      ..title = T.toString()
      ..enumerated = values;
  }
}
