import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../providers/task_provider.dart';
import 'task_form_bottom.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  String _formatDue(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDateOnly = DateTime(due.year, due.month, due.day);
    final diffDays = dueDateOnly.difference(today).inDays;
    final timePart = DateFormat('h:mm a').format(due);

    if (diffDays == 0) return 'Today, $timePart';
    if (diffDays == 1) return 'Tomorrow, $timePart';
    return DateFormat('d MMM yyyy, h:mm a').format(due);
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.tasks;

    final filteredTasks = _selectedDay == null
        ? tasks
        : tasks.where((task) {
            if (task.due == null) return false;
            return task.due!.year == _selectedDay!.year &&
                task.due!.month == _selectedDay!.month &&
                task.due!.day == _selectedDay!.day;
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hi User!",
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "You have something to-do today.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // calendar (weekly)
              TableCalendar(
                focusedDay: _focusedDay,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                calendarFormat: CalendarFormat.week,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                  weekendStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: GoogleFonts.inter(fontSize: 14),
                  weekendTextStyle: GoogleFonts.inter(fontSize: 14),
                  selectedTextStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  todayTextStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              // task list
              Expanded(
                child: filteredTasks.isEmpty
                    ? const Center(
                        child: Text("No tasks for this day, add one!"),
                      )
                    : ListView.builder(
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          final task = filteredTasks[index];

                          // warna priority
                          Color priorityColor;
                          String priorityLabel;
                          switch (task.priority) {
                            case "High":
                              priorityColor = Colors.red;
                              priorityLabel = "High Priority";
                              break;
                            case "Medium":
                              priorityColor = Colors.yellow[700]!;
                              priorityLabel = "Medium Priority";
                              break;
                            case "Low":
                              priorityColor = Colors.green;
                              priorityLabel = "Low Priority";
                              break;
                            default:
                              priorityColor = Colors.grey;
                              priorityLabel = "No Priority";
                          }

                          return Dismissible(
                            key: ValueKey(task.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                // swipe kanan → mark as done
                                taskProvider.updateTask(task.copyWith(isDone: true));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Marked "${task.title}" as done')),
                                );
                                return false; // biar card tidak hilang
                              } else if (direction == DismissDirection.endToStart) {
                                // swipe kiri → delete
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Delete Task'),
                                    content: const Text('Are you sure want to delete this task?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: const Text('Cancel')),
                                      ElevatedButton(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                return confirm ?? false;
                              }
                              return false;
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                taskProvider.deleteTask(task.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Deleted "${task.title}"')),
                                );
                              }
                            },

                            // 👇 Card bisa di-tap untuk edit
                            child: InkWell(
                              onTap: () {
                                showTaskFormBottomSheet(context, task: task);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // title + due
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            task.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              decoration: task.isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        if (task.due != null)
                                          Text(
                                            _formatDue(task.due!),
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (task.description != null)
                                      Text(
                                        task.description!,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.circle,
                                            size: 14, color: priorityColor),
                                        const SizedBox(width: 6),
                                        Text(priorityLabel,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                            )),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ElevatedButton(
        onPressed: () {
          showTaskFormBottomSheet(context); // add task
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4285f4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        ),
        child: Text(
          "+ Add Task",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
