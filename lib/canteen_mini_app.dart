import 'package:flutter/material.dart';
import 'package:qr_reader/create_dish_order.dart';
import 'package:qr_reader/request.dart';

import 'order_detail_view.dart';

String getOrderStatusName(String? statusCode) {
  switch (statusCode?.toLowerCase()) {
    case 'pending':
      return 'Ожидает';
    case 'approved':
      return 'Одобрен';
    case 'canceled':
      return 'Отменён';
    case 'completed':
      return 'Завершён';
    default:
      return 'Неизвестный статус';
  }
}

String getDishTypeName(String? dishType) {
  switch (dishType?.toLowerCase()) {
    case 'first_course':
      return 'Первое блюдо';
    case 'side_dish':
      return 'Гарнир';
    case 'main_course':
      return 'Второе блюдо';
    case 'salad':
      return 'Салат';
    default:
      return 'Неизвестный тип';
  }
}

class CanteenMiniApp extends StatefulWidget {
  const CanteenMiniApp({super.key});

  @override
  State<CanteenMiniApp> createState() => _CanteenMiniAppState();
}

class _CanteenMiniAppState extends State<CanteenMiniApp> {
  List<dynamic> dishes = [];
  List<dynamic> orders = [];

  Map<String, dynamic>? getDishById(int id) {
    return dishes.firstWhere(
          (element) => element['id'] == id,
      orElse: () => null,
    );
  }

  bool isLoadingDishes = true;
  bool isLoadingOrders = true;

  @override
  void initState() {
    super.initState();
    refreshState();
  }

  void refreshState() {
    isLoadingOrders = true;
    isLoadingDishes = true;
    fetchOrders();
    fetchDishes();
  }

  Future<void> fetchDishes() async {
    try {
      final response = await sendRequest("GET", "food/dishes/");
      setState(() {
          dishes = response;
          isLoadingDishes = false;
        });
    } catch (error) {
      setState(() {
        isLoadingDishes = false;
      });
      print('Error fetching dishes: $error');
    }
  }

  Future<void> fetchOrders() async {
    try {
      final response = await sendRequest("GET", "food/orders/");
      setState(() {
        orders = response;
        isLoadingOrders = false;
      });
    } catch (error) {
      setState(() {
        isLoadingOrders = false;
      });
      print('Error fetching orders: $error');
    }
  }

  void _openAddOrderView() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateDishOrderView(dishes: dishes),
      ),
    );
    setState(() {
      refreshState();
    });
  }

  void _openOrderDetailView(dynamic order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailView(
          order: order,
          dish: getDishById(order['dish'])
        ),
      ),
    );
    setState(() {
      refreshState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Canteen Mini App'),
      ),
      body:
        isLoadingDishes || isLoadingOrders ? const Center(child: CircularProgressIndicator()) :
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Заказы',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final dish = getDishById(order['dish']);
                    return ListTile(
                      leading: dish?['photo'] != null
                          ? Image.network(
                        dish?['photo'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : const SizedBox(width: 50, height: 50, child: Icon(Icons.fastfood),),
                      title: Text(dish?['name']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Статус: ${getOrderStatusName(order['status'])}'),
                          Text('Дата готовки: ${order['cooking_time']}'),
                        ],
                      ),
                      trailing: Icon(
                        order['status'] == 'Completed' ? Icons.check_circle : Icons.hourglass_empty,
                        color: order['status'] == 'Completed' ? Colors.green : Colors.orange,
                      ),
                      onTap: () => _openOrderDetailView(order),
                    );
                  },
                ),
              ),
            ],
          ),

      ),
      floatingActionButton: isLoadingDishes || isLoadingOrders ? null : FloatingActionButton(
        onPressed: () => _openAddOrderView(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
