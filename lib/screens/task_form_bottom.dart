import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import 'package:intl/intl.dart';

Future<void> showTaskFormBottomSheet(BuildContext context, {Task? task}) async {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController =
      TextEditingController(text: task?.title ?? "");
  final TextEditingController descController =
      TextEditingController(text: task?.description ?? "");

  DateTime? selectedDateTime = task?.due;
  String selectedPriority = task?.priority ?? "Medium";
  final List<String> priorities = ["High", "Medium", "Low"];

  String formatDueDate(DateTime dateTime) {
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

  Future<void> pickDueDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
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
        selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
  }

  final taskProvider = context.read<TaskProvider>();

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true, // biar full tinggi bisa scroll
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Text(
                task == null ? "Add Task" : "Edit Task",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              // Task name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Task Name"),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? "Task name cannot be empty"
                        : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Due date
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDateTime == null
                          ? "No due date selected"
                          : "Due: ${formatDueDate(selectedDateTime!)}",
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await pickDueDateTime();
                    },
                    child: const Text("Select Date"),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Priority
              DropdownButtonFormField<String>(
                value: selectedPriority,
                items: priorities
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) => selectedPriority = val ?? "Medium",
                decoration: const InputDecoration(labelText: "Priority"),
              ),
              const SizedBox(height: 24),

              // Save + Delete button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (task != null)
                    TextButton.icon(
                      onPressed: () {
                        taskProvider.deleteTask(task.id);
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newTask = Task(
                          id: task?.id ?? DateTime.now().toString(),
                          title: nameController.text.trim(),
                          description: descController.text.trim(),
                          due: selectedDateTime ?? DateTime.now(),
                          priority: selectedPriority,
                          isDone: task?.isDone ?? false,
                        );

                        if (task == null) {
                          taskProvider.addTask(newTask);
                        } else {
                          taskProvider.updateTask(newTask);
                        }
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text("Save"),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
