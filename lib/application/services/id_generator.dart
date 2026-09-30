import 'package:uuid/uuid.dart';

abstract interface class IdGenerator {
  String generate();
}

final class UuidIdGenerator implements IdGenerator {
  const UuidIdGenerator();

  @override
  String generate() => const Uuid().v4();
}
