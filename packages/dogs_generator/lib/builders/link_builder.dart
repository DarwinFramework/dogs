import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:dogs_core/dogs_core.dart';

import 'package:dogs_generator/dogs_generator.dart';
import 'package:lyell_gen/lyell_gen.dart';

class LinkBuilder extends DogsAdapter<LinkSerializer> {
  LinkBuilder() : super(archetype: "link");

  @override
  Future<SubjectDescriptor> generateDescriptor(
      SubjectGenContext<Element> context) async {
    var binding = context.defaultDescriptor();
    binding.meta["converterNames"] =
        context.matches.map((e) => e.name).toList();
    return binding;
  }

  @override
  FutureOr<void> generateSubject(
      SubjectGenContext<Element> genContext, SubjectCodeContext codeContext) {
    codeContext.noGenerate = true;
  }
}
