import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'state.dart';

class FirestorePaginationCubit extends Cubit<FirestorePaginationState> {
  final Query _query;
  final int _limit;
  QueryDocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  final bool isStream;
  StreamSubscription<QuerySnapshot>? _subscription;

  FirestorePaginationCubit({
    required Query query,
    int limit = 10,
    this.isStream = false,
  })  : _query = query,
        _limit = limit,
        super(FirestorePaginationInitial());

  void loadStreamData() {
    if (!isStream) return;
    if (_subscription != null) return;

    Query query = _query.limit(_limit);

    _subscription = query.snapshots().listen((snapshot) {
      final documents = snapshot.docs;

      if (documents.isNotEmpty) {
        // Initial load
        if (_lastDocument == null) {
          _lastDocument = documents.last;
          _hasMore = documents.length == _limit;
          emit(FirestorePaginationLoaded(documents, _hasMore));
        } else {
          // Process new documents
          final newDocuments = documents.where((doc) =>
              state.documents.every((existingDoc) => existingDoc.id != doc.id)).toList();

          if (newDocuments.isNotEmpty) {
            _lastDocument = newDocuments.last;
            final updatedDocuments = List<DocumentSnapshot>.from(state.documents)
              ..addAll(newDocuments);
            _hasMore = newDocuments.length == _limit;
            emit(FirestorePaginationLoaded(updatedDocuments, _hasMore));
          }
        }
      } else {
        _hasMore = false;
        emit(FirestorePaginationLoaded(state.documents, _hasMore));
      }
    }, onError: (error) {
      emit(FirestorePaginationError(error.toString()));
    });
  }

  void loadMoreData() async {
    if (_isLoading || !_hasMore || isStream) return;

    _isLoading = true;
    emit(FirestorePaginationLoading(state.documents));

    Query query = _query.limit(_limit);

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        final documents = List<DocumentSnapshot>.from(state.documents)
          ..addAll(snapshot.docs);
        _hasMore = snapshot.docs.length == _limit;
        emit(FirestorePaginationLoaded(documents, _hasMore));
      } else {
        _hasMore = false;
        emit(FirestorePaginationLoaded(state.documents, _hasMore));
      }
    } catch (e) {
      emit(FirestorePaginationError(e.toString()));
    }

    _isLoading = false;
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
    _subscription?.cancel();
    _subscription = null;
    emit(FirestorePaginationInitial());

    if (isStream) {
      loadStreamData();
    } else {
      loadMoreData();
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
