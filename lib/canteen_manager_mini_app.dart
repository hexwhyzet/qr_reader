import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_reader/request.dart';

class CanteenManagerMiniApp extends StatefulWidget {

  const CanteenManagerMiniApp({super.key});

  @override
  State<CanteenManagerMiniApp> createState() => _CanteenManagerMiniAppState();
}

class _CanteenManagerMiniAppState extends State<CanteenManagerMiniApp> {
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
        title: const Text('Менеджер столовой'),
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
