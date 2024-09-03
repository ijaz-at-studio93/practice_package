import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hello/firestore_pagination_cubit.dart';

import 'state.dart';

class PaginatedGridView extends StatefulWidget {
  final Query query;
  final int limit;
  final Widget Function(BuildContext, DocumentSnapshot) itemBuilder;
  final int gridDelegateColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final Widget? loadingIndicator;
  final Widget? noMoreDataIndicator;

  const PaginatedGridView({
    super.key,
    required this.query,
    required this.limit,
    required this.itemBuilder,
    required this.gridDelegateColumns,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
    this.childAspectRatio = 1.0,
    this.loadingIndicator,
    this.noMoreDataIndicator,
  });

  @override
  _PaginatedGridViewState createState() => _PaginatedGridViewState();
}

class _PaginatedGridViewState extends State<PaginatedGridView> {
  late FirestorePaginationCubit _paginationCubit;

  @override
  void initState() {
    super.initState();
    _paginationCubit =
        FirestorePaginationCubit(query: widget.query, limit: widget.limit);
    _paginationCubit.loadMoreData(); // Load initial data
  }

  @override
  void dispose() {
    _paginationCubit.close(); // Close the cubit when done
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

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.gridDelegateColumns,
            mainAxisSpacing: widget.mainAxisSpacing,
            crossAxisSpacing: widget.crossAxisSpacing,
            childAspectRatio: widget.childAspectRatio,
          ),
          itemCount: state.documents.length + 1,
          itemBuilder: (context, index) {
            if (index == state.documents.length) {
              if (state is FirestorePaginationLoading) {
                return widget.loadingIndicator ??
                    const Center(child: CircularProgressIndicator());
              } else if (state is FirestorePaginationLoaded && !state.hasMore) {
                return widget.noMoreDataIndicator ?? const SizedBox.shrink();
              } else {
                _paginationCubit.loadMoreData();
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
