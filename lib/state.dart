import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FirestorePaginationState {
  final List<DocumentSnapshot> documents;
  const FirestorePaginationState(this.documents);
}

class FirestorePaginationInitial extends FirestorePaginationState {
  FirestorePaginationInitial() : super([]);
}

class FirestorePaginationLoading extends FirestorePaginationState {
  FirestorePaginationLoading(super.documents);
}

class FirestorePaginationLoaded extends FirestorePaginationState {
  final bool hasMore;
  FirestorePaginationLoaded(super.documents, this.hasMore);
}

class FirestorePaginationError extends FirestorePaginationState {
  final String error;
  FirestorePaginationError(this.error) : super([]);
}
