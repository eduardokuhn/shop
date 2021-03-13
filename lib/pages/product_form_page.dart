import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop/providers/product.dart';
import 'package:shop/providers/products.dart';

class ProductFormPage extends StatefulWidget {
  @override
  _ProductFormPageState createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  bool isThereArguments = false;
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageUrlFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  bool _isLoading = false;

  final _form =
      GlobalKey<FormState>(); // referencia ao formulario e seus estados
  final _formData = Map<String, Object>();

  @override
  void initState() {
    super.initState();
    // fica ouvindo se teve mudanca em _imageUrlFocusNode e quando tiver chama a
    // funcao passada como parametro. Nesse caso caso entrarmos e sairmos do foco
    // de _imageUrlFocusNode
    _imageUrlFocusNode.addListener(_updateImage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    var arguments = ModalRoute.of(context)!.settings.arguments;
    bool isThereArguments = arguments != null ? true : false;

    setIsThereArguments(isThereArguments);

    if (_formData.isEmpty && isThereArguments == true) {
      final product = arguments as Product;

      _formData['id'] = product.id.toString();
      _formData['title'] = product.title;
      _formData['description'] = product.description;
      _formData['price'] = product.price;
      _formData['imageUrl'] = product.imageUrl;

      _imageUrlController.text = _formData['imageUrl'].toString();
    }
  }

  void setIsThereArguments(bool resp) => isThereArguments = resp;

  void _updateImage() {
    if (isValidImageUrl(_imageUrlController.text)) {
      // para atualizar o componente e pegar as infos mais atuais do
      // _imageUrlController
      setState(() {});
    }
  }

  bool isValidImageUrl(String url) {
    bool startWithHttp = url.toLowerCase().startsWith('http://');
    bool startWithHttps = url.toLowerCase().startsWith('https://');

    bool endsWithPng = url.toLowerCase().endsWith('.png');
    bool endsWithJpg = url.toLowerCase().endsWith('.jpg');
    bool endsWithJpeg = url.toLowerCase().endsWith('.jpeg');

    return (startWithHttp || startWithHttps) &&
        (endsWithPng || endsWithJpg || endsWithJpeg);
  }

  @override
  void dispose() {
    super.dispose();

    // para evitar qualquer uso de memória por esses objetos
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageUrlFocusNode.removeListener(_updateImage);
    _imageUrlFocusNode.dispose();
  }

  void _saveForm() {
    // vai ser setado para false caso algum dos atributos validator de
    // TextFormField() retornar algo diferente de null
    bool isValid = _form.currentState!.validate();

    if (!isValid) {
      return;
    }

    // dispara o método onSaved() de todos os TextFormField().
    _form.currentState!.save();

    final product = Product(
      id: _formData['id'].toString(),
      title: _formData['title'].toString(),
      description: _formData['description'].toString(),
      price: _formData['price'] as double,
      imageUrl: _formData['imageUrl'].toString(),
    );

    setState(() {
      _isLoading = true;
    });

    // Para usar um Provider fora do método build ele precisa ser listen: false
    final products = Provider.of<Products>(context, listen: false);

    if (_formData['id'] == null) {
      products.addProduct(product).catchError((error) {
        // Retorna um Future de Null pois o catchError retorna um Future de Null
        return showDialog<Null>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error!'),
            content: Text('An error occurs when adding product!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              )
            ],
          ),
        );
      }).then((_) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      });
    } else {
      products.updateProduct(product).catchError((error) {
        // Retorna um Future de Null pois o catchError retorna um Future de Null
        return showDialog<Null>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error!'),
            content: Text('An error occurs when updating product!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              )
            ],
          ),
        );
      }).then((_) {
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product form'),
        actions: [
          IconButton(
            onPressed: () {
              _saveForm();
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(15.0),
              child: Form(
                key: _form,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue:
                          isThereArguments ? _formData['title'].toString() : '',
                      decoration: InputDecoration(labelText: 'Title'),
                      // vai para o próximo campo
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) {
                        // muda o foco para o próximo campo
                        FocusScope.of(context).requestFocus(_priceFocusNode);
                      },
                      // aqui salvamos o valor em um Map
                      onSaved: (value) => _formData['title'] = value!,
                      // caso retornar algo diferente de null significa que ouve um erro
                      validator: (value) {
                        if (value!.trim().isEmpty) {
                          return 'Report a valid title!';
                        }

                        if (value.trim().length < 3) {
                          return 'The title must be at least 3 characters long';
                        }

                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue:
                          isThereArguments ? _formData['price'].toString() : '',
                      decoration: InputDecoration(labelText: 'Price'),
                      textInputAction: TextInputAction.next,
                      focusNode: _priceFocusNode,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onFieldSubmitted: (_) {
                        FocusScope.of(context)
                            .requestFocus(_descriptionFocusNode);
                      },
                      onSaved: (value) =>
                          _formData['price'] = double.tryParse(value!)!,
                      validator: (value) {
                        var newPrice = double.tryParse(value!);
                        bool isInvalid = newPrice == null || newPrice <= 0;

                        if (isInvalid) {
                          return 'Report a valid price!';
                        }

                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: isThereArguments
                          ? _formData['description'].toString()
                          : '',
                      decoration: InputDecoration(labelText: 'Description'),
                      textInputAction: TextInputAction.next,
                      focusNode: _descriptionFocusNode,
                      keyboardType: TextInputType.multiline,
                      maxLines: 3,
                      onSaved: (value) => _formData['description'] = value!,
                      validator: (value) {
                        if (value!.trim().length < 10) {
                          return 'The description must be at least 10 characters long';
                        }

                        return null;
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Image URL'),
                            keyboardType: TextInputType.url,
                            textInputAction: TextInputAction.done,
                            focusNode: _imageUrlFocusNode,
                            controller: _imageUrlController,
                            onFieldSubmitted: (_) {
                              _saveForm();
                            },
                            onSaved: (value) => _formData['imageUrl'] = value!,
                            validator: (value) {
                              if (value!.trim().isEmpty ||
                                  !isValidImageUrl(value)) {
                                return 'Report a valid url!';
                              }

                              return null;
                            },
                          ),
                        ),
                        Container(
                          height: 100,
                          width: 100,
                          margin: const EdgeInsets.only(
                            top: 8,
                            left: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: _imageUrlController.text.isEmpty
                              ? Text('Report URL')
                              : Image.network(_imageUrlController.text),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
