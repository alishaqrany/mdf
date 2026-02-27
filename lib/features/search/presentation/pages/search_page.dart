import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../courses/presentation/bloc/courses_bloc.dart';

/// Unified search page – searches courses using existing CoursesBloc.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  late final CoursesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = CoursesBloc(getEnrolledCourses: sl(), searchCourses: sl());
  }

  @override
  void dispose() {
    _controller.dispose();
    _bloc.close();
    super.dispose();
  }

  void _search() {
    final q = _controller.text.trim();
    if (q.isNotEmpty) {
      _bloc.add(SearchCoursesEvent(query: q));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: Text('common.search'.tr())),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'common.search'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _search(),
              ),
            ),
            Expanded(
              child: BlocBuilder<CoursesBloc, CoursesState>(
                builder: (context, state) {
                  if (state is CoursesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CoursesError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is CoursesSearchResults) {
                    if (state.courses.isEmpty) {
                      return Center(child: Text('courses.no_courses'.tr()));
                    }
                    return ListView.builder(
                      itemCount: state.courses.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final c = state.courses[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.school),
                            title: Text(c.fullName),
                            subtitle: Text(
                              c.shortName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              context.push(
                                '/student/course/${c.id}?title=${Uri.encodeComponent(c.fullName)}',
                              );
                            },
                          ),
                        );
                      },
                    );
                  }
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('common.search'.tr()),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
