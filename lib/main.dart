import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const TaskPlannerApp());
}

class TaskPlannerApp extends StatelessWidget {
  const TaskPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Planner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [
    Task(
      name: 'Example Task',
      dueDate: DateTime.now().add(const Duration(minutes: 1)),
    ),
  ];

  bool useAlternateDateFormat = false;

  void _addTask() {
    TextEditingController taskController = TextEditingController();
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Task'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: taskController,
                decoration: const InputDecoration(hintText: 'Enter task name'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2101),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(selectedDateTime == null
                    ? 'Pick Date and Time'
                    : 'Selected: ${selectedDateTime.toString()}'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (taskController.text.isNotEmpty && selectedDateTime != null) {
                  setState(() {
                    tasks.add(Task(name: taskController.text, dueDate: selectedDateTime!));
                  });
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          useAlternateDateFormat: useAlternateDateFormat,
          onDateFormatChange: (value) {
            setState(() {
              useAlternateDateFormat = value;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Planner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No tasks yet!'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskItem(
                  task: tasks[index],
                  useAlternateDateFormat: useAlternateDateFormat,
                  onDelete: () {
                    setState(() {
                      tasks.removeAt(index);
                    });
                  },
                  onUpdate: () {
                    setState(() {});
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class Task {
  final String name;
  final DateTime dueDate;
  Duration remainingTime;
  Timer? timer;

  Task({required this.name, required this.dueDate})
      : remainingTime = dueDate.difference(DateTime.now());

  void startTimer(VoidCallback onTick) {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingTime = dueDate.difference(DateTime.now());
      if (remainingTime.inSeconds > 0) {
        onTick();
      } else {
        timer.cancel();
        onTick();
      }
    });
  }

  void stopTimer() {
    timer?.cancel();
  }

  String formatRemainingTime() {
    if (remainingTime.inSeconds <= 0) {
      return "Task completed!";
    }

    final days = remainingTime.inDays;
    final hours = remainingTime.inHours % 24;
    final minutes = remainingTime.inMinutes % 60;
    final seconds = remainingTime.inSeconds % 60;

    if (days >= 30) {
      final months = days ~/ 30;
      return "$months months ${days % 30} days";
    } else if (days > 0) {
      return "$days days $hours hours";
    } else if (hours > 0) {
      return "$hours hours $minutes minutes";
    } else if (minutes > 0) {
      return "$minutes minutes $seconds seconds";
    } else {
      return "$seconds seconds";
    }
  }

  String formatDueDate(bool useAlternateFormat) {
    return useAlternateFormat
        ? "${dueDate.month.toString().padLeft(2, '0')}/${dueDate.day.toString().padLeft(2, '0')}/${dueDate.year} ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}"
        : "${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')} ${dueDate.hour.toString().padLeft(2, '0')}:${dueDate.minute.toString().padLeft(2, '0')}";
  }
}

class TaskItem extends StatefulWidget {
  final Task task;
  final bool useAlternateDateFormat;
  final VoidCallback onDelete;
  final VoidCallback onUpdate;

  const TaskItem({super.key, 
    required this.task,
    required this.useAlternateDateFormat,
    required this.onDelete,
    required this.onUpdate,
  });

  @override
  _TaskItemState createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  @override
  void initState() {
    super.initState();
    widget.task.startTimer(widget.onUpdate);
  }

  @override
  void dispose() {
    widget.task.stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text(widget.task.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Due: ${widget.task.formatDueDate(widget.useAlternateDateFormat)}'),
            Text(
              widget.task.formatRemainingTime(),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  final bool useAlternateDateFormat;
  final ValueChanged<bool> onDateFormatChange;

  const SettingsScreen({super.key, 
    required this.useAlternateDateFormat,
    required this.onDateFormatChange,
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isAlternateFormat;

  @override
  void initState() {
    super.initState();
    isAlternateFormat = widget.useAlternateDateFormat;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Date Format'),
              subtitle: Text(
                isAlternateFormat ? "MM/DD/YYYY HH:MM" : "YYYY-MM-DD HH:MM",
              ),
              trailing: Switch(
                value: isAlternateFormat,
                onChanged: (value) {
                  setState(() {
                    isAlternateFormat = value;
                  });
                  widget.onDateFormatChange(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
