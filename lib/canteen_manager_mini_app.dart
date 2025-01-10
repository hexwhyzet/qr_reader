import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_reader/request.dart';

class CanteenManagerMiniApp extends StatelessWidget {
  const CanteenManagerMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Менеджер столовой'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OrderStats(),
                  ),
                );
              },
              child: const Text('Просмотр статистики по заказам'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbacksPage(),
                  ),
                );
              },
              child: const Text('Просмотр отзывов'),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderStats extends StatefulWidget {

  const OrderStats({super.key});

  @override
  State<OrderStats> createState() => _OrderStatsState();
}

class _OrderStatsState extends State<OrderStats> {
  List<dynamic> dishes = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        isLoading = true;
        selectedDate = picked;
      });
      fetchDishes();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDishes();
  }

  Future<void> fetchDishes() async {
    var dict = {
      'date': DateFormat('yyyy-MM-dd').format(selectedDate)
    };
    try {
      final response = await sendRequest("GET", "food/orders/aggregate_orders/", queryParams: dict);
      setState(() {
        dishes = response;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching dishes: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Статистика по заказам'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: Text(
                "Статистика по заказам",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                children: [
                  const Text(
                    "Заказы на дату: ",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    DateFormat('yyyy-MM-dd').format(selectedDate),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),
            isLoading ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()),) : SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final dish = dishes[index];
                  return ListTile(
                    leading: const SizedBox(width: 50, height: 50, child: Icon(Icons.fastfood),),
                    title: Text(dish['dish']),
                    subtitle: Text("Количество заказов: ${dish['total_orders']}"),
                  );
                },
                childCount: dishes.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FeedbacksPage extends StatefulWidget {
  const FeedbacksPage({super.key});

  @override
  State<FeedbacksPage> createState() => _FeedbacksPageState();
}

class _FeedbacksPageState extends State<FeedbacksPage> {
  List<dynamic> feedbacks = [];
  List<dynamic> dishes = [];
  bool isLoadingFeedbacks = true;
  bool isLoadingDishes = true;

  @override
  void initState() {
    super.initState();
    fetchFeedback();
    fetchDishes();
  }

  Future<void> fetchFeedback() async {
    try {
      final response = await sendRequest("GET", "food/feedback/");
      setState(() {
        feedbacks = response;
        isLoadingFeedbacks = false;
      });
    } catch (error) {
      setState(() {
        isLoadingFeedbacks = false;
      });
      print('Error fetching feedbacks: $error');
    }
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

  Map<String, dynamic>? getDishById(int id) {
    return dishes.firstWhere(
          (element) => element['id'] == id,
      orElse: () => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Отзывы'),
        ),
        body: isLoadingFeedbacks || isLoadingDishes ? const Center(child: CircularProgressIndicator()) :
        feedbacks.isEmpty ? const Center(child: Text('Нет отзывов')) :
        ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            String comment = feedbacks[index]['comment'] ?? "";
            if (comment.length > 1000) {
              comment = "${comment.substring(0, 1000)}...";
            }
            return ListTile(
              title: Text(comment),
              subtitle: Text(
                'Блюдо: ${getDishById(feedbacks[index]['dish'])?['name']}',
              ),
            );
          },
        ));
  }
}
