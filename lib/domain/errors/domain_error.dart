sealed class DomainError implements Exception {
  const DomainError(this.message);

  final String message;

  @override
  String toString() => message;
}

final class ValidationError extends DomainError {
  const ValidationError(super.message, {this.field});

  final String? field;
}

final class DuplicateActiveNameError extends DomainError {
  const DuplicateActiveNameError(super.message);
}

final class EntityNotFoundError extends DomainError {
  const EntityNotFoundError(super.message);
}

final class OccupiedTableError extends DomainError {
  const OccupiedTableError(super.message);
}

final class TableUnavailableError extends DomainError {
  const TableUnavailableError(super.message);
}

final class OrderNotEditableError extends DomainError {
  const OrderNotEditableError(super.message);
}

final class ProductUnavailableError extends DomainError {
  const ProductUnavailableError(super.message);
}

final class DuplicatePaymentError extends DomainError {
  const DuplicatePaymentError(super.message);
}

final class PaymentNotAllowedError extends DomainError {
  const PaymentNotAllowedError(super.message);
}

final class PersistenceError extends DomainError {
  const PersistenceError(super.message);
}
