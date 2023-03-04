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

import 'dart:convert';

import 'package:conduit_open_api/v3.dart';
import 'package:dogs_core/dogs_core.dart';

class DogSchema {
  final Map<String, APISchemaObject> _cachedStructObjects = {};

  DogSchema._();

  factory DogSchema.create() {
    var schema = DogSchema._();
    schema.getComponents(); // Cache all current structure objects
    return schema;
  }

  MapEntry<String, APISchemaObject> getStructureSchema(DogStructure structure) {
    var serialName = structure.serialName;
    if (_cachedStructObjects.containsKey(serialName)) {
      return MapEntry(serialName, _cachedStructObjects[serialName]!);
    }
    var properties = Map.fromEntries(structure.fields.map((e) {
      if (!e.structure) {
        APIType serialType;
        switch (e.serial.typeArgument) {
          case String:
            serialType = APIType.string;
            break;
          case int:
            serialType = APIType.integer;
            break;
          case double:
            serialType = APIType.number;
            break;
          case bool:
            serialType = APIType.boolean;
            break;
          default:
            throw Exception("Unhandled non structural serial serialType.");
        }
        var serialSchema = APISchemaObject.empty()..type = serialType;

        if (e.iterableKind == IterableKind.none) {
          var object = serialSchema;
          if (e.optional) object.isNullable = true;
          e.metadataOf<APISchemaObjectMetaVisitor>().forEach((element) {
            element.visit(object);
          });
          return MapEntry(e.name, serialSchema);
        } else {
          var object = APISchemaObject.array(ofSchema: serialSchema);
          if (e.optional) object.isNullable = true;
          e.metadataOf<APISchemaObjectMetaVisitor>().forEach((element) {
            element.visit(object);
          });
          return MapEntry(e.name, object);
        }
      }

      var object = e.findConverter()!.output;
      if (e.optional) object.isNullable = true;
      e.metadataOf<APISchemaObjectMetaVisitor>().forEach((element) {
        element.visit(object);
      });
      return MapEntry(e.name, object);
    }));
    var value = APISchemaObject.object(properties);
    structure.metadataOf<APISchemaObjectMetaVisitor>().forEach((element) {
      element.visit(value);
    });
    _cachedStructObjects[serialName] = value;
    return MapEntry(serialName, value);
  }

  APIComponents getComponents() {
    var schemas = Map.fromEntries(DogEngine.instance.structures.values
        .where((element) => !element.isSynthetic)
        .map((e) => getStructureSchema(e)));
    return APIComponents()..schemas = schemas;
  }

  APIDocument getApiDocument() {
    var document = APIDocument();
    document.version = "3.0.0";
    document.paths = {};
    document.info = APIInfo("DOG Mockup", "1.0",
        description:
            "Autogenerated component mockup of all registered structures which are not synthetic.");
    document.components = getComponents();
    return document;
  }

  String getApiJson() => jsonEncode(getApiDocument().asMap());
}
