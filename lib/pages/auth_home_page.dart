import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/pages/auth_page.dart';
import 'package:shop/pages/products_overview_page.dart';
import 'package:shop/providers/auth.dart';

class AuthHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Auth auth = Provider.of(context);
    return FutureBuilder(
      future: auth.tryAutoLogin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.error != null) {
          print(snapshot.error);
          return Scaffold(
            body: Center(
              child: Text('Error!'),
            ),
          );
        } else {
          return auth.isAuth ? ProductsOverviewPage() : AuthPage();
        }
      },
    );
  }
}
