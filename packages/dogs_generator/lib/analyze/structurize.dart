import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:dogs_core/dogs_core.dart';
import 'package:lyell_gen/lyell_gen.dart';
import 'package:source_gen/source_gen.dart';

import 'package:dogs_generator/dogs_generator.dart';

class CompiledStructure {
  String type;
  String serialName;
  List<CompiledStructureField> fields;
  String metadataSource;

  CompiledStructure(
      this.type, this.serialName, this.fields, this.metadataSource);

  String code(List<String> getters) =>
      "$genAlias.DogStructure<$type>($type, '$serialName', [${fields.map((e) => e.code).join(", ")}], $metadataSource, $genAlias.ObjectFactoryStructureProxy<$type>(_activator, [${getters.join(", ")}]))";
}

class CompiledStructureField {
  String accessor;
  String type;
  String serialType;
  String converterType;
  IterableKind iterableKind;
  String name;
  bool optional;
  bool structure;
  String metadataSource;

  CompiledStructureField(
      this.accessor,
      this.type,
      this.converterType,
      this.serialType,
      this.iterableKind,
      this.name,
      this.optional,
      this.structure,
      this.metadataSource);

  String get code =>
      "$genAlias.DogStructureField($type, ${genPrefix.str("TypeToken<$serialType>()")}, $converterType, $iterableKind, '$name', $optional, $structure, $metadataSource)";
}

class StructurizeResult {
  List<AliasImport> imports;
  CompiledStructure structure;
  List<String> fieldNames;
  String activator;

  StructurizeResult(
      this.imports, this.structure, this.fieldNames, this.activator);
}

class StructurizeCounter {
  int _value = 0;

  int getAndIncrement() {
    return _value++;
  }
}

String szPrefix = "sz";
TypeChecker propertyNameChecker = TypeChecker.fromRuntime(PropertyName);
TypeChecker propertySerializerChecker =
    TypeChecker.fromRuntime(PropertySerializer);
TypeChecker polymorphicChecker = TypeChecker.fromRuntime(Polymorphic);

Future<StructurizeResult> structurize(
    DartType type,
    ConstructorElement constructorElement,
    SubjectGenContext<Element> context,
    StructurizeCounter counter) async {
  List<AliasImport> imports = [];
  List<CompiledStructureField> fields = [];
  var element = type.element! as ClassElement;
  var serialName = element.name;
  for (var e in constructorElement.parameters) {
    var cszp = "$szPrefix${counter.getAndIncrement()}";
    var fieldName = e.name.replaceFirst("this.", "");
    var field = element.getField(fieldName);
    if (field == null) {
      throw Exception(
          "Serializable constructors must only reference instance fields");
    }
    var fieldType = field.type;
    var serialType = await getSerialType(fieldType, context);
    var iterableType = await getIterableType(fieldType, context);

    var optional = field.type.nullabilitySuffix == NullabilitySuffix.question;
    if (fieldType.isDynamic) optional = true;

    var propertyName = fieldName;
    if (propertyNameChecker.hasAnnotationOf(field)) {
      var annotation = propertyNameChecker.annotationsOf(field).first;
      propertyName = annotation.getField("name")!.toStringValue()!;
    }

    var propertySerializer = "null";
    if (propertySerializerChecker.hasAnnotationOf(field)) {
      var serializerAnnotation =
          propertySerializerChecker.annotationsOf(field).first;
      propertySerializer = serializerAnnotation
          .getField("type")!
          .toTypeValue()!
          .getDisplayString(withNullability: false);
    }
    if (polymorphicChecker.hasAnnotationOf(field)) {
      if (field.type.isDartCoreMap) {
        propertySerializer = "DefaultMapConverter";
      } else if (field.type.isDartCoreIterable) {
        propertySerializer = "DefaultIterableConverter";
      } else if (field.type.isDartCoreList) {
        propertySerializer = "DefaultListConverter";
      } else if (field.type.isDartCoreSet) {
        propertySerializer = "DefaultSetConverter";
      } else {
        propertySerializer = "PolymorphicConverter";
      }
    }

    var isLanguageType = fieldType.isVoid || fieldType.isDynamic;
    if (!isLanguageType) {
      imports.add(AliasImport.type(fieldType, cszp));
      imports.add(AliasImport.type(serialType, cszp));
    }

    fields.add(CompiledStructureField(
        fieldName,
        isLanguageType
            ? fieldType.getDisplayString(withNullability: false)
            : "$cszp.${fieldType.getDisplayString(withNullability: false)}",
        propertySerializer,
        isLanguageType
            ? serialType.getDisplayString(withNullability: false)
            : "$cszp.${serialType.getDisplayString(withNullability: false)}",
        iterableType,
        propertyName,
        optional,
        !isDogPrimitiveType(serialType),
        getStructureMetadataSourceArrayAliased(field, imports, counter)));
  }

  // Determine used constructor
  var constructorName = "";
  var constructor = element.unnamedConstructor!;
  if (element.getNamedConstructor("dog") != null) {
    constructorName = ".dog";
    constructor = element.getNamedConstructor("dog")!;
  }

  // Create proxy arguments
  var getters = fields.map((e) => e.accessor).toList();
  var activator = "${element.name}$constructorName(${fields.mapIndexed((i, y) {
    if (y.iterableKind == IterableKind.none) return "list[$i]";
    if (y.optional) return "list[$i]?.cast<${y.serialType}>()";
    return "list[$i].cast<${y.serialType}>()";
  }).join(", ")})";

  var rootTypePrefix = "$szPrefix${counter.getAndIncrement()}";
  imports.add(AliasImport.type(type, rootTypePrefix));
  var structure = CompiledStructure(
      "$rootTypePrefix.${type.getDisplayString(withNullability: false)}",
      serialName,
      fields,
      getStructureMetadataSourceArrayAliased(element, imports, counter));
  return StructurizeResult(imports, structure, getters, activator);
}
