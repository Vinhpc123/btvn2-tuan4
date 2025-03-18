import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';



void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UTH SmartTasks',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TaskListScreen(),
    );
  }
}

// Màn hình danh sách nhiệm vụ
class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List tasks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // Gọi API danh sách nhiệm vụ
  Future<void> fetchTasks() async {
    try {
      final response =
      await http.get(Uri.parse('https://amock.io/api/researchUTH/tasks'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['isSuccess'] == true) {
          setState(() {
            tasks = responseData['data'];
            isLoading = false;
          });
        } else {
          throw Exception('API returned error');
        }
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task List")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? Center(child: Text("No Tasks Yet!"))
          : ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];

          return ListTile(
            title: Text(task['title']),
            subtitle: Text(task['description']),
            trailing:
            Icon(Icons.arrow_forward_ios, color: Colors.blue),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    TaskDetailScreen(task: task), // Truyền toàn bộ task
              ),
            ),
          );
        },
      ),
    );
  }
}

// Màn hình chi tiết nhiệm vụ

class TaskDetailScreen extends StatelessWidget {
  final Map task;

  TaskDetailScreen({required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Task Details")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: task.isNotEmpty
            ? SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task['title'] ?? "No Title",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(task['description'] ?? "No Description"),
              SizedBox(height: 10),
              Text("Category: ${task['category'] ?? 'N/A'}"),
              Text("Priority: ${task['priority'] ?? 'N/A'}"),
              Text("Status: ${task['status'] ?? 'N/A'}"),
              SizedBox(height: 10),

              // Hiển thị công việc con (Subtasks)
              Text("Subtasks:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...?task['subtasks']?.map<Widget>((subtask) => ListTile(
                title: Text(subtask['title']),
                trailing: Icon(
                  subtask['isCompleted']
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: subtask['isCompleted'] ? Colors.green : Colors.red,
                ),
              )),
              SizedBox(height: 10),

              // Hiển thị danh sách tệp đính kèm (Attachments)
              Text("Attachments:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...?task['attachments']?.map<Widget>((attachment) => ListTile(
                title: Text(attachment['fileName']),
                trailing: Icon(Icons.link, color: Colors.blue),
                onTap: () => _launchURL(attachment['fileUrl']),
              )),
              SizedBox(height: 10),

              // Hiển thị danh sách lời nhắc (Reminders)
              Text("Reminders:", style: TextStyle(fontWeight: FontWeight.bold)),
              ...?task['reminders']?.map<Widget>((reminder) => ListTile(
                title: Text("Time: ${reminder['time']}"),
                subtitle: Text("Type: ${reminder['type']}"),
                leading: Icon(Icons.alarm, color: Colors.orange),
              )),
            ],
          ),
        )
            : Center(child: Text("Task not found!")),
      ),
    );
  }

  // Mở link tệp đính kèm
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not open URL: $url");
    }
  }
}
