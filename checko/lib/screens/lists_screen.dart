import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../models/todo_list.dart';
import '../database/firestore_service.dart';
import '../providers/user_provider.dart';
import 'todo_screen.dart';
import '../theme/app_colors.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  // Protected default list names that cannot be deleted
  static const List<String> _protectedListNames = [
    'My Day',
    'Planned',
    'Books',
  ];

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

    final lists = await FirestoreService.instance.readAllTodoLists();
    final todos = await FirestoreService.instance.readAllTodos();

    setState(() {
      _lists.clear();
      _lists.addAll(lists);
      _allTodos.clear();
      _allTodos.addAll(todos);
      _isLoading = false;
    });

    // Create default lists if they don't exist
    await _createDefaultLists();
  }

  Future<void> _createDefaultLists() async {
    final defaultListsData = [
      {
        'name': 'My Day',
        'icon': Icons.wb_sunny,
        'color': 0xFFFF9800,
        'description': 'Tasks for today',
      },
      {
        'name': 'Planned',
        'icon': Icons.calendar_today,
        'color': 0xFF2196F3,
        'description': 'Scheduled tasks',
      },
      {
        'name': 'Books',
        'icon': Icons.menu_book,
        'color': 0xFF9C27B0,
        'description': 'Reading list',
      },
    ];

    for (final listData in defaultListsData) {
      final exists = _lists.any((l) => l.name == listData['name']);
      if (!exists) {
        final newList = TodoList(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              listData['name'].toString().hashCode.toString(),
          name: listData['name'] as String,
          description: listData['description'] as String,
          color: listData['color'] as int,
        );
        final created = await FirestoreService.instance.createTodoList(newList);
        setState(() {
          _lists.add(created);
        });
      }
    }
  }

  bool _isProtectedList(TodoList list) {
    return _protectedListNames.contains(list.name);
  }

  Future<void> _quickAddTask() async {
    if (_lists.isEmpty) return;

    final titleController = TextEditingController();
    TodoList? selectedList = _lists.first;
    Priority selectedPriority = Priority.medium;
    DateTime? selectedDate;

    final result = await showDialog<Todo>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.isDarkMode
              ? AppColors.panel
              : AppColors.lightPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Add Task',
            style: TextStyle(
              color: context.textPrimaryColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Task name',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 20),
                Text(
                  'Add to list',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.outlineColor),
                  ),
                  child: DropdownButton<TodoList>(
                    value: selectedList,
                    isExpanded: true,
                    dropdownColor: context.surfaceColor,
                    underline: const SizedBox(),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: context.textMutedColor,
                    ),
                    items: _lists.map((list) {
                      return DropdownMenuItem<TodoList>(
                        value: list,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(list.color),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              list.name,
                              style: TextStyle(color: context.textPrimaryColor),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedList = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Priority',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: Priority.values.map((priority) {
                    final isSelected = selectedPriority == priority;
                    final color = priority == Priority.high
                        ? AppColors.priorityHigh
                        : priority == Priority.medium
                        ? AppColors.priorityMedium
                        : AppColors.priorityLow;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setDialogState(() => selectedPriority = priority),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.2)
                                : context.surfaceColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? color : context.outlineColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              priority == Priority.high
                                  ? 'High'
                                  : priority == Priority.medium
                                  ? 'Med'
                                  : 'Low',
                              style: TextStyle(
                                color: isSelected
                                    ? color
                                    : context.textMutedColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.outlineColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate != null
                              ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                              : 'Set due date (optional)',
                          style: TextStyle(color: context.textPrimaryColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: context.textMutedColor,
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
              ),
              onPressed: () {
                if (titleController.text.trim().isNotEmpty &&
                    selectedList != null) {
                  final newTodo = Todo(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    listId: selectedList!.id,
                    title: titleController.text.trim(),
                    priority: selectedPriority,
                    dueDate: selectedDate,
                    order: _allTodos
                        .where((t) => t.listId == selectedList!.id)
                        .length,
                  );
                  Navigator.pop(context, newTodo);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final created = await FirestoreService.instance.createTodo(result);
      setState(() {
        _allTodos.add(created);
      });
    }
  }

  List<Todo> _getTodosForList(String listId) {
    return _allTodos.where((todo) => todo.listId == listId).toList();
  }

  int _getCompletedCount(String listId) {
    return _getTodosForList(listId).where((todo) => todo.isCompleted).length;
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
        .where(
          (todo) =>
              todo.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (todo.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                  false),
        )
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
          backgroundColor: context.isDarkMode
              ? AppColors.panel
              : AppColors.lightPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Create New List',
            style: TextStyle(
              color: context.textPrimaryColor,
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
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Color',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimaryColor,
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
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
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
                foregroundColor: context.textMutedColor,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
      await FirestoreService.instance.createTodoList(result);
      setState(() {
        _lists.add(result);
      });
    }
  }

  Future<void> _editList(TodoList list) async {
    final nameController = TextEditingController(text: list.name);
    final descController = TextEditingController(text: list.description ?? '');
    int selectedColor = list.color;

    final colors = [
      0xFF9C27B0,
      0xFFF44336,
      0xFF2196F3,
      0xFF4CAF50,
      0xFFFF9800,
      0xFFE91E63,
      0xFF00BCD4,
      0xFFFF5722,
    ];

    final result = await showDialog<TodoList>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: context.isDarkMode
              ? AppColors.panel
              : AppColors.lightPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Edit List',
            style: TextStyle(
              color: context.textPrimaryColor,
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
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: TextStyle(color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: TextStyle(color: context.textMutedColor),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose Color',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: context.textPrimaryColor,
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
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
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
                foregroundColor: context.textMutedColor,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  final updatedList = TodoList(
                    id: list.id,
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    color: selectedColor,
                  );
                  Navigator.pop(context, updatedList);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await FirestoreService.instance.updateTodoList(result);
      setState(() {
        final index = _lists.indexWhere((l) => l.id == result.id);
        if (index != -1) {
          _lists[index] = result;
        }
      });
    }
  }

  Future<void> _confirmDeleteList(TodoList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.isDarkMode
            ? AppColors.panel
            : AppColors.lightPanel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete List',
          style: TextStyle(
            color: context.textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${list.name}"? All todos in this list will be deleted.',
          style: TextStyle(color: context.textMutedColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textMutedColor),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteList(list.id);
    }
  }

  Future<void> _deleteList(String listId) async {
    await FirestoreService.instance.deleteTodoList(listId);
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
    final userProvider = context.watch<UserProvider>();

    if (_isLoading) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    final searchResults = _getSearchResults();
    final showSearchResults = _searchQuery.isNotEmpty;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _quickAddTask,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: context.isDarkMode
                    ? [
                        const Color(0xff0c1224),
                        const Color(0xff111c34),
                      ]
                    : [
                        AppColors.lightBackground,
                        AppColors.accent.withValues(alpha: 0.08),
                      ],
              ),
            ),
          ),
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${userProvider.username} 👋',
                                  style: TextStyle(
                                    color: context.textPrimaryColor,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Let\'s organize your day',
                                  style: TextStyle(
                                    color: context.textMutedColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🔥', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${userProvider.currentStreak}',
                                      style: TextStyle(
                                        color: context.textPrimaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: _addList,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [AppColors.accent, AppColors.accentAlt],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent.withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.outlineColor.withValues(alpha: 0.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                          style: TextStyle(color: context.textPrimaryColor),
                          decoration: InputDecoration(
                            hintText: 'Search your tasks...',
                            hintStyle: TextStyle(
                              color: context.textMutedColor.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: context.textMutedColor.withValues(alpha: 0.7),
                              size: 22,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear,
                                      color: context.textMutedColor,
                                      size: 20,
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
                      color: context.panelColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                      border: Border(
                        top: BorderSide(color: context.outlineColor),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textPrimaryColor,
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
                        color: context.textMutedColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No results found',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
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
                        color: context.surfaceColor,
                        border: Border.all(color: context.outlineColor),
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
                            color: context.textPrimaryColor,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          list.name,
                          style: TextStyle(
                            color: context.textMutedColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          todo.isCompleted
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: todo.isCompleted
                              ? AppColors.success
                              : context.textMutedColor,
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
                                      (t) => t.listId == list.id,
                                    );
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
                        color: context.textMutedColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No lists yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your first list to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textMutedColor.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = screenWidth > 600 ? 3 : 2;
                    final aspectRatio = screenWidth > 600 ? 0.75 : 0.82;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 4,
                      ),
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
                                      _allTodos.removeWhere(
                                        (t) => t.listId == list.id,
                                      );
                                      _allTodos.addAll(updatedTodos);
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: context.panelColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: const Icon(
                                        Icons.edit,
                                        color: AppColors.accent,
                                      ),
                                      title: Text(
                                        'Edit List',
                                        style: TextStyle(
                                          color: context.textPrimaryColor,
                                        ),
                                      ),
                                      onTap: () {
                                        Navigator.pop(context);
                                        _editList(list);
                                      },
                                    ),
                                    if (!_isProtectedList(list))
                                      ListTile(
                                        leading: const Icon(
                                          Icons.delete,
                                          color: AppColors.danger,
                                        ),
                                        title: Text(
                                          'Delete List',
                                          style: TextStyle(
                                            color: context.textPrimaryColor,
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _confirmDeleteList(list);
                                        },
                                      )
                                    else
                                      ListTile(
                                        leading: Icon(
                                          Icons.lock_outline,
                                          color: context.textMutedColor,
                                        ),
                                        title: Text(
                                          'This list cannot be deleted',
                                          style: TextStyle(
                                            color: context.textMutedColor,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(list.color).withValues(alpha: 0.85),
                                  Color(list.color).withValues(alpha: 0.95),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(list.color).withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.1),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
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
                                            color: Colors.white.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.folder_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          _isProtectedList(list)
                                              ? Icons.lock_outline
                                              : Icons.more_vert,
                                          color: Colors.white.withValues(alpha: 0.7),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      list.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (list.description != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        list.description!,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${todos.length} task${todos.length == 1 ? '' : 's'}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            todos.isEmpty
                                                ? 'No tasks'
                                                : '$completedCount/${todos.length}',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.9),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${(progress * 100).round()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
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
                                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        minHeight: 5,
                                      ),
                                    ),
                                  ],
                                ),
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
