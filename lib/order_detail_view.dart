import 'package:flutter/material.dart';
import 'package:qr_reader/request.dart';

import 'alert.dart';
import 'canteen_mini_app.dart';

class OrderDetailView extends StatelessWidget {
  final dynamic order;
  final dynamic dish;

  const OrderDetailView({
    super.key,
    required this.order,
    required this.dish,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заказа'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Удаление заказа'),
                  content: const Text('Вы действительно хотите удалить заказ?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () async {
                        try {
                          await sendRequest("DELETE", "food/orders/${order['id']}/");
                          if (context.mounted) {
                            if (context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            if (context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                            await raiseSuccessFlushbar(context, "Заказ успешно удалён!");
                          }
                        } catch (e) {
                          if (context.mounted) {
                            await raiseErrorFlushbar(context, "Ошибка удаления заказа!");
                          }
                          if (context.mounted && Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              dish['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            dish?['photo'] != null ?
            Image.network(
              dish['photo'],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ) : const Icon(Icons.fastfood),
            const SizedBox(height: 16),
            Text('Дата готовки: ${order["cooking_time"]}'),
            const SizedBox(height: 8),
            Text('Статус заказа: ${getOrderStatusName(order["status"])}'),
            const SizedBox(height: 8),
            Text('Тип блюда: ${getDishTypeName(dish["category"])}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => ReviewDialog(dishId: dish['id'],),
                );
              },
              child: const Text('Оставить отзыв'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewDialog extends StatefulWidget {
  final int dishId;

  const ReviewDialog({super.key, required this.dishId});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final TextEditingController reviewController = TextEditingController();
  bool _isSubmitting = false;
  late int dishId;

  @override
  void initState() {
    super.initState();
    dishId = widget.dishId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Оставить отзыв'),
      content: TextField(
        controller: reviewController,
        decoration: const InputDecoration(hintText: 'Напишите свой отзыв здесь...'),
        maxLines: 4,
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_isSubmitting) {
              return;
            }
            Navigator.pop(context);
          },
          child: const Text('Отменить'),
        ),
        TextButton(
          onPressed: () async {
            if (_isSubmitting) {
              return;
            }
            setState(() {
              _isSubmitting = true;
            });

            final review = reviewController.text;

            if (review.isEmpty) {
              await raiseErrorFlushbar(context, "Введите текст отзыва");
              if (context.mounted) {
                setState(() {
                  _isSubmitting = false;
                });
              }
              return;
            }

            var dict = {
              "dish": dishId,
              "comment": review,
            };
            try {
              await sendRequest("POST", "food/feedback/", body: dict);
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              if (context.mounted) {
                await raiseSuccessFlushbar(context, "Отзыв успешно отправлен!");
              }
            } catch (e) {
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.pop(context);
              }
              if (context.mounted) {
                await raiseErrorFlushbar(context, "Ошибка отправки отзыва!");
              }
            }

            if (context.mounted) {
              setState(() {
                _isSubmitting = false;
              });
            }
          },
          child: const Text('Отправить'),
        ),
      ],
    );
  }
}