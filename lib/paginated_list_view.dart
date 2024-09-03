import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hello/firestore_pagination_cubit.dart';
import 'package:hello/state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaginatedListView extends StatefulWidget {
  final Query query;
  final int limit;
  final Widget Function(BuildContext, DocumentSnapshot) itemBuilder;
  final Widget? loadingIndicator;
  final Widget? noMoreDataIndicator;
  final bool isStream;

  const PaginatedListView({
    super.key,
    required this.query,
    required this.limit,
    required this.itemBuilder,
    this.loadingIndicator,
    this.noMoreDataIndicator,
    this.isStream = false,
  });

  @override
  _PaginatedListViewState createState() => _PaginatedListViewState();
}

class _PaginatedListViewState extends State<PaginatedListView> {
  late FirestorePaginationCubit _paginationCubit;

  @override
  void initState() {
    super.initState();
    _paginationCubit = FirestorePaginationCubit(
      query: widget.query,
      limit: widget.limit,
      isStream: widget.isStream,
    );

    if (widget.isStream) {
      _paginationCubit.loadStreamData();
    } else {
      _paginationCubit.loadMoreData();
    }
  }

  @override
  void dispose() {
    _paginationCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FirestorePaginationCubit, FirestorePaginationState>(
      bloc: _paginationCubit,
      builder: (context, state) {
        if (state is FirestorePaginationLoading && state.documents.isEmpty) {
          return Center(
              child:
                  widget.loadingIndicator ?? const CircularProgressIndicator());
        } else if (state is FirestorePaginationError) {
          return Center(child: Text('Error: ${state.error}'));
        }

        return ListView.builder(
          itemCount: state.documents.length + 1,
          itemBuilder: (context, index) {
            if (index == state.documents.length) {
              if (state is FirestorePaginationLoading) {
                return widget.loadingIndicator ??
                    const Center(child: CircularProgressIndicator());
              } else if (state is FirestorePaginationLoaded && !state.hasMore) {
                return widget.noMoreDataIndicator ?? const SizedBox.shrink();
              } else {
                if (widget.isStream) {
                  print('Load more data for stream');
                  // Load more data for stream
                  _paginationCubit.loadStreamData();
                } else {
                  // Load more data for future
                  _paginationCubit.loadMoreData();
                }
                return widget.loadingIndicator ??
                    const Center(child: CircularProgressIndicator());
              }
            }

            final document = state.documents[index];
            return widget.itemBuilder(context, document);
          },
        );
      },
    );
  }
}
