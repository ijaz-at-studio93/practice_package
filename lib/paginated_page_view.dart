import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hello/firestore_pagination_cubit.dart';

import 'state.dart';

class PaginatedPageView extends StatefulWidget {
  final Query query;
  final int limit;
  final Widget Function(BuildContext, DocumentSnapshot) itemBuilder;
  final PageController? pageController;
  final Axis scrollDirection;
  final bool reverse;
  final Widget? loadingIndicator;
  final Widget? noMoreDataIndicator;

  const PaginatedPageView({
    super.key,
    required this.query,
    required this.limit,
    required this.itemBuilder,
    this.pageController,
    this.scrollDirection = Axis.horizontal,
    this.reverse = false,
    this.loadingIndicator,
    this.noMoreDataIndicator,
  });

  @override
  _PaginatedPageViewState createState() => _PaginatedPageViewState();
}

class _PaginatedPageViewState extends State<PaginatedPageView> {
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

        return PageView.builder(
          controller: widget.pageController,
          scrollDirection: widget.scrollDirection,
          reverse: widget.reverse,
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
