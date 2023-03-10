import 'package:dogs_core/dogs_validation.dart';
import 'package:dogs_core/dogs_core.dart';

@serializable
@Description("A random unique person")
class Person with DogsMixin<Person> {

  @Description("The name of the person")
  @LengthRange(min: 1, max: 128)
  @Regex("([A-Z])+([a-z])*")
  String name;
  @Range(min: 0, max: 130)
  int age;
  @SizeRange(max: 64)
  Set<String>? tags;
  @validated
  List<Note> notes;
  Gender gender;

  @PropertyName("birthday")
  @PropertySerializer(PolymorphicConverter)
  DateTime birthdayDate;

  Person.dog(this.name, this.age, this.tags, this.notes, this.birthdayDate, this.gender);

  Person({
    required this.name,
    required this.age,
    this.tags,
    required this.notes,
    required this.gender,
    required this.birthdayDate
  });
}

@serializable
@TestStructureAnnotation("Note Outer")
class Note with DogsMixin<Note> {
  String text;

  @TestStructureAnnotation("Note Inner")
  int id;

  @SizeRange(min: 0, max: 16)
  @Minimum(1)
  List<int>? claims;

  @polymorphic
  Object? attachment;

  Note(this.text, this.id, this.attachment, this.claims);
}

@serializable
enum Gender { male, female, other }
