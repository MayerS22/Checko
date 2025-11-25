import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../database/database_helper.dart';
import 'todo_screen.dart';
import '../theme/app_colors.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final List<TodoList> _lists = [];
  final List<Todo> _allTodos = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final lists = await DatabaseHelper.instance.readAllTodoLists();
    final todos = await DatabaseHelper.instance.readAllTodos();

    setState(() {
      _lists.clear();
      _lists.addAll(lists);
      _allTodos.clear();
      _allTodos.addAll(todos);
      _isLoading = false;
    });

    // If no lists exist, create a default one
    if (_lists.isEmpty) {
      await _createDefaultList();
    }
  }

  Future<void> _createDefaultList() async {
    final defaultList = TodoList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'My Tasks',
      description: 'Default task list',
      color: AppColors.accent.toARGB32(),
    );

    await DatabaseHelper.instance.createTodoList(defaultList);
    setState(() {
      _lists.add(defaultList);
    });
  }

  List<Todo> _getTodosForList(String listId) {
    return _allTodos.where((todo) => todo.listId == listId).toList();
  }

  int _getCompletedCount(String listId) {
    return _getTodosForList(listId)
        .where((todo) => todo.isCompleted)
        .length;
  }

  double _getProgressPercentage(String listId) {
    final todos = _getTodosForList(listId);
    if (todos.isEmpty) return 0.0;
    final completed = todos.where((todo) => todo.isCompleted).length;
    return completed / todos.length;
  }

  List<Todo> _getSearchResults() {
    if (_searchQuery.isEmpty) return [];
    return _allTodos
        .where((todo) =>
            todo.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _addList() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int selectedColor = AppColors.accent.toARGB32();

    final colors = [
      0xFF9C27B0, // Purple
      0xFFF44336, // Red
      0xFF2196F3, // Blue
      0xFF4CAF50, // Green
      0xFFFF9800, // Orange
      0xFFE91E63, // Pink
      0xFF00BCD4, // Cyan
      0xFFFF5722, // Deep Orange
    ];

    final result = await showDialog<TodoList>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Create New List',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'List Name',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: AppColors.textMuted),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Color',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(color),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final newList = TodoList(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    color: selectedColor,
                  );
                  Navigator.pop(context, newList);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await DatabaseHelper.instance.createTodoList(result);
      setState(() {
        _lists.add(result);
      });
    }
  }

  Future<void> _deleteList(String listId) async {
    await DatabaseHelper.instance.deleteTodoList(listId);
    setState(() {
      _lists.removeWhere((list) => list.id == listId);
      _allTodos.removeWhere((todo) => todo.listId == listId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
          ),
        ),
      );
    }

    final searchResults = _getSearchResults();
    final showSearchResults = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xff0c1224),
                  const Color(0xff111c34),
                  const Color(0xff18294a),
                ],
              ),
            ),
          ),
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            left: -20,
            top: 40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentAlt.withValues(alpha: 0.14),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.outline,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.folder_special,
                              color: AppColors.accentAlt,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Checko',
                                style: TextStyle(
                                  color: AppColors.textMuted.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Text(
                                'My Lists',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            splashRadius: 24,
                            onPressed: _addList,
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.accent,
                                    AppColors.accentAlt,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.outline,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Search todos across all lists...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.8),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors.textMuted,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      border: const Border(
                        top: BorderSide(color: AppColors.outline),
                      ),
                    ),
                    child: showSearchResults
                        ? _buildSearchResults(searchResults)
                        : _buildListsView(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Todo> results) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            '${results.length} result${results.length == 1 ? '' : 's'} found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 74,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final todo = results[index];
                    final list = _lists.firstWhere(
                      (l) => l.id == todo.listId,
                      orElse: () => TodoList(id: '', name: 'Unknown'),
                    );
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Color(list.color),
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(
                          todo.title,
                          style: TextStyle(
                            color: Colors.white,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          list.name,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          todo.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: todo.isCompleted
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TodoScreen(
                                list: list,
                                todos: _getTodosForList(list.id),
                                onTodosChanged: (todos) {
                                  setState(() {
                                    _allTodos.removeWhere(
                                        (t) => t.listId == list.id);
                                    _allTodos.addAll(todos);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildListsView() {
    return Column(
      children: [
        const SizedBox(height: 18),
        Expanded(
          child: _lists.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 74,
                        color: AppColors.textMuted.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No lists yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your first list to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate responsive crossAxisCount and childAspectRatio
                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = screenWidth > 600 ? 3 : 2;
                    final aspectRatio = screenWidth > 600 ? 0.75 : 0.82;
                    
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: _lists.length,
                      itemBuilder: (context, index) {
                        final list = _lists[index];
                        final todos = _getTodosForList(list.id);
                        final completedCount = _getCompletedCount(list.id);
                        final progress = _getProgressPercentage(list.id);

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TodoScreen(
                                  list: list,
                                  todos: todos,
                                  onTodosChanged: (updatedTodos) {
                                    setState(() {
                                      _allTodos.removeWhere((t) => t.listId == list.id);
                                      _allTodos.addAll(updatedTodos);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            if (_lists.length > 1) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete List'),
                                  content: Text(
                                      'Are you sure you want to delete "${list.name}"? All todos in this list will be deleted.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      onPressed: () {
                                        _deleteList(list.id);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(list.color),
                                  Color(list.color).withValues(alpha: 0.8),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(list.color).withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.folder,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_lists.length > 1)
                                        Icon(
                                          Icons.more_vert,
                                          color: Colors.white.withValues(alpha: 0.7),
                                          size: 18,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Flexible(
                                    child: Text(
                                      list.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (list.description != null) ...[
                                    const SizedBox(height: 4),
                                    Flexible(
                                      child: Text(
                                        list.description!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 11,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.task_alt,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '${todos.length} task${todos.length == 1 ? '' : 's'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              todos.isEmpty
                                                  ? 'No tasks'
                                                  : '$completedCount of ${todos.length} done',
                                              style: TextStyle(
                                                color: Colors.white.withValues(alpha: 0.95),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '${(progress * 100).round()}%',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.95),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                          minHeight: 5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        ),
                      ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
