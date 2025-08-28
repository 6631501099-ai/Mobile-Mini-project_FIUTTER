import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
// ตัวแปรเก็บข้อมูลผู้ใช้ที่ล็อกอิน
String? username;
String? userId;
//yaya
// auto
// ฟังก์ชันช่วย parse จำนวนเงิน
num parsePaid(dynamic value) {
  if (value == null) return 0;
  if (value is int || value is double) return value;
  return num.tryParse(value.toString()) ?? 0;
}

void main() async {
  bool isLoggedIn = false;

  while (!isLoggedIn) {
    isLoggedIn = await login();
  }

  while (true) {
    print("========== Expense Tracking App ==========");
    print("Welcome $username");

    print("1. All expenses");
    print("2. Today's expense");
    print("3. Search expense");
    print("4. Add new expense");
    print("5. Delete an expense");
    print("6. Exit");

    stdout.write("Choose... ");
    String? choose = stdin.readLineSync()?.trim();
    switch (choose) {
      case '1':
        await showAllExpenses();
        break;
      case '2':
        await showTodaysExpenses();
        break;
      case '3':
        await searchExpenses();
        break;
      case '4':
        await addNewExpense();
        break;
      case '5':
        await deleteExpense();
        break;
      case '6':
        print("----- Bye -----");
        return;
      default:
        print("Please try again.");
    }
  }
}

Future<void> searchExpenses() async {
  stdout.write("Item to search: ");
  String? itemName = stdin.readLineSync()?.trim();

  if (itemName == null || itemName.isEmpty) {
    print("Invalid input");
    return;
  }

  final url = Uri.parse('http://localhost:3000/search?item=$itemName');
  final response = await http.get(url);

  if (response.statusCode == 404) {
    print("No item: $itemName");
    return;
  } else if (response.statusCode != 200) {
    print('Failed to retrieve expenses');
    return;
  }

  final jsonResult = json.decode(response.body) as List;
  num total = 0;

  for (var exp in jsonResult) {
    final dt = DateTime.parse(exp['date']).toLocal();
    final paid = parsePaid(exp['amount']); // แก้จาก exp['paid'] เป็น exp['amount']
    print("${exp['id']}. ${exp['item']} : ${paid}฿ : $dt");
    total += paid;
  }

  print("Total = $total฿");
}

Future<bool> login() async {
  print("===== Login =====");
  stdout.write("Username: ");
  username = stdin.readLineSync()?.trim();

  stdout.write("Password: ");
  String? password = stdin.readLineSync()?.trim();

  if (username == null || password == null) {
    print("Incomplete input");
    return false;
  }

  final body = json.encode({"username": username, "password": password});
  final url = Uri.parse('http://localhost:3000/login');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final result = json.decode(response.body);
    userId = result['user_id'].toString();
    return true;
  } else {
    final result = response.body;
    print("Error: $result");
    return false;
  }
}

Future<void> addNewExpense() async {
  print("===== Add new item =====");
  stdout.write("Item: ");
  String? item = stdin.readLineSync()?.trim();

  stdout.write("Paid: ");
  String? paidStr = stdin.readLineSync()?.trim();

  if (item == null ||
      paidStr == null ||
      item.isEmpty ||
      paidStr.isEmpty ||
      userId == null) {
    print("Incomplete input or user not logged in");
    return;
  }

  num paid;
  try {
    paid = num.parse(paidStr);
  } catch (e) {
    print("Invalid amount entered.");
    return;
  }

  final body = json.encode({
    "item": item,
    "amount": paid, // เปลี่ยนจาก paid เป็น amount
    "userId": userId, // เปลี่ยนจาก user_id เป็น userId
  });

  final url = Uri.parse('http://localhost:3000/expenses');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 201) {
    print("Inserted!");
  } else {
    print("Failed to insert the expense. Status code: ${response.statusCode}");
    print("Response: ${response.body}");
  }
}

Future<void> deleteExpense() async {
  print("===== Delete an Item =====");
  stdout.write("Item id: ");
  String? id = stdin.readLineSync()?.trim();

  if (id == null || id.isEmpty) {
    print("Invalid ID");
    return;
  }

  final url = Uri.parse('http://localhost:3000/expenses/$id');
  final response = await http.delete(url);

  if (response.statusCode == 200) {
    print("Deleted!");
  } else if (response.statusCode == 404) {
    print("Expense not found");
  } else {
    print("Failed to delete expense");
  }
}

Future<void> showAllExpenses() async {
  final url = Uri.parse('http://localhost:3000/expenses');
  final response = await http.get(url);

  if (response.statusCode != 200) {
    print('Failed to retrieve expenses');
    return;
  }

  final jsonResult = json.decode(response.body) as List;
  num total = 0;
  print("-------------All expenses-------------");

  for (var exp in jsonResult) {
    final dt = DateTime.parse(exp['date']).toLocal();
    final paid = parsePaid(
      exp['amount'],
    ); // แก้จาก exp['paid'] เป็น exp['amount']
    print("${exp['id']}. ${exp['item']} : ${paid}฿ : $dt");
    total += paid;
  }

  print("Total expenses = $total฿");
}

Future<void> showTodaysExpenses() async {
  final url = Uri.parse('http://localhost:3000/expenses');
  final response = await http.get(url);

  if (response.statusCode != 200) {
    print('Failed to retrieve expenses');
    return;
  }

  final jsonResult = json.decode(response.body) as List;
  final today = DateTime.now().toLocal();
  num total = 0;
  print("-----------Today's expenses-----------");

  for (var exp in jsonResult) {
    final dt = DateTime.parse(exp['date']).toLocal();
    final paid = parsePaid(exp['amount']); // แก้จาก exp['paid'] เป็น exp['amount']
    if (dt.year == today.year &&
        dt.month == today.month &&
        dt.day == today.day) {
      print("${exp['id']}. ${exp['item']} : ${paid}฿ : $dt");
      total += paid;
    }
  }

  print("Total expenses = $total฿");
}
