import 'package:flutter/material.dart';

import '../models/todo.dart';
import '../models/todo_list.dart';
import '../database/database_helper.dart';

enum _TodoFilter { all, active, done }

class TodoScreen extends StatefulWidget {
  final TodoList list;
  final List<Todo> todos;
  final Function(List<Todo>) onTodosChanged;

  const TodoScreen({
    super.key,
    required this.list,
    required this.todos,
    required this.onTodosChanged,
  });

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  late List<Todo> _todos;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  _TodoFilter _filter = _TodoFilter.all;

  @override
  void initState() {
    super.initState();
    _todos = List.from(widget.todos);
  }

  List<Todo> get _visibleTodos {
    switch (_filter) {
      case _TodoFilter.active:
        return _todos.where((todo) => !todo.isCompleted).toList();
      case _TodoFilter.done:
        return _todos.where((todo) => todo.isCompleted).toList();
      case _TodoFilter.all:
        return _todos;
    }
  }

  int get _completedCount => _todos.where((todo) => todo.isCompleted).length;

  Future<void> _addTodo() async {
    if (_textController.text.trim().isEmpty) return;

    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      listId: widget.list.id,
      title: _textController.text.trim(),
    );

    await DatabaseHelper.instance.createTodo(newTodo);

    setState(() {
      _todos.add(newTodo);
      _textController.clear();
    });
    widget.onTodosChanged(_todos);
    _focusNode.unfocus();
  }

  Future<void> _deleteTodo(String id) async {
    await DatabaseHelper.instance.deleteTodo(id);

    setState(() {
      _todos.removeWhere((todo) => todo.id == id);
    });
    widget.onTodosChanged(_todos);
  }

  Future<void> _toggleTodo(String id) async {
    setState(() {
      final todo = _todos.firstWhere((todo) => todo.id == id);
      todo.toggleComplete();
    });

    final todo = _todos.firstWhere((todo) => todo.id == id);
    await DatabaseHelper.instance.updateTodo(todo);

    widget.onTodosChanged(_todos);
  }

  void _setFilter(_TodoFilter filter) {
    setState(() {
      _filter = filter;
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completedCount;
    final totalCount = _todos.length;
    final visibleTodos = _visibleTodos;

    return Scaffold(
      backgroundColor: const Color(0xff0e0f1f),
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade400,
                  Colors.purple.shade500,
                  Colors.pink.shade400,
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
                color: Colors.white.withValues(alpha: 0.08),
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
                color: Colors.white.withValues(alpha: 0.05),
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
                          IconButton(
                            splashRadius: 24,
                            onPressed: () => Navigator.pop(context),
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: const Icon(
                              Icons.task_alt,
                              color: Colors.white,
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
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                widget.list.name,
                                style: const TextStyle(
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
                            onPressed: _focusNode.requestFocus,
                            icon: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add,
                                color: Colors.deepPurple.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  height: 72,
                                  width: 72,
                                  child: CircularProgressIndicator(
                                    value: totalCount == 0 ? 0 : completedCount / totalCount,
                                    strokeWidth: 8,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.greenAccent.shade200,
                                    ),
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      totalCount == 0
                                          ? '0%'
                                          : '${((completedCount / totalCount) * 100).round()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      'done',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    totalCount == 0
                                        ? 'Nothing scheduled yet'
                                        : '$completedCount of $totalCount completed',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    totalCount == 0
                                        ? 'Add your first task to get momentum.'
                                        : 'Stay consistent and clear the deck.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 13,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (totalCount > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: LinearProgressIndicator(
                                          value: completedCount / totalCount,
                                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.greenAccent.shade200,
                                          ),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _TodoFilter.values
                            .map(
                              (filter) => Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: ChoiceChip(
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        filter == _TodoFilter.all
                                            ? Icons.layers
                                            : filter == _TodoFilter.active
                                                ? Icons.radio_button_unchecked
                                                : Icons.task_alt,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        filter == _TodoFilter.all
                                            ? 'All'
                                            : filter == _TodoFilter.active
                                                ? 'Active'
                                                : 'Done',
                                      ),
                                    ],
                                  ),
                                  selected: _filter == filter,
                                  onSelected: (_) => _setFilter(filter),
                                  selectedColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: _filter == filter
                                        ? Colors.deepPurple.shade600
                                        : Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                                  shape: StadiumBorder(
                                    side: BorderSide(
                                      color: _filter == filter
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: _textController,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Add a task with intent...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.edit_outlined,
                                  color: Colors.deepPurple.shade300,
                                ),
                                suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                suffixIcon: Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      backgroundColor: Colors.deepPurple.shade500,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _addTodo,
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 18, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              onSubmitted: (_) => _addTodo(),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: visibleTodos.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.incomplete_circle_outlined,
                                          size: 74,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(height: 14),
                                        Text(
                                          _filter == _TodoFilter.done
                                              ? 'Nothing completed yet'
                                              : 'No tasks to show',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _filter == _TodoFilter.done
                                              ? 'Finish something to see it here.'
                                              : 'Add a task or change the filter.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
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
                                    itemCount: visibleTodos.length,
                                    itemBuilder: (context, index) {
                                      final todo = visibleTodos[index];
                                      return _TodoItem(
                                        key: ValueKey(todo.id),
                                        todo: todo,
                                        onToggle: () => _toggleTodo(todo.id),
                                        onDelete: () => _deleteTodo(todo.id),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('dismiss-${todo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red.shade300,
              Colors.red.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: todo.isCompleted
                ? [
                    Colors.greenAccent.shade100.withValues(alpha: 0.24),
                    Colors.greenAccent.shade100.withValues(alpha: 0.14),
                  ]
                : [
                    Colors.white,
                    Colors.white,
                  ],
          ),
          border: Border.all(
            color: todo.isCompleted
                ? Colors.greenAccent.shade100
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: todo.isCompleted
                            ? Colors.greenAccent.shade400
                            : Colors.deepPurple.shade200,
                        width: 2,
                      ),
                      color: todo.isCompleted
                          ? Colors.greenAccent.shade400
                          : Colors.transparent,
                    ),
                    child: todo.isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: todo.isCompleted
                                ? Colors.grey.shade500
                                : Colors.grey.shade800,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          todo.isCompleted
                              ? 'Completed'
                              : 'Tap to mark done',
                          style: TextStyle(
                            fontSize: 12,
                            color: todo.isCompleted
                                ? Colors.green.shade600
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    splashRadius: 22,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade300,
                      size: 22,
                    ),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

