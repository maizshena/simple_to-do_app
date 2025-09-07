import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'package:intl/intl.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? existingTask; // null = add, not null = edit

  const TaskFormScreen({super.key, this.existingTask});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  DateTime? _selectedDateTime;
  String _selectedPriority = "Medium";
  final List<String> _priorities = ["High", "Medium", "Low"];

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      _nameController.text = widget.existingTask!.title;
      _descController.text = widget.existingTask!.description ?? "";
      _selectedDateTime = widget.existingTask!.due;
      _selectedPriority = widget.existingTask!.priority ?? "Medium";
    }
  }

  // format tanggal + jam
  String _formatDueDate(DateTime dateTime) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (dateTime.year == tomorrow.year &&
        dateTime.month == tomorrow.month &&
        dateTime.day == tomorrow.day) {
      return "Tomorrow (${DateFormat.jm().format(dateTime)})";
    } else if (dateTime.difference(now).inDays < 7 &&
        dateTime.weekday != now.weekday) {
      return "${DateFormat.EEEE().format(dateTime)} (${DateFormat.jm().format(dateTime)})";
    } else {
      return "${DateFormat('dd MMMM yyyy').format(dateTime)} (${DateFormat.jm().format(dateTime)})";
    }
  }

  Future<void> _pickDueDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      // ignore: use_build_context_synchronously
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 8, minute: 0),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTask(TaskProvider provider) {
    if (_formKey.currentState!.validate()) {
      final task = Task(
        id: widget.existingTask?.id ?? DateTime.now().toString(),
        title: _nameController.text.trim(),
        description: _descController.text.trim(),
        due: _selectedDateTime ?? DateTime.now(),
        priority: _selectedPriority,
        isDone: widget.existingTask?.isDone ?? false,
      );

      if (widget.existingTask == null) {
        provider.addTask(task);
      } else {  
        provider.updateTask(task);
      }
      Navigator.pop(context);
    }
  }

  void _deleteTask(TaskProvider provider) {
    if (widget.existingTask != null) {
      provider.deleteTask(widget.existingTask!.id);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.read<TaskProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask == null ? "Add Task" : "Edit Task"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // field task name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Task Name"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Task name cannot be empty";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // field description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // field due date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateTime == null
                          ? "No due date selected"
                          : "Due: ${_formatDueDate(_selectedDateTime!)}",
                    ),
                  ),
                  TextButton(
                    onPressed: _pickDueDateTime,
                    child: const Text("Select Date"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // dropdown priority
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                items: _priorities
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedPriority = val ?? "Medium";
                  });
                },
                decoration: const InputDecoration(labelText: "Priority"),
              ),
              const SizedBox(height: 32),

              // tombol save + delete
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.existingTask != null)
                    TextButton.icon(
                      onPressed: () => _deleteTask(taskProvider),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () => _saveTask(taskProvider),
                    child: const Text("Save"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
    
  }
}
