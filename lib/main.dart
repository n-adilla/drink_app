// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:drink_app/menu_list/coffee.dart';
import 'package:drink_app/menu_list/john.dart';
import 'package:drink_app/menu_list/tea.dart';
import 'package:drink_app/models/drink.dart';
import 'package:drink_app/models/order.dart';
import 'package:drink_app/utils/constants.dart';
import 'package:drink_app/utils/unique_id_gen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  int _currentIndex = 0;

  final TextEditingController _customerNameController = TextEditingController();
  String _customerName = ' ';

  void _clearCustomerName() {
    setState(() {
      _customerNameController.clear();
      _customerName = '';
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    super.dispose();
  }

  bool isLoading = false;

  // List<Drink> drinks = coffeeMenu;

  List<Order> orders = [];

  void addOrder(Drink drink) {
    var existingOrder = orders.firstWhere(
      (order) => order.drink.name == drink.name,
      orElse: () => Order(drink, 0),
    );

    setState(() {
      existingOrder.quantity++;
      orders.add(existingOrder);
    });
  }

  void removeOrder(Order order) {
    setState(() {
      if (order.quantity > 1) {
        order.quantity--;
      } else {
        orders.remove(order);
      }
    });
  }

  void saveOrder() async {
    if (orders.isNotEmpty) {
      // Sending the order to the Telegram bot
      const botToken = telegramBotToken;
      const chatId = telegramChatId;

      DateTime now = DateTime.now();
      String seconds = now.second.toString();
      String dateTimeNow =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} / ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${seconds.padLeft(2, '0')}';

      String invoiceId = generateShortUniqueId();

      double orderPrice = 0;
      var message = '**** New Order ****\n\n';

      List<Order> uniqueOrders = [];

      message += 'Date / Time: $dateTimeNow\n';
      message += 'Invoice ID: $invoiceId\n';
      message += 'Customer Name: $_customerName\n\n';

      for (var order in orders) {
        if (!uniqueOrders.contains(order)) {
          uniqueOrders.add(order);
        }
      }

      for (var uniqueOrder in uniqueOrders) {
        orderPrice += uniqueOrder.drink.price * uniqueOrder.quantity;
        message +=
            '${uniqueOrder.drink.name} x ${uniqueOrder.quantity}: RM${(uniqueOrder.drink.price * uniqueOrder.quantity).toStringAsFixed(2)}\n';
      }
      message += '----------------------------\n';
      message += 'TOTAL: RM${orderPrice.toStringAsFixed(2)}\n';
      message += '----------------------------\n';

      final url =
          'https://api.telegram.org/bot$botToken/sendMessage?chat_id=$chatId&text=$message';

      savingOrder() async {
        setState(() {
          isLoading = true;
        });

        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // Order sent successfully
          setState(() {
            isLoading = false;
            orders.clear();
            _clearCustomerName;
          });
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Order Sent'),
              content: Text(
                  'Your order has been sent successfully.\n\nCustomer\'s name: $_customerName\nTotal price: RM${orderPrice.toStringAsFixed(2)}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            isLoading = false;
          });
          // Failed to send order
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: const Text('Failed to send order. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Order Confirmation'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                savingOrder();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            mainAppbarText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 22,
              fontFamily: 'NotoSans',
            ),
          ),
          centerTitle: true,
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/KTJ_logo.jpeg'),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: TextField(
                  decoration: const InputDecoration(
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    labelText: 'Customer Name',
                  ),
                  controller: _customerNameController,
                  onChanged: (value) {
                    setState(() {
                      _customerName = value;
                    });
                  },
                ),
              ),
              const Divider(
                color: Colors.transparent,
                thickness: 3,
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    coffee(),
                    tea(),
                    john(),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.coffee),
              label: 'Coffee',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_drink),
              label: 'Tea',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fastfood),
              label: 'John',
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: isLoading ? null : saveOrder,
          child: isLoading
              ? const CircularProgressIndicator()
              : const Icon(Icons.save),
        ),
      ),
    );
  }

  Widget coffee() {
    return Container(
      color: Colors.brown.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: coffeeMenu.length,
        itemBuilder: (context, index) {
          var drink = coffeeMenu[index];
          var order = orders.firstWhere(
            (order) => order.drink.name == drink.name,
            orElse: () => Order(drink, 0),
          );

          return ListTile(
            title: Text(
              drink.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('RM ${drink.price.toStringAsFixed(2)}'),
            trailing: order != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => removeOrder(order),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(order.quantity.toString()),
                      IconButton(
                        onPressed: () => {
                          print('Clicked on ADD ${drink.name}'),
                          addOrder(drink)
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  )
                : IconButton(
                    onPressed: () => addOrder(drink),
                    icon: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }

  Widget tea() {
    return Container(
      color: Colors.brown.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: teaMenu.length,
        itemBuilder: (context, index) {
          var drink = teaMenu[index];
          var order = orders.firstWhere(
            (order) => order.drink.name == drink.name,
            orElse: () => Order(drink, 0),
          );

          return ListTile(
            title: Text(
              drink.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('RM ${drink.price.toStringAsFixed(2)}'),
            trailing: order != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => removeOrder(order),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(order.quantity.toString()),
                      IconButton(
                        onPressed: () => {
                          print('Clicked on ADD ${drink.name}'),
                          addOrder(drink)
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  )
                : IconButton(
                    onPressed: () => addOrder(drink),
                    icon: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }

  Widget john() {
    return Container(
      color: Colors.brown.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: johnMenu.length,
        itemBuilder: (context, index) {
          var drink = johnMenu[index];
          var order = orders.firstWhere(
            (order) => order.drink.name == drink.name,
            orElse: () => Order(drink, 0),
          );

          return ListTile(
            title: Text(
              drink.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('RM ${drink.price.toStringAsFixed(2)}'),
            trailing: order != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => removeOrder(order),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(order.quantity.toString()),
                      IconButton(
                        onPressed: () => {
                          print('Clicked on ADD ${drink.name}'),
                          addOrder(drink)
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  )
                : IconButton(
                    onPressed: () => addOrder(drink),
                    icon: const Icon(Icons.add),
                  ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: App()));
}

// class Coffee extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Content of Section 1'),
//     );
//   }
// }

// class Tea extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Content of Section 2'),
//     );
//   }
// }

// class John extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Content of Section 3'),
//     );
//   }
// }
