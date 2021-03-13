import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shop/exceptions/http_exception.dart';
import 'package:shop/providers/product.dart';
import 'package:shop/utils/constants.dart';

class Products with ChangeNotifier {
  final Uri _baseUrl = Uri().resolve('${Constants.BASE_API_URL}/products');

  List<Product> _items = [];

  String? _token;
  String? _userId;

  Products([this._token, this._userId, this._items = const []]);

  List<Product> get items => [..._items];

  List<Product> get favoriteItems {
    return _items.where((product) => product.isFavorite).toList();
  }

  int get itemsCount {
    return _items.length;
  }

  Future<void> loadProduct() async {
    Uri url = Uri().resolve('$_baseUrl.json?auth=$_token');
    final response = await http.get(url);

    final favoriteReponse = await http.get(Uri().resolve(
        '${Constants.BASE_API_URL}/userFavorites/$_userId.json?auth=$_token'));

    final Map<String, dynamic> data = json.decode(response.body);
    final favoriteMap = json.decode(favoriteReponse.body);
    print(favoriteMap);

    _items.clear();
    data.forEach((productId, productData) {
      final isFavorite =
          favoriteMap == null ? false : favoriteMap[productId] ?? false;
      _items.add(
        Product(
          id: productId,
          title: productData['title'],
          description: productData['description'],
          price: productData['price'],
          imageUrl: productData['imageUrl'],
          isFavorite: isFavorite,
        ),
      );
      notifyListeners();
    });

    return Future.value();
  }

  Future<void> addProduct(Product newProduct) {
    Uri url = Uri().resolve('$_baseUrl/.json?auth=$_token');
    return http
        .post(
      url,
      body: json.encode(
        {
          'title': newProduct.title,
          'description': newProduct.description,
          'price': newProduct.price,
          'imageUrl': newProduct.imageUrl,
        },
      ),
    )
        .then((response) {
      _items.add(
        Product(
          id: json.decode(response.body)['name'],
          title: newProduct.title,
          description: newProduct.description,
          price: newProduct.price,
          imageUrl: newProduct.imageUrl,
        ),
      );
      notifyListeners(); // avisa que a lista foi atualizada
    });
  }

  Future<void> updateProduct(Product product) async {
    Uri url = Uri().resolve('$_baseUrl/${product.id}.json?auth=$_token');
    if (product.id == null) {
      return;
    }

    final index = _items.indexWhere((prod) => prod.id == product.id);

    if (index >= 0) {
      await http.patch(
        url,
        body: json.encode({
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
        }),
      );

      _items[index] = product;
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id, String token) async {
    final index = _items.indexWhere((prod) => prod.id == id);

    if (index >= 0) {
      final product = _items[index];
      final Uri url = Uri().resolve('$_baseUrl/${product.id}.json?auth=$token');

      _items.remove(product);
      notifyListeners();

      final response = await http.delete(url);

      if (response.statusCode >= 400) {
        _items.insert(index, product);
        notifyListeners();

        throw HttpException('There was an error deleting the product');
      }
    }
  }
}
