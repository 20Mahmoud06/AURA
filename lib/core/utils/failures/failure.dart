import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final dynamic error;

  const Failure(this.message, {this.error});

  @override
  List<Object?> get props => [message, error];

  @override
  String toString() => message;
}
