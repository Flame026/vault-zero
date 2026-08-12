import 'package:flutter/foundation.dart';
import 'record.dart';

@immutable
class RecordCursor {
  final DateTime createdAt;
  final String id;

  const RecordCursor({
    required this.createdAt,
    required this.id,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordCursor &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt &&
          id == other.id;

  @override
  int get hashCode => createdAt.hashCode ^ id.hashCode;
}

@immutable
class RecordPage {
  final List<Record> records;
  final RecordCursor? nextCursor;
  final bool hasMore;

  const RecordPage({
    required this.records,
    this.nextCursor,
    required this.hasMore,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordPage &&
          runtimeType == other.runtimeType &&
          listEquals(records, other.records) &&
          nextCursor == other.nextCursor &&
          hasMore == other.hasMore;

  @override
  int get hashCode => Object.hash(Object.hashAll(records), nextCursor, hasMore);
}
