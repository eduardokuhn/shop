import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/providers/cart.dart';
import 'package:shop/utils/constants.dart';

class Order {
  final String id;
  final double total;
  final List<CartItem> products;
  final DateTime date;

  Order({
    required this.id,
    required this.total,
    required this.products,
    required this.date,
  });
}

class Orders with ChangeNotifier {
  final Uri _url = Uri().resolve('${Constants.BASE_API_URL}/orders');

  String? _userId;
  String? _token;

  Orders([this._token, this._userId, this._items = const []]);

  List<Order> _items = [];

  List<Order> get items {
    return [..._items];
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> addOrder(Cart cart) async {
    final date = DateTime.now();

    final response = await http.post(
      _url.resolve('$_url/$_userId.json?auth=$_token'),
      body: json.encode({
        'total': cart.totalAmount,
        'products': cart.items.values
            .map((cartItem) => {
                  'id': cartItem.id,
                  'productId': cartItem.productId,
                  'title': cartItem.title,
                  'quantity': cartItem.quantity,
                  'price': cartItem.price,
                })
            .toList(),
        'date': date.toIso8601String()
      }),
    );

    _items.insert(
      0,
      Order(
          id: json.decode(response.body)['name'],
          total: cart.totalAmount,
          products: cart.items.values.toList(),
          date: date),
    );
    notifyListeners();
  }

  Future<void> loadOrders() async {
    List<Order> loadedOrders = [];
    final response =
        await http.get(_url.resolve('$_url/$_userId.json?auth=$_token'));
    Map<String, dynamic> data = json.decode(response.body);

    _items.clear();

    data.forEach((orderId, orderData) {
      final List<CartItem> productsFromOrder =
          (orderData['products'] as List<dynamic>).map((cartItem) {
        return CartItem(
          id: cartItem['id'],
          productId: cartItem['productId'],
          title: cartItem['title'],
          quantity: cartItem['quantity'],
          price: cartItem['price'],
        );
      }).toList();

      loadedOrders.add(
        Order(
          id: orderId,
          total: orderData['total'],
          products: productsFromOrder,
          date: DateTime.parse(orderData['date']),
        ),
      );

      notifyListeners();
    });

    _items = loadedOrders.reversed.toList();
    return Future.value();
  }
}
