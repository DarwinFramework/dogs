import 'package:darwin_marshal/darwin_marshal.dart';
import 'package:dogs/dogs.dart';
import 'package:dogs_darwin/dogs_darwin.dart';

class DogsMarshal {
  static void link(DarwinMarshal marshal, [DogEngine? engineOverride]) {
    var engine = engineOverride ?? DogEngine.internalSingleton;
    engine.associatedConverters.forEach((key, value) {
      var collectionSerializer = DogsDarwinCollectionMapper(key, value, engine);
      marshal.registerTypeMapper(
          key, DogsDarwinSingleMapper(key, value, engine));
      marshal.registerTypeMapper(value.deriveListType, collectionSerializer);
      marshal.registerTypeMapper(value.deriveSetType, collectionSerializer);
    });
  }
}